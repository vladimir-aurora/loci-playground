# LOCI playground — Cortex-M4F testbed

A small, pre-wired set of open-source firmware projects you can build in
about five minutes and use to drive every feature of the **LOCI** Claude
Code plugin. The point is to give you real Cortex-M4 binaries to play
with, so you can try LOCI end-to-end without having to bring your own
embedded codebase to the table.

> **You are testing LOCI itself.** If anything in this README is
> unclear, if a step doesn't "just work," or if a LOCI skill misbehaves
> — that's exactly the feedback we want.
> See [Filing a bug or feedback](#filing-a-bug-or-feedback).

---

## What is LOCI?

Think of LOCI as an **oscilloscope for code that hasn't shipped yet** —
or, for the source-review crowd, a static analyzer that thinks in
silicon instead of syntax. Most tools tell you what your code *says*.
LOCI reads the **compiled binary** — the ELF, the `.o`, the `.a` — and
tells you what the CPU will actually do with it: how long a function
will run, how much energy it'll burn, how deep the stack will get, how
much ROM and RAM it'll cost you, and where the control flow really goes
once the optimizer is finished with it.

It's a Claude Code plugin, which means all of this surfaces as natural
conversation. You ask "what's the worst-case execution time of
`uECC_sign`?" and LOCI hands back hard numbers from the compiled
assembly. No instrumentation, no code changes, no on-target measurement
— everything runs on artifacts the toolchain already produces.

Concretely, LOCI ships seven skills:

| Skill | What you get |
|-------|--------------|
| `/exec-trace`    | Instruction-level worst-path / happy-path timing and energy per call. |
| `/stack-depth`   | Worst-case stack budget — walks the call graph, sums the frames. |
| `/memory-report` | ROM / RAM section breakdown and top consumers from a linked ELF. |
| `/control-flow`  | Annotated control-flow graph (CFG) in a text format LLMs can reason over. |
| `/trends`        | Per-function history of timing / energy / stack / memory across edits. |
| `/bug-report`    | Forensic diagnostic for when LOCI itself misbehaves. |
| `/help`          | Quick reference for everything above. |

Plus two skills that fire automatically, no slash command needed:

- **preflight** runs in `/plan` mode when you describe new logic. It
  analyzes the callees of the function you're about to touch *before*
  you've written a line, so design decisions land on data instead of
  intuition.
- **post-edit** runs after every C/C++/Rust edit. It recompiles, diffs
  the binary against the pre-edit snapshot, and reports the
  timing / energy / CFG delta so you see the impact of the change
  immediately.

For deeper documentation on LOCI itself — skills, configuration, the
analysis model — see **https://docs.loci-dev.net/**. This README only
covers what you need to drive the testbed.

---

## What's in this repo

Five small open-source libraries plus one linked demo ELF, all
cross-compiled for **Cortex-M4F (armv7e-m)** with **TI Arm Clang**.
Each project was picked because it stresses a different LOCI feature:

| Project   | Upstream                              | What it's for |
|-----------|---------------------------------------|---------------|
| micro-ecc | github.com/kmackay/micro-ecc          | One long arithmetic-heavy `/exec-trace` (ECDSA sign / shared secret). |
| littlefs  | github.com/littlefs-project/littlefs  | Filesystem walk → `/stack-depth` on a deep call chain. |
| tinycrypt | github.com/intel/tinycrypt            | Many small algorithms — pick AES, SHA-256, HMAC, or CTR-PRNG for `/exec-trace`. |
| printf    | github.com/eyalroz/printf             | Giant format-specifier switch → `/control-flow`. |
| cJSON     | github.com/DaveGamble/cJSON           | Recursive-descent parser → `/stack-depth` on adversarial JSON. |
| demo      | (this repo)                           | A tiny `main.c` that pulls one symbol from each library into a real Cortex-M4 ELF — that's what `/memory-report` analyzes. |

You don't need to understand any of these libraries to use the testbed.
The skill examples below give you exact function names to copy-paste.

---

## Prerequisites

You'll install a handful of things once. None of them are large, and
LOCI handles its own Python / `uv` / `jq` dependencies automatically
on first run — you don't need to set those up yourself.

| Tool | Why you need it | How to get it |
|------|----------------|---------------|
| **Claude Code** | Hosts the LOCI plugin. | https://claude.ai/code |
| **Git** (with submodules) | Cloning this repo + its five upstream submodules. | Any modern version. On Windows, [Git for Windows](https://git-scm.com/download/win) — that also gives you Git Bash. |
| **TI Arm Clang** (2.1.3 LTS or newer) | Cross-compiler for Cortex-M4. | Free download from TI (myTI account required): https://www.ti.com/tool/download/ARM-CGT-CLANG. Default install path: `C:\ti\ticlang` on Windows, `/opt/ti/ticlang` on Linux. |
| **CMake ≥ 3.16 + Ninja** | Build system. | Windows: `choco install cmake ninja` · Debian/Ubuntu: `sudo apt install cmake ninja-build` · macOS: `brew install cmake ninja` |
| **Network access to `mcp.auroralabs.com`** | LOCI's binary-execution model lives there. Needed for `/exec-trace`, `preflight`, `post-edit`. The other skills work offline. | Make sure your firewall / VPN allows outbound HTTPS to that host. |

> **Why pinned to TI Arm Clang?** LOCI itself supports other ARM
> toolchains (`arm-none-eabi-gcc`, `armcl`, `iccarm`), but this testbed
> deliberately uses a single compiler so every tester gets byte-identical
> artifacts and directly comparable LOCI numbers. Mixing compilers
> across testers would muddy the data we're collecting this round.

> **macOS note:** TI does not ship Arm Clang for macOS. Build inside a
> Linux VM or container, or point `TIARMCLANG_DIR` at a locally-sourced
> install. The build script exits with a clear error if it can't find
> the compiler.

---

## Install the LOCI plugin

LOCI is distributed as a Claude Code marketplace plugin. For this
testing round, install from the **development** channel — that's
`auroralabs-loci/loci-claude-dev`:

```text
/plugin marketplace add auroralabs-loci/loci-claude-dev
/plugin install loci@loci
```

Type those two commands inside any Claude Code session. (The
production channel, `auroralabs-loci/loci-claude`, tracks stable
releases and won't carry the in-flight changes you're being asked to
validate. Don't install from it for testing.)

The first time you start a session in a project, LOCI runs a one-time
bootstrap: it creates a Python 3.12 virtualenv at `~/.loci/venv`,
fetches `uv` and `jq` if they're missing, and detects the project. It
takes **20–40 seconds on first launch** and is silent thereafter.

The first time you invoke an MCP-backed skill (`/exec-trace`,
preflight, or post-edit), Claude Code may also pop up an authorization
prompt for the LOCI MCP server. Approve it. If for some reason it
doesn't appear, type `/mcp` to bring up the server list manually.

Confirm LOCI is live by typing `/help` in Claude Code. You should see
the LOCI quick-reference, with `/exec-trace`, `/stack-depth`,
`/memory-report`, `/control-flow`, `/trends`, and `/bug-report` all
listed.

---

## Clone and build

```bash
git clone --recurse-submodules https://github.com/vladimir-aurora/loci-playground.git
cd loci-playground
./build.sh
```

That's the whole setup. The script:

- detects your OS (Windows / Linux / macOS),
- finds your TI Arm Clang install (override with
  `TIARMCLANG_DIR=/path ./build.sh` if it's somewhere unusual),
- configures CMake with the cross-toolchain file,
- builds five static libraries and one linked `demo.elf` into
  `.loci-build/`.

Re-running `./build.sh` is incremental. `./build.sh --clean` wipes the
build directory and starts fresh. If you cloned without
`--recurse-submodules`, run `./setup.sh` first to fetch the upstream
submodules, then `./build.sh`.

### How LOCI uses this build

Start Claude Code from the **repo root** (`loci-playground/`). LOCI
auto-detects the project on session start by reading
`.loci-build/compile_commands.json` and inspecting the cross-compiled
artifacts.

You do **not** need to `cd` into a subdirectory like `micro-ecc/` or
`cjson/` to "scope" LOCI to that project. Every function in every
library is reachable from the root — LOCI resolves names via the call
graph and the compiled artifacts, not the working directory. Just call
the skill with the function name and LOCI finds it.

---

## Try every LOCI skill

With Claude Code running in the repo root, paste any of the prompts
below. Each one targets a real symbol in one of the cross-compiled
artifacts. Try at least one from each section so you've seen every
LOCI feature work end-to-end.

### `/exec-trace <function>` — timing + energy

Worst-path / happy-path timing and energy on the compiled assembly.
This is LOCI's flagship skill — best aimed at functions that do one
bounded piece of arithmetic-heavy work.

```text
/exec-trace uECC_sign           # ECDSA sign — long, arithmetic-dominated
/exec-trace tc_aes_encrypt      # one AES-128 block
/exec-trace tc_sha256_compress  # SHA-256 inner loop, 64 rounds
/exec-trace cJSON_Parse         # full recursive parse
/exec-trace vsnprintf_          # printf format dispatch
```

### `/stack-depth <function>` — worst-case stack budget

Walks the call graph from the entry function, sums the frame sizes,
and tells you the deepest the stack can get under any input.
Indispensable when you're sizing an RTOS task or chasing a hard-fault.

```text
/stack-depth cJSON_Parse        # recursive descent — adversarial JSON
/stack-depth lfs_dir_traverse   # filesystem tree walk
/stack-depth uECC_sign          # bounded but deep call chain
```

### `/memory-report` — ROM / RAM breakdown

Needs a linked ELF, which is exactly why the `demo/` project exists.
It pulls one symbol from each library plus TI's standard runtime, so
the report you get back reflects a realistic Cortex-M4 image (~25 KB
of library code, ~213 KB total ELF):

```text
/memory-report                  # analyzes .loci-build/demo/demo.elf
```

### `/control-flow <function>` — annotated CFG

Renders the function's basic-block graph in a text format optimized
for LLM reasoning. Best on branchy code where you'd otherwise have to
read the assembly by hand:

```text
/control-flow vsnprintf_          # giant switch over format specifiers
/control-flow tc_sha256_update    # block-fed compress loop
/control-flow lfs_dir_fetchmatch  # directory-entry matching
```

### `/trends` — per-function history

Shows how a function's timing, energy, stack, or memory has moved over
recent edits on the current branch. To populate it, run an
`/exec-trace`, make a change, rebuild, exec-trace again — and watch
LOCI line up the before-and-after.

```text
/trends                          # everything measured on this branch
/trends uECC_sign                # one function's trajectory
```

### Auto-firing: preflight and post-edit

These two run on their own. You don't type a slash command — they fire
in response to what you're doing.

**preflight** kicks in when you're in `/plan` mode and you describe
new logic ("implement", "add", "refactor", "modify"). Before you write
the code, LOCI examines the callees of the function you're about to
touch and surfaces timing, energy, stack, and CFG facts. Decisions get
made with data instead of intuition.

> Try it: type `/plan`, then say:
> *"I want to add an LRU cache in front of `cJSON_Parse` to skip
> re-parsing identical JSON blobs."*

**post-edit** fires after any edit to a `.c` / `.cc` / `.cpp` /
`.cxx` / `.h` / `.hpp` / `.hxx` / `.rs` file. It recompiles the
object, diffs against the pre-edit snapshot, and reports the
timing / energy / CFG delta. You see the cost (or savings) of every
change as soon as you save.

> Try it: open `tinycrypt/upstream/lib/source/sha256.c`. Make a
> non-trivial edit — unroll a loop, change a constant in the compress
> step, swap an operation order. Save. post-edit fires automatically.

The very first edit to a file in a Claude Code session has no
pre-edit baseline yet, so you'll get a "first measurement" record
instead of a `%`-diff. Make a second edit and you'll see the
comparison.

### `/bug-report` — diagnostic

When LOCI itself misbehaves, run this. Full reporting flow in the
next section.

```text
/bug-report
```

---

## Filing a bug or feedback

This is the most important section for you as a tester. We want you to
file reports liberally — anything from "this confused me" to "LOCI
crashed" is useful.

### When something goes wrong with LOCI

1. **Run `/bug-report` inside Claude Code.** It writes a timestamped
   file like `report-2026-05-20-windows.md` in your current directory.
   The report includes:
   - your Claude Code, LOCI plugin, and OS versions;
   - project context (compiler, architecture, target);
   - a 13-point diagnostics checklist;
   - root-cause reasoning;
   - sanitized copies of the relevant config files, with secrets
     redacted in-memory before writing.

2. **File an issue** in the Aurora Labs Jira project at
   https://auroralabs.atlassian.net/browse/AAD. All testing-round
   feedback and bug reports go there, regardless of which skill
   misbehaved.

3. **Attach the report file** and briefly describe:
   - what you typed and what you expected,
   - what LOCI did instead.

That's the whole flow. The report has everything we need to reproduce
or diagnose; you don't need to chase down logs by hand.

### When this *testbed* itself has a problem

If the issue is with this repo — the build script broke, the README is
unclear, a project failed to compile — open an issue on GitHub at
https://github.com/auroralabs-loci/loci-claude-dev/issues instead. No
`/bug-report` needed for that; it's a LOCI diagnostic and won't tell
us much about a CMake error.

### Feedback that isn't a bug

Confusion is feedback. "I didn't know what this skill was for," "the
output overwhelmed me," "I wished it did X" — all of that is exactly
what we want to hear. File it the same way; you don't need a
`/bug-report` attached for non-bug feedback.

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `tiarmclang not found` from `./build.sh` | Install TI Arm Clang (see [Prerequisites](#prerequisites)), or set `TIARMCLANG_DIR=/path/to/ticlang` and re-run. |
| Submodules look empty | `./setup.sh` (or `git submodule update --init --recursive`). |
| `/help` doesn't show LOCI in Claude Code | Run `/plugin marketplace add auroralabs-loci/loci-claude-dev` and `/plugin install loci@loci`. Restart Claude Code. |
| First Claude Code session feels stuck for 30 seconds | That's the LOCI bootstrap building its venv. Let it finish — subsequent sessions are instant. |
| Skill says "no compile_commands.json" | Run `./build.sh` first, then restart Claude Code from the repo root. |
| `/memory-report` says no ELF | Confirm `.loci-build/demo/demo.elf` exists. If not, run `./build.sh --clean`. |
| MCP server "not authorized" | Type `/mcp` in Claude Code, approve the **loci** server. If it doesn't appear in the list, restart Claude Code. |
| `/exec-trace` hangs or errors with a network message | Confirm your network reaches `mcp.auroralabs.com` over HTTPS. Corporate VPNs sometimes block it. |
| Anything else | Run `/bug-report` and file the report — see [Filing a bug or feedback](#filing-a-bug-or-feedback). |

---

## Repo layout

```
loci-playground/
├── CMakeLists.txt                       # top-level — adds all subprojects
├── toolchain/
│   └── cortex-m4-tiarmclang.cmake       # cross-compile toolchain file
├── setup.sh                             # git submodule init
├── build.sh                             # configure + build everything
├── micro-ecc/   CMakeLists.txt + upstream/   (submodule)
├── littlefs/    CMakeLists.txt + upstream/
├── tinycrypt/   CMakeLists.txt + upstream/
├── printf/      CMakeLists.txt + upstream/
├── cjson/       CMakeLists.txt + upstream/
└── demo/        CMakeLists.txt + main.c    # → demo.elf for /memory-report
```

Build flags from `toolchain/cortex-m4-tiarmclang.cmake`:

```
-mcpu=cortex-m4 -mfpu=fpv4-sp-d16 -mfloat-abi=hard -mthumb
-ffunction-sections -fdata-sections
```

The toolchain forces `STATIC_LIBRARY` as the try-compile target type
so CMake never tries to link a Cortex-M4 executable on the host during
its compiler check.

---

## Maintainer notes

### Adding another project

1. `git submodule add <url> <name>/upstream`
2. Create `<name>/CMakeLists.txt` with a single `add_library(<name> STATIC ...)`.
3. Add `add_subdirectory(<name>)` to the top-level `CMakeLists.txt`.
4. *(Optional)* To represent the new library in `/memory-report`, add
   `extern` references to one or two of its symbols in `demo/main.c`
   and add the library to `demo/CMakeLists.txt`'s
   `target_link_libraries`.

### Updating an upstream pin

```bash
cd micro-ecc/upstream
git fetch && git checkout <new-sha-or-tag>
cd ../..
git add micro-ecc/upstream
git commit -m "bump micro-ecc to <ref>"
```

---

## One-liner

```bash
git clone --recurse-submodules https://github.com/vladimir-aurora/loci-playground.git \
  && cd loci-playground && ./build.sh
```

Then start Claude Code in the repo root, install the plugin if you
haven't already, and type `/help` to confirm LOCI is live. From there,
pick a skill from [Try every LOCI skill](#try-every-loci-skill) and
follow your curiosity.
