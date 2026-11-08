#!/usr/bin/env bash
set -euo pipefail

# Build sys-con for Nintendo Switch in the official devkitPro image.
# The repository is mounted rather than copied so the normal project Makefile
# and all source files are available inside the container.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR="${PROJECT_ROOT}/build-switch"
IMAGE="${DEVKITPRO_DOCKER_IMAGE:-sys-con-switch-builder:local}"

if [[ -n "${CONTAINER_ENGINE:-}" ]]; then
    ENGINE="$CONTAINER_ENGINE"
elif command -v docker >/dev/null 2>&1; then
    ENGINE="docker"
elif command -v podman >/dev/null 2>&1; then
    ENGINE="podman"
else
    echo "[ERROR] Neither docker nor podman was found." >&2
    exit 2
fi

if [[ "${SKIP_IMAGE_BUILD:-0}" != "1" ]]; then
    echo "Building image: ${IMAGE}"
    "$ENGINE" build -t "$IMAGE" -f "$SCRIPT_DIR/Dockerfile" "$SCRIPT_DIR"
fi

VOLUME_SUFFIX="${CONTAINER_VOLUME_SUFFIX:-}"
if [[ -z "$VOLUME_SUFFIX" && "$(basename "$ENGINE")" == podman* ]]; then
    VOLUME_SUFFIX=":Z"
fi

USER_ARGS=()
if [[ "${CONTAINER_USE_HOST_USER:-0}" == "1" ]]; then
    USER_ARGS+=(--user "$(id -u):$(id -g)")
fi

TTY_ARGS=()
if [[ -t 0 && -t 1 ]]; then
    TTY_ARGS+=(-it)
fi

echo "Using container engine: ${ENGINE}"
echo "Using image: ${IMAGE}"
echo "Using project: ${PROJECT_ROOT}"

"$ENGINE" run --rm "${TTY_ARGS[@]}" \
    "${USER_ARGS[@]}" \
    -e DEVKITPRO=/opt/devkitpro \
    -e DEVKITA64=/opt/devkitpro/devkitA64 \
    -e LIBNX=/opt/devkitpro/libnx \
    -e PORTLIBS=/opt/devkitpro/portlibs \
    -v "${PROJECT_ROOT}:/workspace${VOLUME_SUFFIX}" \
    -w /workspace \
    "$IMAGE" \
    bash -lc \
    'set -e
     export PATH="$DEVKITA64/bin:$DEVKITPRO/tools/bin:$PORTLIBS/switch/bin:$PATH"
     if [[ "${CLEAN_BUILD:-0}" == "1" ]]; then
         make clean
     fi
     make -j"${JOBS:-$(nproc)}" "$@"' \
    "$@"

BUILD_STATUS=$?
if [[ "$BUILD_STATUS" -eq 0 ]]; then
    rm -rf "$OUTPUT_DIR"
    mkdir -p "$OUTPUT_DIR"
    cp -a "$PROJECT_ROOT/out/." "$OUTPUT_DIR/"
    echo "Build outputs copied to: ${OUTPUT_DIR}"
fi

exit "$BUILD_STATUS"
