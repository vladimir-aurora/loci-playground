cmake_minimum_required(VERSION 3.16)
project(loci-playground C)

# These projects only ever build as object libraries / static archives for
# Cortex-M4 analysis. No executables, no linker, no host fallback.
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS OFF)

# Quiet down host warnings we don't care about in cross-compiled crypto/parser code.
add_compile_options(-Wno-unused-function -Wno-unused-variable)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# LOCI analyses optimized code with DWARF: -O2 -g -DNDEBUG. Without this,
# CMake's empty default yields -O0 and no debug info, neither of which
# matches real firmware or gives LOCI source-line mapping.
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_BUILD_TYPE RelWithDebInfo CACHE STRING "Build type" FORCE)
endif()

# Sanity check: this tree is meaningless without a cross-toolchain.
if(NOT CMAKE_CROSSCOMPILING)
    message(FATAL_ERROR
        "This project must be configured with the Cortex-M4 toolchain file:\n"
        "  cmake -B build -G Ninja -DCMAKE_TOOLCHAIN_FILE=toolchain/cortex-m4-tiarmclang.cmake")
endif()

message(STATUS "LOCI playground — target: ${CMAKE_SYSTEM_PROCESSOR}, compiler: ${CMAKE_C_COMPILER}")

add_subdirectory(micro-ecc)
add_subdirectory(littlefs)
add_subdirectory(tinycrypt)
add_subdirectory(printf)
add_subdirectory(cjson)
add_subdirectory(demo)
