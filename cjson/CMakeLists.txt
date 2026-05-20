# cJSON — ultra-light JSON parser/printer
# Upstream: github.com/DaveGamble/cJSON
#
# LOCI demo angle: cJSON_Parse is a textbook recursive-descent parser —
# ideal for /stack-depth on adversarial inputs and /control-flow on the
# tokenizer. We skip cJSON_Utils (JSON Patch helper) to keep the surface
# small; add it back if you want a second analysis target.

add_library(cjson STATIC
    upstream/cJSON.c
)

target_include_directories(cjson PUBLIC upstream)
