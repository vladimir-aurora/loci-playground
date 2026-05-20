# LOCI test projects — Cortex-M4 / armv7e-m

Five small open-source projects plus a linked demo ELF, all cross-compiled
for **Cortex-M4F** with **TI Arm Clang**, so every LOCI skill —
`/exec-trace`, `/stack-depth`, `/memory-report`, `/control-flow`,
`/trends`, `/bug-report`, plus the auto-firing `preflight` and `post-edit`
hooks — has real artifacts to analyze.

| Project   | Upstream                              | Files compiled | LOCI angle |
|-----------|---------------------------------------|----------------|------------|
| micro-ecc | github.com/kmackay/micro-ecc          | 1 .c           | One long crypto exec trace; thumb2 asm paths |
| littlefs  | github.com/littlefs-project/littlefs  | 2 .c           | Recursive directory walk → stack depth |
| tinycrypt | github.com/intel/tinycrypt            | 15 .c          | Many small algorithms side by side |
| printf    | github.com/eyalroz/printf             | 1 .c           | Huge switch — control-flow + format-cost |
| cJSON     | github.com/DaveGamble/cJSON           | 1 .c           | Recursive-descent parser → stack depth |
| demo      | (this repo)                           | 1 .c → ELF     | Linked Cortex-M4 image for `/memory-report` |

## Prerequisites

| Tool          | Version checked | Notes |
|---------------|-----------------|-------|
| TI Arm Clang  | 2.1.3 LTS       | Defaults: `C:\ti\ticlang` (Win), `/opt/ti/ticlang` (Linux). Override via `$TIARMCLANG_DIR`. macOS is unsupported by TI — see below. |
| CMake         | >= 3.16         | 4.x is fine. |
| Ninja         | any             | `choco install ninja` / `apt install ninja-build` / `brew install ninja`. |
| Git           | any             | With submodule support (every modern version). |
| Bash          | any             | Git Bash on Windows; native bash on Linux/macOS. |

**macOS note:** TI does not ship Arm Clang for macOS. Build inside a
Linux VM/container, or set `TIARMCLANG_DIR` to a locally-sourced install.
The build scripts will exit with a clear error otherwise.

## One-time setup

```bash
git clone --recurse-submodules git@github.com:vladimir-aurora/loci-test-projects.git
cd loci-test-projects
./build.sh
```

If you already cloned without `--recurse-submodules`, run `./setup.sh`
first. `./build.sh --clean` wipes the build directory. Custom toolchain
location: `TIARMCLANG_DIR=/path/to/ticlang ./build.sh`.

## Layout

```
loci-test-projects/
├── .gitmodules                          # 5 upstream pins (HTTPS)
├── .gitattributes                       # forces LF on shell scripts
├── CMakeLists.txt                       # top-level, adds all subdirs
├── toolchain/
│   └── cortex-m4-tiarmclang.cmake       # cross-platform toolchain file
├── setup.sh                             # `git submodule update --init`
├── build.sh                             # configure + build everything
├── micro-ecc/   CMakeLists.txt + upstream/   (submodule)
├── littlefs/    CMakeLists.txt + upstream/
├── tinycrypt/   CMakeLists.txt + upstream/
├── printf/      CMakeLists.txt + upstream/
├── cjson/       CMakeLists.txt + upstream/
└── demo/        CMakeLists.txt + main.c    # → demo.elf for memory-report
```

## Build flags

From `toolchain/cortex-m4-tiarmclang.cmake`:

```
-mcpu=cortex-m4 -mfpu=fpv4-sp-d16 -mfloat-abi=hard -mthumb
-ffunction-sections -fdata-sections
```

`STATIC_LIBRARY` is forced as the try-compile target type so CMake never
tries to link a Cortex-M4 executable on the host.

## Running every LOCI skill against this project

Open a Claude Code session with this directory as cwd so LOCI initializes
the project context against `compile_commands.json` (CMake generates it
at `.loci-build/compile_commands.json` automatically). Then:

### `/exec-trace <function>` — instruction-level timing + energy

Computes worst-path / happy-path execution time and energy on the
compiled assembly. Best targets here are functions that do one bounded
piece of work.

```text
/exec-trace uECC_sign           # ECDSA sign — long arithmetic-heavy trace
/exec-trace tc_aes_encrypt      # one AES-128 block — clean SIMD32 paths
/exec-trace tc_sha256_compress  # SHA-256 inner loop, 64 rounds
/exec-trace cJSON_Parse         # full recursive parse of a JSON blob
/exec-trace vsnprintf_          # printf format dispatch
```

### `/stack-depth <function>` — worst-case stack budget

Traverses the call graph from the entry function and reports the maximum
frame chain. Best targets are recursive / deeply-nested code.

```text
/stack-depth cJSON_Parse        # recursive descent → adversarial JSON
/stack-depth lfs_dir_traverse   # filesystem tree walk
/stack-depth uECC_sign          # bounded but deep call chain
```

### `/memory-report` — ROM/RAM section + region breakdown

Needs a linked ELF. That's why `demo/demo.elf` exists — it pulls in one
symbol per `.o` from every library plus TI's standard runtime so the
report reflects a realistic Cortex-M4 image (213 KB ELF, ~25 KB of code
from the libraries themselves).

```text
/memory-report                  # against .loci-build/demo/demo.elf
```

### `/control-flow <function>` — annotated CFG

Renders the function's basic-block graph in a text format optimized for
LLM analysis. Best targets are branchy code.

```text
/control-flow vsnprintf_        # giant switch over format specifiers
/control-flow tc_sha256_update  # block-fed compress loop
/control-flow lfs_dir_fetchmatch  # directory entry matching
```

### `/trends` — per-function measurement history

Shows how a function's timing / energy / stack / memory have moved over
recent edits on the current branch. To populate history, run an exec-trace,
make a change, rebuild, and exec-trace again.

```text
/trends                          # everything measured on this branch
/trends uECC_sign                # one function's trajectory
```

### `/bug-report` — diagnostic when LOCI itself misbehaves

Collects environment state and runs health checks. Use it when a skill
doesn't fire, results look wrong, or the MCP isn't connecting.

```text
/bug-report
```

### Auto-firing skills: `preflight` and `post-edit`

These don't need a slash command. They fire automatically:

**`preflight`** — when you're in `/plan` mode and describe new logic
("implement", "add", "refactor", "modify"). Before you make the edit,
LOCI analyzes the callees of the function you're about to touch and
reports timing / energy / control-flow constraints.

To exercise it deliberately:

> Enter plan mode (`/plan`), then say something like:
> *"I want to add an LRU cache in front of cJSON_Parse to skip re-parsing
> identical JSON blobs."* Preflight will analyze `cJSON_Parse`'s callees
> on the compiled artifact and surface stack / timing facts before you
> commit to an approach.

**`post-edit`** — fires automatically after any Edit/Write/MultiEdit to
a `.c` / `.cc` / `.cpp` / `.cxx` / `.h` / `.hpp` / `.hxx` / `.rs` file.
It compiles the post-edit object, compares against the pre-edit object
captured by the pre-edit hook, and reports the timing/energy/control-flow
delta.

To exercise it deliberately:

> Open any library source — e.g. `tinycrypt/upstream/lib/source/sha256.c`
> — make a non-trivial edit (unroll a loop, change a constant in the
> compress step, swap an operation order). Save. Post-edit will fire
> automatically and report the % diff.

The post-edit hook needs a pre-edit baseline captured by the pre-edit
hook on the same Claude Code session. Editing a file LOCI has never seen
in this session gives you a first-measurement record (no `% diff`).

### `/help` — LOCI quick-reference

```text
/help                           # lists every skill + environment status
```

## Adding another project

1. `git submodule add <url> <name>/upstream`
2. Create `<name>/CMakeLists.txt` with a single `add_library(<name> STATIC ...)`.
3. Add `add_subdirectory(<name>)` to the top-level `CMakeLists.txt`.
4. If you want the new library represented in `demo.elf` (for
   `/memory-report`), add `extern` references to one or two of its
   symbols in `demo/main.c` and add the library name to its
   `target_link_libraries`.

## Updating an upstream pin

```bash
cd micro-ecc/upstream
git fetch && git checkout <new-sha-or-tag>
cd ../..
git add micro-ecc/upstream
git commit -m "bump micro-ecc to <ref>"
```

## One-liner

```bash
git clone --recurse-submodules git@github.com:vladimir-aurora/loci-test-projects.git && cd loci-test-projects && ./build.sh
```

TI Arm Clang, Ninja, and CMake are the only manual installs; everything
else is automatic.
