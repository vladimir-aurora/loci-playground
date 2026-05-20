# CMake toolchain file: TI Arm Clang targeting Cortex-M4F (armv7e-m)
#
# Usage:
#   cmake -B build -G Ninja -DCMAKE_TOOLCHAIN_FILE=toolchain/cortex-m4-tiarmclang.cmake
#
# Override the compiler location with -DTIARMCLANG_DIR=... if it lives somewhere
# other than C:/ti/ticlang. The LOCI plugin expects this default path.

set(CMAKE_SYSTEM_NAME       Generic)
set(CMAKE_SYSTEM_PROCESSOR  arm)

if(NOT DEFINED TIARMCLANG_DIR)
    if(DEFINED ENV{TIARMCLANG_DIR})
        set(TIARMCLANG_DIR "$ENV{TIARMCLANG_DIR}")
    else()
        set(TIARMCLANG_DIR "C:/ti/ticlang")
    endif()
endif()

set(CMAKE_C_COMPILER   "${TIARMCLANG_DIR}/bin/tiarmclang.exe")
set(CMAKE_CXX_COMPILER "${TIARMCLANG_DIR}/bin/tiarmclang.exe")
set(CMAKE_ASM_COMPILER "${TIARMCLANG_DIR}/bin/tiarmclang.exe")
set(CMAKE_AR           "${TIARMCLANG_DIR}/bin/tiarmar.exe" CACHE FILEPATH "archiver")

# Cortex-M4F (single-precision FPU, hard ABI, Thumb-only)
set(CPU_FLAGS "-mcpu=cortex-m4 -mfpu=fpv4-sp-d16 -mfloat-abi=hard -mthumb")

# Object-only builds: no linker step, no startup, no libc dependency.
# LOCI analyses the .o / .a artifacts directly.
set(CMAKE_C_FLAGS_INIT   "${CPU_FLAGS} -ffunction-sections -fdata-sections")
set(CMAKE_CXX_FLAGS_INIT "${CPU_FLAGS} -ffunction-sections -fdata-sections")
set(CMAKE_ASM_FLAGS_INIT "${CPU_FLAGS}")

# We don't link — tell CMake's compiler test not to either.
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

# Keep find_* from picking up host artifacts.
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
