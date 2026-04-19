#!/usr/bin/env bash
# Finish TRELLIS.2 native extensions in conda env trellis2.
# Optional: sudo ./tools/install_gen3d_system_deps.sh (system nvcc + libjpeg) — not required if
# CUDA toolkit was installed into the conda env (see gen3d/pipeline/stage2_mesh.py env wiring).
# Run as your user (not root): ./tools/run_trellis2_setup.sh
set -euo pipefail

SECRETS_FILE="${FOULWARD_SECRETS_FILE:-${HOME}/.foulward_secrets}"
if [[ -r "${SECRETS_FILE}" ]]; then
	# shellcheck disable=SC1090
	set -a
	# shellcheck disable=SC1090
	source "${SECRETS_FILE}"
	set +a
fi

export CONDA_ALWAYS_YES=true
export PATH="${HOME}/miniconda3/bin:${PATH}"
if [[ ! -x "${HOME}/miniconda3/bin/conda" ]]; then
	echo "error: Miniconda not found at ${HOME}/miniconda3/bin/conda" >&2
	exit 1
fi
# shellcheck disable=SC1091
source "${HOME}/miniconda3/etc/profile.d/conda.sh"
conda activate trellis2
if [[ -z "${CUDA_HOME:-}" ]]; then
	shopt -s nullglob
	for _cuda in /usr/lib/cuda /usr/lib/cuda-* /usr/local/cuda; do
		if [[ -x "${_cuda}/bin/nvcc" ]]; then
			export CUDA_HOME="${_cuda}"
			break
		fi
	done
	shopt -u nullglob
	if [[ -z "${CUDA_HOME:-}" ]] && command -v nvcc >/dev/null 2>&1; then
		export CUDA_HOME="$(dirname "$(dirname "$(command -v nvcc)")")"
	fi
fi
if [[ -z "${CUDA_HOME:-}" ]] || [[ ! -d "${CUDA_HOME}" ]]; then
	echo "error: CUDA_HOME not set or invalid. Install nvidia-cuda-toolkit, then:" >&2
	echo "  export CUDA_HOME=/usr/lib/cuda   # or: dirname of nvcc parent" >&2
	exit 1
fi
TRELLIS_ROOT="${TRELLIS_ROOT:-${HOME}/TRELLIS.2}"
if [[ ! -f "${TRELLIS_ROOT}/setup.sh" ]]; then
	echo "error: TRELLIS.2 not found at ${TRELLIS_ROOT}. Clone: git clone -b main --recursive https://github.com/microsoft/TRELLIS.2.git" >&2
	exit 1
fi
cd "${TRELLIS_ROOT}"
# shellcheck disable=SC1091
. ./setup.sh --basic --flash-attn --nvdiffrast --nvdiffrec --cumesh --o-voxel --flexgemm
echo "OK: TRELLIS setup.sh finished."
