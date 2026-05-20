# LOCI test projects — Cortex-M4 / armv7e-m

Five small, self-contained open-source projects, each cross-compiled for
**Cortex-M4F** with **TI Arm Clang** so LOCI skills (`/exec-trace`,
`/stack-depth`, `/memory-report`, `/control-flow`) have real artifacts to
analyze.

| Project   | Upstream                              | Files compiled | LOCI angle |
|-----------|---------------------------------------|----------------|------------|
| micro-ecc | github.com/kmackay/micro-ecc          | 1 .c           | One long crypto exec trace; thumb2 asm paths |
| littlefs  | github.com/littlefs-project/littlefs  | 2 .c           | Recursive directory walk → stack depth |
| tinycrypt | github.com/intel/tinycrypt            | 15 .c          | Many small algorithms side by side |
| printf    | github.com/eyalroz/printf             | 1 .c           | Huge switch — control-flow + format-cost |
| cJSON    | github.com/DaveGamble/cJSON           | 1 .c           | Recursive-descent parser → stack depth |

## Prerequisites

| Tool          | Version checked | Notes |
|---------------|-----------------|-------|
| TI Arm Clang  | 2.1.3 LTS       | Defaults: `C:\ti\ticlang` (Win), `/opt/ti/ticlang` (Linux). Override via `$TIARMCLANG_DIR`. macOS is unsupported by TI — see below. |
| CMake         | >= 3.16         | 4.x is fine. |
| Ninja         | any             | `choco install ninja` / `apt install ninja-build` / `brew install ninja`. |
| Git           | any             | With submodule support (every modern version). |
| Bash          | any             | Git Bash on Windows; native bash on Linux/macOS. |

No Cortex-M startup files, linker scripts, or libc are required — every
project builds to a static archive only. LOCI reads the object files.

**macOS note:** TI does not ship Arm Clang for macOS. If you're on a Mac,
either build inside a Linux VM/container, or set `TIARMCLANG_DIR` to a
locally-sourced install. The build scripts will exit with a clear error
otherwise.

## One-time setup

```bash
git clone --recurse-submodules git@github.com:vladimir-aurora/loci-test-projects.git
cd loci-test-projects
./build.sh
```

If you already cloned without `--recurse-submodules`, run `./setup.sh`
first to fetch the upstream submodules.

`./build.sh --clean` wipes the build directory first. Custom toolchain
location: `TIARMCLANG_DIR=/path/to/ticlang ./build.sh`.

## Layout

```
loci-test-projects/
├── .gitmodules                          # 5 upstream pins (HTTPS)
├── .gitattributes                       # forces LF on shell scripts
├── CMakeLists.txt                       # top-level, adds all 5 subdirs
├── toolchain/
│   └── cortex-m4-tiarmclang.cmake       # cross-platform toolchain file
├── setup.sh                             # `git submodule update --init`
├── build.sh                             # configure + build all 5
├── micro-ecc/
│   ├── CMakeLists.txt                   # wrapper — compiles uECC.c
│   └── upstream/                        # submodule
├── littlefs/  ...
├── tinycrypt/ ...
├── printf/    ...
└── cjson/     ...
```

Each `CMakeLists.txt` is intentionally tiny — all five wrappers can be
read end-to-end in under a minute.

## Build flags

From `toolchain/cortex-m4-tiarmclang.cmake`:

```
-mcpu=cortex-m4 -mfpu=fpv4-sp-d16 -mfloat-abi=hard -mthumb
-ffunction-sections -fdata-sections
```

`STATIC_LIBRARY` is forced as the try-compile target type so CMake never
tries to link a Cortex-M4 executable on the host.

## Suggested LOCI runs

Once `./build.sh` succeeds, the .o files live under `.loci-build/`. Ask
Claude things like:

- `/exec-trace uECC_sign`              — full ECDSA sign timing
- `/exec-trace tc_aes_encrypt`         — single AES block
- `/exec-trace tc_sha256_update`       — SHA-256 hot loop
- `/stack-depth cJSON_Parse`           — recursive parser worst case
- `/stack-depth lfs_dir_traverse`      — filesystem tree walk
- `/control-flow vsnprintf_`           — printf format dispatch
- `/memory-report`                     — ROM/RAM per project

## Adding another project

1. `git submodule add <url> <name>/upstream`
2. Create `<name>/CMakeLists.txt` with a single `add_library(<name> STATIC ...)`.
3. Add `add_subdirectory(<name>)` to the top-level `CMakeLists.txt`.

That's it — no other glue.

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
