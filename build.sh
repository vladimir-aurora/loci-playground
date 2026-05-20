#!/usr/bin/env bash
# build.sh — configure + build all five projects for Cortex-M4F with tiarmclang.
#
# Works in Git Bash on Windows, Linux, and macOS.
#
# Usage:
#   ./build.sh                    # default tiarmclang location for this OS
#   ./build.sh --clean            # wipe the build dir first
#   TIARMCLANG_DIR=/path ./build.sh   # custom toolchain location

set -euo pipefail
cd "$(dirname "$0")"

BUILD_DIR=".loci-build"
TOOLCHAIN_FILE="toolchain/cortex-m4-tiarmclang.cmake"
CLEAN=0

while [ $# -gt 0 ]; do
    case "$1" in
        -c|--clean) CLEAN=1; shift ;;
        -h|--help)
            sed -n '2,12p' "$0" | sed 's/^# \?//'
            exit 0
            ;;
        *) echo "Unknown argument: $1" >&2; exit 2 ;;
    esac
done

# ---- Detect host OS and pick a default tiarmclang location -----------------
case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*) HOST=windows ;;
    Linux*)               HOST=linux ;;
    Darwin*)              HOST=macos ;;
    *)                    HOST=unknown ;;
esac

if [ -z "${TIARMCLANG_DIR:-}" ]; then
    case "$HOST" in
        windows) TIARMCLANG_DIR="C:/ti/ticlang" ;;
        linux)   TIARMCLANG_DIR="/opt/ti/ticlang" ;;
        macos)
            echo "Error: TI Arm Clang is not officially distributed for macOS." >&2
            echo "Either run the build inside a Linux VM/container, or set" >&2
            echo "TIARMCLANG_DIR explicitly if you've sourced a build locally." >&2
            exit 1
            ;;
        *) TIARMCLANG_DIR="/opt/ti/ticlang" ;;
    esac
fi

if [ "$HOST" = windows ]; then
    TIC="$TIARMCLANG_DIR/bin/tiarmclang.exe"
else
    TIC="$TIARMCLANG_DIR/bin/tiarmclang"
fi

if [ ! -f "$TIC" ]; then
    echo "Error: tiarmclang not found at $TIC" >&2
    echo "Install TI Arm Clang or set TIARMCLANG_DIR to your install root." >&2
    exit 1
fi
echo "[info] Host: $HOST"
echo "[info] Using tiarmclang: $TIC"

# ---- Configure + build -----------------------------------------------------
if [ "$CLEAN" -eq 1 ] && [ -d "$BUILD_DIR" ]; then
    echo "[clean] Removing $BUILD_DIR"
    rm -rf "$BUILD_DIR"
fi

# Only pass -DCMAKE_TOOLCHAIN_FILE on the initial configure; CMake caches it
# in CMakeCache.txt and warns about unused variables on subsequent runs.
if [ ! -f "$BUILD_DIR/CMakeCache.txt" ]; then
    cmake -B "$BUILD_DIR" -G Ninja \
        -DCMAKE_TOOLCHAIN_FILE="$TOOLCHAIN_FILE" \
        -DTIARMCLANG_DIR="$TIARMCLANG_DIR"
fi

cmake --build "$BUILD_DIR"

echo
echo "Build complete. Artifacts:"
find "$BUILD_DIR" \( -name '*.a' -o -name '*.lib' -o -name '*.elf' \) -not -path '*/CompilerIdC/*' \
    | sort \
    | while read -r f; do
        sz=$(wc -c < "$f")
        printf "  %8d bytes  %s\n" "$sz" "$f"
    done

echo
echo "To analyse with LOCI, point any of its skills at $BUILD_DIR."
echo "  Example: /exec-trace tc_aes_encrypt   or   /stack-depth lfs_dir_traverse"
