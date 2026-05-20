# demo — links the five libraries into a single Cortex-M4 ELF so that
# LOCI's /memory-report has section budgets to analyse.
#
# The binary is intentionally not runnable on real hardware: it has no
# clock init, no peripherals, no I/O. Only its section/symbol layout
# matters. TI Arm Clang's default linker command file (auto-injected via
# --rom_model) handles startup, vectors, and section placement — using
# TI's own runtime here is more representative of a real Cortex-M
# project than a hand-rolled minimal startup would be.

add_executable(demo main.c)

target_link_libraries(demo PRIVATE
    micro_ecc
    littlefs
    tinycrypt
    printf
    cjson
)

set_target_properties(demo PROPERTIES SUFFIX ".elf")
