# littlefs — power-cut-safe filesystem for MCUs
# Upstream: github.com/littlefs-project/littlefs
#
# LOCI demo angle: lfs_file_write / lfs_dir_traverse exercise recursion and
# block I/O abstraction — ideal for /stack-depth analysis.
# (We deliberately exclude bd/, tests/, runners/ — those are host-only.)

add_library(littlefs STATIC
    upstream/lfs.c
    upstream/lfs_util.c
)

target_include_directories(littlefs PUBLIC upstream)

target_compile_definitions(littlefs PRIVATE
    LFS_NO_MALLOC               # force static buffers — measurable stack cost
    LFS_NO_ASSERT
    LFS_NO_DEBUG
    LFS_NO_WARN
    LFS_NO_ERROR
)
