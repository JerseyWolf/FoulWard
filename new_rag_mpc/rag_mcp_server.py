#!/usr/bin/env python3
"""
rag_mcp_server.py — Foul Ward RAG MCP Server
==============================================
Stdio-transport MCP server exposing two tools to Cursor:

    query_project_knowledge(question, domain="all")
        Hybrid BM25 + semantic retrieval over project files,
        with LLM-generated answers citing source files.

    get_recent_simbot_summary(n_runs=3)
        Structured summary of recent SimBot log entries.

Uses LangGraph with SQLite checkpointer for cross-session memory.

Run directly:
    python rag_mcp_server.py

Or via Cursor MCP config (stdio transport).
"""

import json
import logging
import os
import re
import sys
from datetime import datetime
from pathlib import Path
from typing import Any, Optional

# ── MCP imports ──────────────────────────────────────────
from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp.server.lowlevel import NotificationOptions
from mcp.server.models import InitializationOptions
from mcp.types import Tool, TextContent

# ── LangChain / retrieval imports ────────────────────────
import chromadb
from langchain_ollama import OllamaEmbeddings, ChatOllama
from langchain_community.retrievers import BM25Retriever
from langchain_core.documents import Document
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder
from langchain_core.messages import HumanMessage, AIMessage, SystemMessage
from langchain_core.output_parsers import StrOutputParser

# ── LangGraph memory ────────────────────────────────────
from langgraph.graph import StateGraph, START, END
from langgraph.checkpoint.sqlite import SqliteSaver
from typing import TypedDict, Annotated, Sequence
from langchain_core.messages import BaseMessage
import operator
import sqlite3

# ════════════════════════════════════════════════════════════
# Configuration
# ════════════════════════════════════════════════════════════

LLM_ROOT = Path.home() / "LLM"
CHROMA_PATH = LLM_ROOT / "rag_db"
MEMORY_DB_PATH = LLM_ROOT / "rag_memory.db"

EMBEDDING_MODEL = "nomic-embed-text"
# Use a smaller / faster model for MCP tool calls; keep 30B Qwen for background use
LLM_MODEL = "qwen2.5:3b"

COLLECTION_NAMES = ["architecture", "code", "resources", "simbot_logs"]

DOMAIN_MAP = {
    "all": COLLECTION_NAMES,
    "architecture": ["architecture"],
    "code": ["code"],
    "resources": ["resources"],
    "simbot_logs": ["simbot_logs"],
    # Convenience aliases
    "docs": ["architecture"],
    "scripts": ["code"],
    "balance": ["resources", "simbot_logs"],
    "logs": ["simbot_logs"],
}

SYSTEM_PROMPT = (
    "You are an expert game balance analyst and Godot 4 architect "
    "specializing in the Foul Ward tower defense project. You have deep "
    "knowledge of the project's GDScript codebase, Types.EnemyType and "
    "Types.BuildingType enums, building and enemy data .tres resources, "
    "SimBot simulation logs, wave scaling formulas, and economy balance. "
    "When answering questions always cite the specific source file the "
    "information comes from. When making balance suggestions always "
    "reference the actual numbers from the resource files and simulation "
    "logs, never invent values."
)

# Retrieval tuning
SEMANTIC_TOP_K = 8
BM25_TOP_K = 8
FINAL_TOP_K = 8        # Slightly higher now that chunks are smaller
SEMANTIC_WEIGHT = 0.5  # In ensemble: 0.5 semantic + 0.5 BM25

# ════════════════════════════════════════════════════════════
# Logging
# ════════════════════════════════════════════════════════════

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.FileHandler(LLM_ROOT / "mcp_server.log"),
        logging.StreamHandler(sys.stderr),
    ],
)
log = logging.getLogger("foulward_rag")

# ════════════════════════════════════════════════════════════
# ChromaDB + Retrieval Layer
# ════════════════════════════════════════════════════════════


class ProjectRetriever:
    """
    Hybrid retriever over Foul Ward's ChromaDB collections.
    Combines BM25 keyword search with ChromaDB semantic search
    via score-based ensemble ranking.
    """

    def __init__(self):
        self.client = chromadb.PersistentClient(path=str(CHROMA_PATH))
        self.embeddings = OllamaEmbeddings(model=EMBEDDING_MODEL)
        self.collections: dict[str, chromadb.Collection] = {}
        self._bm25_cache: dict[str, BM25Retriever] = {}

        for name in COLLECTION_NAMES:
            try:
                self.collections[name] = self.client.get_collection(name=name)
                count = self.collections[name].count()
                log.info(f"Loaded collection '{name}': {count} chunks")
                self._warm_bm25(name)
            except Exception as e:
                log.warning(f"Collection '{name}' not found: {e}")

    def _warm_bm25(self, coll_name: str) -> None:
        """Pre-load documents and build a BM25 index for a single collection."""
        coll = self.collections.get(coll_name)
        if coll is None or coll.count() == 0:
            return
        try:
            data = coll.get(include=["documents", "metadatas"])
        except Exception as e:
            log.error(f"BM25 warmup failed for '{coll_name}': {e}")
            return

        docs: list[Document] = []
        for i, doc_text in enumerate(data["documents"]):
            meta = data["metadatas"][i] if data["metadatas"] else {}
            docs.append(Document(page_content=doc_text, metadata=meta))

        if docs:
            self._bm25_cache[coll_name] = BM25Retriever.from_documents(
                docs, k=BM25_TOP_K
            )
            log.info(f"BM25 index warmed for '{coll_name}' ({len(docs)} docs)")

    def _semantic_search(
        self, query: str, collection_names: list[str], top_k: int = SEMANTIC_TOP_K
    ) -> list[Document]:
        """Embed query and search ChromaDB collections."""
        query_embedding = self.embeddings.embed_query(query)
        results: list[Document] = []

        for coll_name in collection_names:
            coll = self.collections.get(coll_name)
            if coll is None or coll.count() == 0:
                continue

            k = min(top_k, coll.count())
            try:
                res = coll.query(
                    query_embeddings=[query_embedding],
                    n_results=k,
                    include=["documents", "metadatas", "distances"],
                )
            except Exception as e:
                log.error(f"Semantic search failed on '{coll_name}': {e}")
                continue

            for i, doc_text in enumerate(res["documents"][0]):
                meta = res["metadatas"][0][i] if res["metadatas"] else {}
                distance = res["distances"][0][i] if res["distances"] else 1.0
                meta["_score"] = 1.0 - distance  # Convert distance to similarity
                meta["_source"] = "semantic"
                results.append(Document(page_content=doc_text, metadata=meta))

        return results

    def _bm25_search(
        self, query: str, collection_names: list[str], top_k: int = BM25_TOP_K
    ) -> list[Document]:
        """
        BM25 keyword search using pre-warmed per-collection indices.
        """
        all_results: list[Document] = []

        for coll_name in collection_names:
            retriever = self._bm25_cache.get(coll_name)
            if retriever is None:
                continue

            try:
                retriever.k = top_k
                results = retriever.invoke(query)
                for doc in results:
                    doc.metadata["_source"] = "bm25"
                all_results.extend(results)
            except Exception as e:
                log.error(f"BM25 search failed for '{coll_name}': {e}")

        return all_results

    def hybrid_search(
        self,
        query: str,
        domain: str = "all",
        top_k: int = FINAL_TOP_K,
    ) -> list[Document]:
        """
        Ensemble retrieval: merge semantic + BM25 results,
        deduplicate by source_file+chunk_index, and rank.
        """
        collection_names = DOMAIN_MAP.get(domain, COLLECTION_NAMES)

        semantic_results = self._semantic_search(query, collection_names)
        bm25_results = self._bm25_search(query, collection_names)

        # Merge with weighted scoring
        scored: dict[str, tuple[float, Document]] = {}

        for doc in semantic_results:
            key = f"{doc.metadata.get('source_file', '')}::{doc.metadata.get('chunk_index', 0)}"
            score = doc.metadata.get("_score", 0.5) * SEMANTIC_WEIGHT
            if key in scored:
                old_score, old_doc = scored[key]
                scored[key] = (old_score + score, old_doc)
            else:
                scored[key] = (score, doc)

        for i, doc in enumerate(bm25_results):
            key = f"{doc.metadata.get('source_file', '')}::{doc.metadata.get('chunk_index', 0)}"
            # BM25 rank-based score: higher rank = higher score
            bm25_score = (1.0 - i / max(len(bm25_results), 1)) * (1.0 - SEMANTIC_WEIGHT)
            if key in scored:
                old_score, old_doc = scored[key]
                scored[key] = (old_score + bm25_score, old_doc)
            else:
                scored[key] = (bm25_score, doc)

        # Sort by combined score, take top_k
        ranked = sorted(scored.values(), key=lambda x: x[0], reverse=True)
        return [doc for _, doc in ranked[:top_k]]

    def get_simbot_log_entries(self, n_runs: int = 3) -> list[dict]:
        """
        Retrieve the N most recent SimBot log chunks, grouped by run_id.
        Returns raw chunk data for the summary tool to process.
        """
        coll = self.collections.get("simbot_logs")
        if coll is None or coll.count() == 0:
            return []

        try:
            data = coll.get(include=["documents", "metadatas"])
        except Exception:
            return []

        # Group by run_id, sort by last_modified descending
        runs: dict[str, list[dict]] = {}
        for i, doc_text in enumerate(data["documents"]):
            meta = data["metadatas"][i] if data["metadatas"] else {}
            run_id = meta.get("run_id", "unknown")
            if run_id not in runs:
                runs[run_id] = []
            runs[run_id].append(
                {
                    "text": doc_text,
                    "metadata": meta,
                }
            )

        def run_sort_key(run_chunks: list[dict]) -> str:
            dates = [c["metadata"].get("last_modified", "") for c in run_chunks]
            return max(dates) if dates else ""

        sorted_runs = sorted(
            runs.items(), key=lambda kv: run_sort_key(kv[1]), reverse=True
        )
        return [
            {"run_id": rid, "chunks": chunks}
            for rid, chunks in sorted_runs[:n_runs]
        ]


# ════════════════════════════════════════════════════════════
# LangGraph Memory + RAG Chain
# ════════════════════════════════════════════════════════════


class AgentState(TypedDict):
    messages: Annotated[Sequence[BaseMessage], operator.add]
    context: str
    question: str
    domain: str


def build_rag_graph(retriever: ProjectRetriever) -> tuple[Any, SqliteSaver]:
    """
    Build a LangGraph RAG chain with SQLite-backed memory.
    The graph: retrieve_context → maybe_summarize → generate_answer
    """
    llm = ChatOllama(model=LLM_MODEL, temperature=0.1)

    # ── SQLite checkpointer for cross-session memory ─────
    conn = sqlite3.connect(str(MEMORY_DB_PATH), check_same_thread=False)
    checkpointer = SqliteSaver(conn)
    checkpointer.setup()

    # ── Prompt template ──────────────────────────────────
    prompt = ChatPromptTemplate.from_messages(
        [
            ("system", SYSTEM_PROMPT),
            MessagesPlaceholder(variable_name="history"),
            (
                "human",
                """Answer the following question using the retrieved context.
Cite source files when referencing specific information.
If the context doesn't contain enough information, say so clearly.

Context:
{context}

Question: {question}""",
            ),
        ]
    )

    # ── Graph nodes ──────────────────────────────────────

    def retrieve_node(state: AgentState) -> dict:
        """Retrieve relevant context for the question."""
        question = state["question"]
        domain = state.get("domain", "all")
        docs = retriever.hybrid_search(question, domain=domain, top_k=FINAL_TOP_K)

        context_parts = []
        for doc in docs:
            fname = doc.metadata.get("file_name", "unknown")
            context_parts.append(f"[Source: {fname}]\n{doc.page_content}")

        context = (
            "\n\n---\n\n".join(context_parts)
            if context_parts
            else "No relevant context found."
        )
        return {"context": context}

    def maybe_summarize_node(state: AgentState) -> dict:
        """
        Optional summarization/prune step to keep history bounded.
        Summarize when more than 10 messages are stored.
        """
        messages = list(state.get("messages", []))
        if len(messages) <= 10:
            return {}

        # Use last 4 messages as recent context, summarize the rest.
        recent = messages[-4:]
        to_summarize = messages[:-4]

        summary_prompt = ChatPromptTemplate.from_messages(
            [
                (
                    "system",
                    "Summarize the following conversation so far into a concise "
                    "system message that captures key decisions and facts.",
                ),
                MessagesPlaceholder(variable_name="history"),
            ]
        )
        chain = summary_prompt | llm | StrOutputParser()
        summary_text = chain.invoke({"history": to_summarize})
        summary_msg = SystemMessage(content=f"Conversation summary: {summary_text}")

        return {"messages": [summary_msg] + recent}

    def generate_node(state: AgentState) -> dict:
        """Generate an answer using LLM with context and history."""
        history = list(state.get("messages", []))[-20:]

        chain = prompt | llm | StrOutputParser()
        answer = chain.invoke(
            {
                "history": history,
                "context": state["context"],
                "question": state["question"],
            }
        )

        return {
            "messages": [
                HumanMessage(content=state["question"]),
                AIMessage(content=answer),
            ]
        }

    # ── Build graph ──────────────────────────────────────
    graph = StateGraph(AgentState)
    graph.add_node("retrieve", retrieve_node)
    graph.add_node("maybe_summarize", maybe_summarize_node)
    graph.add_node("generate", generate_node)
    graph.add_edge(START, "retrieve")
    graph.add_edge("retrieve", "maybe_summarize")
    graph.add_edge("maybe_summarize", "generate")
    graph.add_edge("generate", END)

    compiled = graph.compile(checkpointer=checkpointer, durability="sync")
    return compiled, checkpointer


# ════════════════════════════════════════════════════════════
# Tool implementations
# ════════════════════════════════════════════════════════════


def format_sources(docs: list[Document]) -> list[dict]:
    """Format source documents for the tool response."""
    sources: list[dict] = []
    seen = set()
    for doc in docs:
        fname = doc.metadata.get("file_name", "unknown")
        if fname in seen:
            continue
        seen.add(fname)
        sources.append(
            {
                "file": fname,
                "path": doc.metadata.get("source_file", ""),
                "domain": doc.metadata.get("domain", ""),
                "preview": (
                    doc.page_content[:200] + "..."
                    if len(doc.page_content) > 200
                    else doc.page_content
                ),
            }
        )
    return sources


def format_simbot_summary(run_data: list[dict]) -> str:
    """
    Parse SimBot log chunks and produce a structured summary.
    Handles both JSON and CSV log formats.
    """
    if not run_data:
        return json.dumps(
            {
                "status": "no_data",
                "message": (
                    "No SimBot logs found in the index. "
                    "Run SimBot first, then re-index."
                ),
            },
            indent=2,
        )

    summaries = []
    for run in run_data:
        run_id = run["run_id"]
        combined_text = "\n".join(c["text"] for c in run["chunks"])
        last_mod = max(
            (c["metadata"].get("last_modified", "") for c in run["chunks"]),
            default="unknown",
        )

        metrics: dict[str, Any] = {
            "run_id": run_id,
            "last_modified": last_mod,
            "chunk_count": len(run["chunks"]),
        }

        # Try JSON parsing for structured metrics
        try:
            data = json.loads(combined_text)
            if isinstance(data, dict):
                for key in [
                    "waves_survived",
                    "total_gold_earned",
                    "total_gold_spent",
                    "enemies_killed",
                    "buildings_placed",
                    "buildings_destroyed",
                    "tower_hp_remaining",
                    "strategy_profile",
                    "total_days",
                ]:
                    if key in data:
                        metrics[key] = data[key]
            elif isinstance(data, list):
                metrics["record_count"] = len(data)
                if data and isinstance(data[0], dict):
                    metrics["sample_keys"] = list(data[0].keys())[:10]
        except (json.JSONDecodeError, TypeError):
            pass

        # Regex extraction for common metric patterns in any text format
        patterns = {
            "waves_survived": r"waves?[_\s]*survived[:\s]*(\d+)",
            "gold_earned": r"gold[_\s]*earned[:\s]*(\d+)",
            "gold_spent": r"gold[_\s]*spent[:\s]*(\d+)",
            "enemies_killed_total": r"(?:total[_\s]*)?enemies[_\s]*killed[:\s]*(\d+)",
            "buildings_placed": r"buildings?[_\s]*placed[:\s]*(\d+)",
            "tower_hp_remaining": r"tower[_\s]*hp[_\s]*(?:remaining)?[:\s]*(\d+)",
        }
        for metric_name, pattern in patterns.items():
            if metric_name not in metrics:
                m = re.search(pattern, combined_text, re.IGNORECASE)
                if m:
                    metrics[metric_name] = int(m.group(1))

        # Include raw text preview if no structured data found
        if len(metrics) <= 3:  # Only run_id, last_modified, chunk_count
            metrics["raw_preview"] = combined_text[:500]

        summaries.append(metrics)

    return json.dumps(
        {
            "status": "ok",
            "runs_found": len(summaries),
            "summaries": summaries,
        },
        indent=2,
    )


# ════════════════════════════════════════════════════════════
# MCP Server
# ════════════════════════════════════════════════════════════


def _check_ollama_alive() -> bool:
    import urllib.request

    try:
        urllib.request.urlopen("http://localhost:11434/api/tags", timeout=3)
        return True
    except Exception:
        return False


def create_server() -> Server:
    """Create and configure the MCP server."""
    if not _check_ollama_alive():
        log.error(
            "Ollama is not reachable at http://localhost:11434 — "
            "embedding and LLM calls will fail. "
            "Start Ollama with `ollama serve` first."
        )

    server = Server("foulward-rag")
    retriever = ProjectRetriever()

    # Warm up LLM and embeddings with a dummy call to reduce first-call latency
    try:
        _ = retriever.embeddings.embed_query("warmup")
    except Exception as e:
        log.warning(f"Embedding warmup failed: {e}")

    rag_graph, _checkpointer = build_rag_graph(retriever)

    # ── Tool definitions ─────────────────────────────────
    TOOLS = [
        Tool(
            name="query_project_knowledge",
            description=(
                "Search the Foul Ward project knowledge base using hybrid "
                "BM25 + semantic retrieval. Returns an LLM-generated answer "
                "with source file citations. Use this to look up architecture "
                "decisions, GDScript code patterns, resource file values, "
                "signal flows, or any project-specific information. "
                "Set domain to narrow the search: 'all', 'architecture' (docs), "
                "'code' (GDScript), 'resources' (.tres files), 'simbot_logs', "
                "or 'balance' (resources + logs together)."
            ),
            inputSchema={
                "type": "object",
                "properties": {
                    "question": {
                        "type": "string",
                        "description": "The question to answer about the Foul Ward project.",
                    },
                    "domain": {
                        "type": "string",
                        "description": (
                            "Which domain to search. Options: all, architecture, "
                            "code, resources, simbot_logs, balance, docs, scripts, logs."
                        ),
                        "default": "all",
                        "enum": [
                            "all",
                            "architecture",
                            "code",
                            "resources",
                            "simbot_logs",
                            "balance",
                            "docs",
                            "scripts",
                            "logs",
                        ],
                    },
                },
                "required": ["question"],
            },
        ),
        Tool(
            name="get_recent_simbot_summary",
            description=(
                "Get a structured summary of the most recent SimBot simulation "
                "runs. Returns key metrics per run: waves survived, gold earned/"
                "spent, enemies killed by type, buildings placed/destroyed, and "
                "tower HP remaining. Use this before any balance-related work to "
                "ground your analysis in actual simulation data."
            ),
            inputSchema={
                "type": "object",
                "properties": {
                    "n_runs": {
                        "type": "integer",
                        "description": "Number of recent runs to summarize (default: 3).",
                        "default": 3,
                        "minimum": 1,
                        "maximum": 20,
                    },
                },
                "required": [],
            },
        ),
    ]

    # ── MCP handlers ─────────────────────────────────────

    @server.list_tools()
    async def list_tools() -> list[Tool]:
        return TOOLS

    @server.call_tool()
    async def call_tool(name: str, arguments: dict) -> list[TextContent]:
        log.info(f"Tool call: {name}({arguments})")

        if name == "query_project_knowledge":
            question = arguments.get("question", "")
            domain = arguments.get("domain", "all")

            if not question.strip():
                return [
                    TextContent(
                        type="text",
                        text=json.dumps({"error": "Empty question provided."}),
                    )
                ]

            # Run hybrid retrieval
            docs = retriever.hybrid_search(question, domain=domain)
            sources = format_sources(docs)

            # Run through LangGraph RAG chain with memory
            try:
                config = {"configurable": {"thread_id": f"foulward_{domain}"}}
                result = rag_graph.invoke(
                    {
                        "messages": [],
                        "context": "",
                        "question": question,
                        "domain": domain,
                    },
                    config=config,
                )

                # Extract the last AI message as the answer
                answer = ""
                for msg in reversed(result.get("messages", [])):
                    if isinstance(msg, AIMessage):
                        answer = msg.content
                        break

                if not answer:
                    answer = "Could not generate an answer from the retrieved context."

            except Exception as e:
                log.error(f"RAG chain error: {e}")
                # Fallback: return raw context without LLM synthesis
                context_text = "\n\n".join(
                    f"[{d.metadata.get('file_name', '?')}] {d.page_content[:300]}"
                    for d in docs
                )
                answer = f"(LLM unavailable — raw retrieval results)\n\n{context_text}"

            response = {
                "answer": answer,
                "sources": sources,
                "domain_searched": domain,
                "chunks_retrieved": len(docs),
            }
            return [TextContent(type="text", text=json.dumps(response, indent=2))]

        elif name == "get_recent_simbot_summary":
            n_runs = arguments.get("n_runs", 3)
            run_data = retriever.get_simbot_log_entries(n_runs=n_runs)
            summary = format_simbot_summary(run_data)
            return [TextContent(type="text", text=summary)]

        else:
            return [
                TextContent(
                    type="text",
                    text=json.dumps({"error": f"Unknown tool: {name}"}),
                )
            ]

    return server


# ════════════════════════════════════════════════════════════
# Entry point
# ════════════════════════════════════════════════════════════


async def main():
    log.info("Starting Foul Ward RAG MCP Server...")
    log.info(f"ChromaDB: {CHROMA_PATH}")
    log.info(f"Memory DB: {MEMORY_DB_PATH}")

    server = create_server()

    async with stdio_server() as (read_stream, write_stream):
        log.info("MCP server running on stdio transport.")
        await server.run(
            read_stream,
            write_stream,
            InitializationOptions(
                server_name="foulward-rag",
                server_version="1.0.0",
                capabilities=server.get_capabilities(
                    notification_options=NotificationOptions(),
                    experimental_capabilities={},
                ),
            ),
        )


if __name__ == "__main__":
    import asyncio

    asyncio.run(main())
