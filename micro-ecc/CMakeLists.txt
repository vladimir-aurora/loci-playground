# micro-ecc — tiny ECDSA / ECDH library
# Upstream: github.com/kmackay/micro-ecc
#
# LOCI demo angle: a single big-integer crypto routine (uECC_sign,
# uECC_shared_secret) gives one long exec trace dominated by modular
# arithmetic. uECC_PLATFORM=5 enables the inline ARM-thumb2 asm paths.

add_library(micro_ecc STATIC
    upstream/uECC.c
)

target_include_directories(micro_ecc PUBLIC upstream)

target_compile_definitions(micro_ecc PRIVATE
    uECC_PLATFORM=5             # uECC_arm_thumb2
    uECC_OPTIMIZATION_LEVEL=1   # >=2 pulls in vli_sub thumb2 asm that exhausts the regalloc under -O2
    uECC_SUPPORTS_secp256r1=1
    uECC_SUPPORTS_secp192r1=0
    uECC_SUPPORTS_secp224r1=0
    uECC_SUPPORTS_secp256k1=0
    uECC_SUPPORT_COMPRESSED_POINT=0
)
