#!/usr/bin/env bash
# One-shot system packages for gen3d / TRELLIS.2 (CUDA nvcc + libjpeg).
# Run from repo root: sudo ./tools/install_gen3d_system_deps.sh
set -euo pipefail

SECRETS_FILE="${FOULWARD_SECRETS_FILE:-${HOME}/.foulward_secrets}"
if [[ -r "${SECRETS_FILE}" ]]; then
	# shellcheck disable=SC1090
	set -a
	# shellcheck disable=SC1090
	source "${SECRETS_FILE}"
	set +a
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y nvidia-cuda-toolkit libjpeg-dev
echo "OK: nvidia-cuda-toolkit + libjpeg-dev installed."
command -v nvcc >/dev/null && nvcc --version | head -3 || echo "warning: nvcc not on PATH yet; open a new shell or source ~/.bashrc"
