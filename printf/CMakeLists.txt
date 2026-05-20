# printf (eyalroz fork) — standalone embedded printf, no libc dependency
# Upstream: github.com/eyalroz/printf
#
# LOCI demo angle: format-string parsing is a giant switch — great for
# /control-flow visualization and for comparing %d vs %f exec cost.
# We bypass the upstream CMake's config-file generation and pass the knobs
# directly as compile definitions, so the build has zero generated files.

add_library(printf STATIC
    upstream/src/printf/printf.c
)

target_include_directories(printf PUBLIC upstream/src)

target_compile_definitions(printf PRIVATE
    # NB: PRINTF_INCLUDE_CONFIG_H is gated by #ifdef, not #if — leave it
    # undefined so printf.h skips the generated config header.
    PRINTF_SUPPORT_DECIMAL_SPECIFIERS=1
    PRINTF_SUPPORT_EXPONENTIAL_SPECIFIERS=1
    PRINTF_SUPPORT_WRITEBACK_SPECIFIER=1
    PRINTF_SUPPORT_LONG_LONG=1
    PRINTF_USE_DOUBLE_INTERNALLY=1
    PRINTF_ALIAS_STANDARD_FUNCTION_NAMES_SOFT=0
    PRINTF_ALIAS_STANDARD_FUNCTION_NAMES_HARD=0
    PRINTF_CHECK_FOR_NUL_IN_FORMAT_SPECIFIER=1
    PRINTF_SUPPORT_MSVC_STYLE_INTEGER_SPECIFIERS=1
)
