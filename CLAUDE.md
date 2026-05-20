# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A **testbed for the LOCI Claude Code plugin**, not a deliverable firmware project. Five upstream open-source C libraries (micro-ecc, littlefs, tinycrypt, printf, cJSON) plus a `demo/` ELF are cross-compiled for **Cortex-M4F (armv7e-m) using TI Arm Clang**, so LOCI skills (`/exec-trace`, `/stack-depth`, `/memory-report`, `/control-flow`, preflight, post-edit) have real artifacts to analyze. None of the binaries run on real hardware — `demo.elf` has no clock init, no peripherals, no I/O; only its symbol and section layout matter.

## Build commands

```bash
./setup.sh         # one-time: fetch the five submodules (skip if cloned with --recurse-submodules)
./build.sh         # configure + build everything into .loci-build/
./build.sh --clean # wipe .loci-build/ and rebuild from scratch
TIARMCLANG_DIR=/custom/path ./build.sh   # override toolchain location
```

Defaults: `C:/ti/ticlang` on Windows, `/opt/ti/ticlang` on Linux. macOS hosts must supply `TIARMCLANG_DIR` themselves (TI does not distribute Arm Clang for macOS). The build is incremental; `./build.sh` is safe to re-run after edits.

There is no test target, no lint target, no run target. The artifacts (`.a` static libs, `demo.elf`) are the output; LOCI is the consumer.

## Architecture

**Cross-compile-only project.** `CMakeLists.txt` aborts with `FATAL_ERROR` if `CMAKE_CROSSCOMPILING` isn't set — there is no host build path. The toolchain file (`toolchain/cortex-m4-tiarmclang.cmake`) sets `CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY` so CMake's compiler probe never tries to link a Cortex-M4 executable on the host.

Build flags (locked in the toolchain file, do not weaken these — LOCI's numbers depend on them):
```
-mcpu=cortex-m4 -mfpu=fpv4-sp-d16 -mfloat-abi=hard -mthumb
-ffunction-sections -fdata-sections
```

Each subproject is one `add_library(<name> STATIC ...)` over a git submodule under `<name>/upstream/`. The top-level CMake adds them in fixed order; there are no inter-library dependencies. `demo/main.c` exists solely to force one symbol per `.o` from each library into the link via `__attribute__((used)) static int (* const _references[])(void)` — TI's `tiarmlnk` does not honor GNU `--whole-archive`, so explicit symbol references are the portable equivalent. Adding a new library symbol that should appear in `/memory-report` means adding an `extern` + array entry to `demo/main.c`.

`CMAKE_EXPORT_COMPILE_COMMANDS ON` is required — LOCI auto-detects the project by reading `.loci-build/compile_commands.json` on session start.

## LOCI integration notes

- Start Claude Code from the **repo root**. LOCI resolves functions via the call graph and compiled artifacts, not the working directory — you do not `cd` into a subproject to scope a skill.
- The `loci-preflight` skill is mandatory in `/plan` mode when new C/C++/Rust logic is described.
- The `loci-post-edit` skill is mandatory after any Edit/Write/MultiEdit to `.c .cc .cpp .cxx .h .hpp .hxx .rs`. Invoke it immediately, do not batch.
- Never write intermediate files outside the project tree (no `/tmp/`, `/var/tmp/`) — on Windows those paths fail in the venv Python and trigger permission prompts that halt automation. Use `.loci-build/` for scratch.
- For Python calls inside Bash tools, use the venv python (`/c/Users/User/.loci/venv/Scripts/python.exe`) provided in the SessionStart hook context — never bare `python`/`python3`. For parsing JSON from `asm-analyze` / `build-metadata`, use `jq` rather than `python -c` (the plugin emits Unicode that cp1252 stdout cannot encode on Windows).

## Conventions specific to this repo

- **Do not edit `<name>/upstream/`** — those are vendored git submodules. Changes belong in the upstream repo or in our wrapper `CMakeLists.txt`. To bump a pin, `cd <name>/upstream && git checkout <ref> && cd ../.. && git add <name>/upstream && git commit`.
- **Do not add executables** other than `demo/`. The project is artifact-for-analysis, not firmware-to-run.
- **Compile warnings**: the top-level `CMakeLists.txt` silences `-Wno-unused-function -Wno-unused-variable` because the cross-compiled crypto/parser code has many conditional code paths. Don't reintroduce those warnings as errors.
