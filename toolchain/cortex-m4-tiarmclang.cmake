# CMake toolchain file: TI Arm Clang targeting Cortex-M4F (armv7e-m)
#
# Works on Windows (Git Bash / native), Linux, and macOS hosts.
# The TI Arm Clang compiler itself is only distributed for Windows and Linux,
# so macOS hosts must point TIARMCLANG_DIR at a custom/sourced install.
#
# Usage:
#   cmake -B build -G Ninja -DCMAKE_TOOLCHAIN_FILE=toolchain/cortex-m4-tiarmclang.cmake
#
# Override the compiler location with -DTIARMCLANG_DIR=... or
# $TIARMCLANG_DIR if your install is not at the OS-typical path.

set(CMAKE_SYSTEM_NAME       Generic)
set(CMAKE_SYSTEM_PROCESSOR  arm)

# Resolve the install root: -D wins, then env var, then per-OS default.
if(NOT DEFINED TIARMCLANG_DIR)
    if(DEFINED ENV{TIARMCLANG_DIR})
        set(TIARMCLANG_DIR "$ENV{TIARMCLANG_DIR}")
    elseif(CMAKE_HOST_WIN32)
        set(TIARMCLANG_DIR "C:/ti/ticlang")
    else()
        set(TIARMCLANG_DIR "/opt/ti/ticlang")
    endif()
endif()

# Compiler/archiver executable names differ between Windows and POSIX.
if(CMAKE_HOST_WIN32)
    set(_tic_exe "tiarmclang.exe")
    set(_tia_exe "tiarmar.exe")
else()
    set(_tic_exe "tiarmclang")
    set(_tia_exe "tiarmar")
endif()

set(CMAKE_C_COMPILER   "${TIARMCLANG_DIR}/bin/${_tic_exe}")
set(CMAKE_CXX_COMPILER "${TIARMCLANG_DIR}/bin/${_tic_exe}")
set(CMAKE_ASM_COMPILER "${TIARMCLANG_DIR}/bin/${_tic_exe}")
set(CMAKE_AR           "${TIARMCLANG_DIR}/bin/${_tia_exe}" CACHE FILEPATH "archiver")

# Cortex-M4F (single-precision FPU, hard ABI, Thumb-only).
set(CPU_FLAGS "-mcpu=cortex-m4 -mfpu=fpv4-sp-d16 -mfloat-abi=hard -mthumb")

# Object-only builds: no linker step, no startup, no libc dependency.
# LOCI analyses the .o / .a artifacts directly.
set(CMAKE_C_FLAGS_INIT   "${CPU_FLAGS} -ffunction-sections -fdata-sections")
set(CMAKE_CXX_FLAGS_INIT "${CPU_FLAGS} -ffunction-sections -fdata-sections")
set(CMAKE_ASM_FLAGS_INIT "${CPU_FLAGS}")

# We don't link — make CMake's compiler probe skip the link step.
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

# Keep find_* from picking up host artifacts.
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
