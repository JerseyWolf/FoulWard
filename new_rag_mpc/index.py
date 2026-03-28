#!/usr/bin/env python3
"""
index.py — Foul Ward RAG Indexer
=================================
Scans the Godot project tree, chunks files by domain, and upserts into
four ChromaDB collections with hybrid BM25 + semantic retrieval support.

Usage:
    python index.py              # Full index (skips unchanged files)
    python index.py --force      # Force re-index everything
    python index.py --stats      # Print collection stats and exit

Collections:
    architecture  — .md files from ~/FoulWard/docs/
    code          — .gd files from ~/FoulWard/scripts/
    resources     — .tres files from ~/FoulWard/resources/
    simbot_logs   — .json/.csv from ~/FoulWard/logs/
"""

import argparse
import hashlib
import json
import os
import re
import sys
import time
from datetime import datetime
from pathlib import Path
from typing import Optional

import chromadb
from langchain_ollama import OllamaEmbeddings

from langchain_text_splitters import (
    RecursiveCharacterTextSplitter,
    Language,
)

# ════════════════════════════════════════════════════════════
# Configuration
# ════════════════════════════════════════════════════════════

FOULWARD_ROOT = Path.home() / "FoulWard"
LLM_ROOT = Path.home() / "LLM"
CHROMA_PATH = LLM_ROOT / "rag_db"
HASH_CACHE_PATH = LLM_ROOT / "index_hashes.json"

# Domain → (source directory, file extensions, collection name)
DOMAINS = {
    "architecture": {
        "source_dir": FOULWARD_ROOT / "docs",
        "extensions": {".md"},
        "collection": "architecture",
    },
    "code": {
        "source_dir": FOULWARD_ROOT / "scripts",
        "extensions": {".gd"},
        "collection": "code",
    },
    "resources": {
        "source_dir": FOULWARD_ROOT / "resources",
        "extensions": {".tres"},
        "collection": "resources",
    },
    "simbot_logs": {
        "source_dir": FOULWARD_ROOT / "logs",
        "extensions": {".json", ".csv"},
        "collection": "simbot_logs",
    },
}

# Also index key root-level project docs
ROOT_DOCS = [
    "CONVENTIONS.md",
    "ARCHITECTURE.md",
    "INDEX_FULL.md",
    "INDEX_SHORT.md",
    "INDEX_MACHINE.md",
]

# Chunking: use smaller chunks for code/resources, larger for docs
CODE_CHUNK_SIZE = 400        # tokens (approx, via char count * 0.75)
CODE_CHUNK_OVERLAP = 80
DOC_CHUNK_SIZE = 800
DOC_CHUNK_OVERLAP = 100

CODE_CHAR_CHUNK_SIZE = int(CODE_CHUNK_SIZE / 0.75)
CODE_CHAR_CHUNK_OVERLAP = int(CODE_CHUNK_OVERLAP / 0.75)

DOC_CHAR_CHUNK_SIZE = int(DOC_CHUNK_SIZE / 0.75)
DOC_CHAR_CHUNK_OVERLAP = int(DOC_CHUNK_OVERLAP / 0.75)

EMBEDDING_MODEL = "nomic-embed-text"

# ════════════════════════════════════════════════════════════
# Utilities
# ════════════════════════════════════════════════════════════


def file_hash(filepath: Path) -> str:
    """SHA-256 of file contents."""
    h = hashlib.sha256()
    h.update(filepath.read_bytes())
    return h.hexdigest()


def load_hash_cache() -> dict:
    """Load the hash cache from disk."""
    if HASH_CACHE_PATH.exists():
        return json.loads(HASH_CACHE_PATH.read_text())
    return {}


def save_hash_cache(cache: dict) -> None:
    """Persist the hash cache."""
    HASH_CACHE_PATH.write_text(json.dumps(cache, indent=2))


def parse_run_id_from_filename(filename: str) -> str:
    """
    Extract a run_id from SimBot log filenames.
    Expected patterns:
        simbot_run_20260325_143022.json
        simbot_endless_strategy_physical_001.csv
        run_003.json
    Falls back to the stem if no pattern matches.
    """
    stem = Path(filename).stem
    # Try date-stamped pattern
    m = re.search(r"run[_-]?(\d{8}[_-]?\d{6})", stem)
    if m:
        return m.group(0)
    # Try numbered pattern
    m = re.search(r"run[_-]?(\d+)", stem)
    if m:
        return m.group(0)
    # Try strategy pattern
    m = re.search(r"(strategy[_-]\w+[_-]\d+)", stem)
    if m:
        return m.group(0)
    return stem


def extract_gdscript_class_name(content: str) -> Optional[str]:
    """Pull class_name from a GDScript file."""
    m = re.search(r"^class_name\s+(\w+)", content, re.MULTILINE)
    return m.group(1) if m else None


def extract_tres_resource_type(content: str) -> Optional[str]:
    """Pull the resource type from a .tres file header."""
    m = re.search(r"\[gd_resource\s+type=\"(\w+)\"", content)
    return m.group(1) if m else None


# ════════════════════════════════════════════════════════════
# Chunking strategies per domain
# ════════════════════════════════════════════════════════════


def get_splitter_for_domain(domain: str) -> RecursiveCharacterTextSplitter:
    """Return a text splitter tuned to the domain's content type."""
    if domain == "code":
        # GDScript is close enough to Python for the Language splitter
        return RecursiveCharacterTextSplitter.from_language(
            language=Language.PYTHON,
            chunk_size=CODE_CHAR_CHUNK_SIZE,
            chunk_overlap=CODE_CHAR_CHUNK_OVERLAP,
        )
    elif domain == "resources":
        # .tres files are INI-like with [resource] / [sub_resource] sections
        return RecursiveCharacterTextSplitter(
            separators=["\n[", "\n\n", "\n", " "],
            chunk_size=CODE_CHAR_CHUNK_SIZE,
            chunk_overlap=CODE_CHAR_CHUNK_OVERLAP,
        )
    elif domain == "simbot_logs":
        # JSON/CSV: split on record boundaries
        return RecursiveCharacterTextSplitter(
            separators=["\n},\n", "\n}\n", "\n\n", "\n", " "],
            chunk_size=DOC_CHAR_CHUNK_SIZE,
            chunk_overlap=DOC_CHAR_CHUNK_OVERLAP,
        )
    else:
        # Markdown docs: use heading-aware splitting
        return RecursiveCharacterTextSplitter.from_language(
            language=Language.MARKDOWN,
            chunk_size=DOC_CHAR_CHUNK_SIZE,
            chunk_overlap=DOC_CHAR_CHUNK_OVERLAP,
        )


def build_metadata(filepath: Path, domain: str, chunk_index: int) -> dict:
    """Build per-chunk metadata."""
    stat = filepath.stat()
    meta = {
        "source_file": str(filepath),
        "file_name": filepath.name,
        "file_type": filepath.suffix.lstrip("."),
        "domain": domain,
        "chunk_index": chunk_index,
        "last_modified": datetime.fromtimestamp(stat.st_mtime).isoformat(),
        "file_size_bytes": stat.st_size,
    }

    if domain == "simbot_logs":
        meta["run_id"] = parse_run_id_from_filename(filepath.name)

    return meta


# ════════════════════════════════════════════════════════════
# Indexing pipeline
# ════════════════════════════════════════════════════════════


def collect_files(domain_config: dict) -> list[Path]:
    """Recursively find all matching files in a source directory."""
    source_dir = domain_config["source_dir"].resolve()
    extensions = domain_config["extensions"]
    if not source_dir.exists():
        return []
    files: list[Path] = []
    for ext in extensions:
        for p in source_dir.rglob(f"*{ext}"):
            try:
                resolved = p.resolve()
            except OSError:
                continue
            # Guard against symlink escape outside the project root
            if source_dir in resolved.parents or resolved.parent == source_dir:
                files.append(p)
    return sorted(files)


def collect_root_docs() -> list[Path]:
    """Collect root-level project docs that go into the architecture collection."""
    files: list[Path] = []
    for name in ROOT_DOCS:
        p = FOULWARD_ROOT / name
        if p.exists():
            files.append(p)
    return files


def index_collection(
    client: chromadb.ClientAPI,
    domain: str,
    files: list[Path],
    hash_cache: dict,
    force: bool = False,
) -> tuple[int, int]:
    """
    Index files into a ChromaDB collection.
    Returns (files_processed, chunks_added).
    """
    config = DOMAINS[domain]
    collection_name = config["collection"]

    # Get or create collection
    collection = client.get_or_create_collection(
        name=collection_name,
        metadata={"hnsw:space": "cosine"},
    )

    splitter = get_splitter_for_domain(domain)
    embeddings = OllamaEmbeddings(model=EMBEDDING_MODEL)

    files_processed = 0
    chunks_added = 0

    for filepath in files:
        file_key = str(filepath)
        current_hash = file_hash(filepath)

        # Skip unchanged files unless forced
        if not force and hash_cache.get(file_key) == current_hash:
            continue

        # Read file content
        try:
            content = filepath.read_text(encoding="utf-8", errors="replace")
        except Exception as e:
            print(f"  WARN: Could not read {filepath}: {e}")
            continue

        if not content.strip():
            continue

        # Delete existing chunks for this file before re-indexing
        try:
            existing = collection.get(where={"source_file": file_key})
            if existing and existing.get("ids"):
                collection.delete(ids=existing["ids"])
        except Exception:
            # Collection might be empty or not support where yet
            pass

        # Build header context for code/resource files
        header = ""
        if domain == "code":
            cls = extract_gdscript_class_name(content)
            if cls:
                header = f"# GDScript class: {cls}\n# File: {filepath.name}\n\n"
        elif domain == "resources":
            rtype = extract_tres_resource_type(content)
            if rtype:
                header = f"# Godot Resource type: {rtype}\n# File: {filepath.name}\n\n"

        # Chunk the content
        chunks = splitter.split_text(content)

        if not chunks:
            continue

        # Prepare batch for ChromaDB
        ids: list[str] = []
        documents: list[str] = []
        metadatas: list[dict] = []

        for i, chunk_text in enumerate(chunks):
            path_hash = hashlib.md5(str(filepath).encode()).hexdigest()[:8]
            doc_id = f"{collection_name}::{path_hash}::{filepath.name}::chunk_{i}"
            meta = build_metadata(filepath, domain, i)

            # Prepend header context to first chunk
            if i == 0 and header:
                chunk_text = header + chunk_text

            ids.append(doc_id)
            documents.append(chunk_text)
            metadatas.append(meta)

        # Embed and upsert in batches of 50
        batch_size = 50
        for batch_start in range(0, len(ids), batch_size):
            batch_end = min(batch_start + batch_size, len(ids))
            batch_docs = documents[batch_start:batch_end]
            batch_ids = ids[batch_start:batch_end]
            batch_meta = metadatas[batch_start:batch_end]

            try:
                batch_embeddings = embeddings.embed_documents(batch_docs)
                collection.upsert(
                    ids=batch_ids,
                    documents=batch_docs,
                    embeddings=batch_embeddings,
                    metadatas=batch_meta,
                )
            except Exception as e:
                print(
                    f"  ERROR embedding/upserting {filepath.name} "
                    f"batch {batch_start}: {e}"
                )
                continue

        # Update hash cache
        hash_cache[file_key] = current_hash
        files_processed += 1
        chunks_added += len(chunks)
        print(f"  Indexed: {filepath.name} → {len(chunks)} chunks")

    return files_processed, chunks_added


def print_stats(client: chromadb.ClientAPI) -> None:
    """Print summary statistics for all collections."""
    print("\n╔══════════════════════════════════════════════════╗")
    print("║         ChromaDB Collection Statistics           ║")
    print("╠══════════════════════════════════════════════════╣")
    for domain, config in DOMAINS.items():
        name = config["collection"]
        try:
            coll = client.get_collection(name=name)
            count = coll.count()
            print(f"║  {name:<20s}  {count:>6d} chunks          ║")
        except Exception:
            print(f"║  {name:<20s}  (not created yet)       ║")
    print("╚══════════════════════════════════════════════════╝")


# ════════════════════════════════════════════════════════════
# Main
# ════════════════════════════════════════════════════════════


def main():
    parser = argparse.ArgumentParser(description="Foul Ward RAG Indexer")
    parser.add_argument("--force", action="store_true", help="Force re-index all files")
    parser.add_argument("--stats", action="store_true", help="Print stats and exit")
    args = parser.parse_args()

    # Ensure directories exist
    CHROMA_PATH.mkdir(parents=True, exist_ok=True)

    # Initialize ChromaDB
    client = chromadb.PersistentClient(path=str(CHROMA_PATH))

    if args.stats:
        print_stats(client)
        return

    print("═══════════════════════════════════════════════════")
    print("  Foul Ward RAG Indexer")
    print(f"  Project root: {FOULWARD_ROOT}")
    print(f"  ChromaDB:     {CHROMA_PATH}")
    print(f"  Mode:         {'FORCE' if args.force else 'incremental'}")
    print("═══════════════════════════════════════════════════")

    if not FOULWARD_ROOT.exists():
        print(f"\nERROR: Project root not found at {FOULWARD_ROOT}")
        print("  Set FOULWARD_ROOT or create a symlink.")
        sys.exit(1)

    hash_cache = load_hash_cache()
    total_files = 0
    total_chunks = 0
    start = time.time()

    for domain, config in DOMAINS.items():
        print(f"\n[{domain}] Scanning {config['source_dir']}...")
        files = collect_files(config)

        # Add root docs to architecture collection
        if domain == "architecture":
            files.extend(collect_root_docs())

        if not files:
            print("  No files found.")
            continue

        print(f"  Found {len(files)} files.")
        f_count, c_count = index_collection(
            client, domain, files, hash_cache, force=args.force
        )
        total_files += f_count
        total_chunks += c_count

    save_hash_cache(hash_cache)
    elapsed = time.time() - start

    print(f"\n{'═' * 52}")
    print(f"  Done in {elapsed:.1f}s")
    print(f"  Files processed: {total_files}")
    print(f"  Chunks added:    {total_chunks}")

    print_stats(client)


if __name__ == "__main__":
    main()
