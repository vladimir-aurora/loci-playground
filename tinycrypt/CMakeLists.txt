# TinyCrypt — small crypto primitives from Intel
# Upstream: github.com/intel/tinycrypt
#
# LOCI demo angle: many small focused functions (tc_aes_encrypt,
# tc_sha256_update, tc_hmac_*) — perfect for comparing /exec-trace across
# algorithms and for /control-flow on each.

file(GLOB TINYCRYPT_SOURCES CONFIGURE_DEPENDS upstream/lib/source/*.c)

add_library(tinycrypt STATIC ${TINYCRYPT_SOURCES})

target_include_directories(tinycrypt PUBLIC upstream/lib/include)
