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
| cJSON     | github.com/DaveGamble/cJSON           | 1 .c           | Recursive-descent parser → stack depth |

> CMSIS-DSP was on the original shortlist but swapped for cJSON. Reasons:
> CMSIS-DSP clones at ~200 MB, depends on CMSIS_5 core headers, and its
> CMake expects specific include layouts — none of that is "seamless for
> colleagues." Add it back later if you want the SIMD32 demo.

## Prerequisites

| Tool          | Version checked | Notes |
|---------------|-----------------|-------|
| TI Arm Clang  | 2.1.3 LTS       | Expected at `C:\ti\ticlang`. Override with `$env:TIARMCLANG_DIR`. |
| CMake         | >= 3.16         | 4.x is fine. |
| Ninja         | any             | Bundled with most IDEs / `choco install ninja`. |
| Git           | any             | For `setup.ps1`. |
| PowerShell    | 7+ preferred    | Scripts use `pwsh`. |

No Cortex-M startup files, linker scripts, or libc are required — every
project builds to a static archive only. LOCI reads the object files.

## One-time setup (per machine)

```powershell
cd C:\Playground\loci-test-projects
pwsh -File setup.ps1     # clones the five upstream repos shallow
pwsh -File build.ps1     # configures + builds all five
```

Re-running either script is idempotent. `build.ps1 -Clean` wipes the
build directory first.

## Layout

```
loci-test-projects/
├── CMakeLists.txt                       # top-level, adds all 5 subdirs
├── toolchain/
│   └── cortex-m4-tiarmclang.cmake       # the only toolchain file
├── setup.ps1                            # clones upstreams
├── build.ps1                            # cmake configure + build
├── micro-ecc/
│   ├── CMakeLists.txt                   # wrapper — compiles uECC.c
│   └── upstream/                        # git clone
├── littlefs/  ...
├── tinycrypt/ ...
├── printf/    ...
└── cjson/     ...
```

Each `CMakeLists.txt` is intentionally tiny — colleagues should be able
to read all 5 wrappers in under a minute.

## Build flags

From `toolchain/cortex-m4-tiarmclang.cmake`:

```
-mcpu=cortex-m4 -mfpu=fpv4-sp-d16 -mfloat-abi=hard -mthumb
-ffunction-sections -fdata-sections
```

`STATIC_LIBRARY` is forced as the try-compile target type so CMake never
tries to link a Cortex-M4 executable on the host.

## Suggested LOCI runs

Once `build.ps1` succeeds, the .o files live under `.loci-build/`. Ask
Claude things like:

- `/exec-trace uECC_sign`              — full ECDSA sign timing
- `/exec-trace tc_aes_encrypt`         — single AES block
- `/exec-trace tc_sha256_update`       — SHA-256 hot loop
- `/stack-depth cJSON_Parse`           — recursive parser worst case
- `/stack-depth lfs_dir_traverse`      — filesystem tree walk
- `/control-flow vsnprintf_`           — printf format dispatch
- `/memory-report`                     — ROM/RAM per project

## Adding another project

1. Append the clone to the `$repos` list in `setup.ps1`.
2. Create `<name>/CMakeLists.txt` with a single `add_library(<name> STATIC ...)`.
3. Add `add_subdirectory(<name>)` to the top-level `CMakeLists.txt`.

That's it — no other glue.

## Rolling out to a colleague

```powershell
git clone <this-repo> C:\Playground\loci-test-projects
cd C:\Playground\loci-test-projects
pwsh -File setup.ps1
pwsh -File build.ps1
```

Prerequisite installs (Ninja + TI Arm Clang) are the only manual steps;
everything else is scripted.
