![NX1 Reborn](res/nx1-reborn-jxnplays.png)

# NX1 Reborn

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows-lightgrey)]()
[![Status](https://img.shields.io/badge/status-active-brightgreen)]()

A static recompilation of **Call of Duty: Future Warfare** (NX1) into native Windows executables.

PowerPC code is translated ahead of time into C++ and compiled. Xenos shaders are converted to HLSL and run on a real GPU driver. This is a maintained fork of [NX1recomp](https://github.com/goshavindtburg/NX1recomp) with local work on netplay, a native D3D9 path, shader cache, and supporting tooling.

<div align="center">
  <img src="res/nx1-status.svg?v=5" width="900">
</div>

---

## Progress

| Area | Status | Notes |
| --- | --- | --- |
| Single-player (`nx1_sp`) | Bootable | ReXGlue graphics + developer overlay |
| Multiplayer (`nx1_mp`) | Bootable | Native D3D9 renderer |
| Netplay | Working | Client stutter fixed (v0.9) |
| Maps (`.ff`) | 15 loadable | Real bulk half present |
| Maps (`.ffm` only) | 12 invisible | Runtime has no `.ff` → `.ffm` fallback |
| Shader cache | Native | SM3 transform + `fxc` backend |
| Discord presence | Present | Requires Discord Social SDK |


---

## Current state

With a dump in `nx1/` and `thirdparty/` restored, this project builds and runs on Windows. The
exact sequence is below — it is what has been verified on a clean clone.

## Missing files

This repository does not contain the game or its build dependencies. You must supply:

| Path | What it is | Where to get it |
| --- | --- | --- |
| `nx1/` | Game dump (`.xex` + assets) | The Dec 18 2011 prototype dump (see below) |
| `generated/` | C++ from ReXGlue | Produced by running ReXGlue against your dump |
| `thirdparty/` | Vendored trees | `tools\setup-thirdparty.ps1` |

### Game dump

The dump is the **Dec 18 2011 prototype build** of Call of Duty: Future Warfare. Other or partial
dumps are missing bulk data for several maps, which is why some maps will not load.

Place the dump contents in `nx1/`. Either of these layouts works:

```
nx1\5-nx1mp_demo.xex              <- flat
nx1\NX1\5-nx1mp_demo.xex          <- one nested folder
```

The runtime auto-detects both and mounts whichever folder holds the `.xex` as the volume root.

---

## Building

### Prerequisites

- Windows
- **Clang 20.1.8 (MSVC ABI)** — `winget install LLVM.LLVM`. This is required, not optional: the SDK
  refuses to configure with MSVC (`rexglue-sdk/CMakeLists.txt` errors out on any non-Clang compiler).
- Visual Studio 2022 Build Tools (headers, Windows SDK, and the MSVC runtime Clang links against).
- CMake 3.25+ and Ninja (both ship with the VS Build Tools).
- A full NX1 dump in `nx1/`.

### Steps

**1. Clone.**

```
git clone https://github.com/jxnplays/NX1-Reborn.git
cd NX1-Reborn
```

**2. Place your dump in `nx1/`** (either layout shown above).

**3. Restore `thirdparty/`.**

This is **not** `git submodule update` — this repo has no top-level `.gitmodules`, and
`rexglue-sdk/` + `XenosRecomp/` are vendored copies without their own `.git` directories. Use the
script, which pulls the correct upstream trees and repairs Windows symlink checkouts:

```powershell
powershell -ExecutionPolicy Bypass -File tools\setup-thirdparty.ps1
```

It restores 27 submodules from upstream ReXGlue commit `e8ce24f` (the commit this fork's vendored
SDK was derived from), plus 11 vendored directories that appear in no `.gitmodules` at all
(`disasm`, `dxbc`, `renderdoc`, and others), and fixes 15 symlinks that git otherwise checks out as
one-line text stubs. Expect it to take a few minutes and a few GB.

**4. Build ReXGlue** (the code generator):

```
cd rexglue-sdk
cmake --preset win-amd64
cmake --build --preset win-amd64-release --target rexglue
cd ..
```

> Note the preset names: `win-amd64` to configure, `win-amd64-release` to build.

**5. Generate `generated/`** from your dump:

```
cd nx1_mp
..\rexglue-sdk\out\win-amd64\Release\rexglue.exe -f codegen nx1_mp_manifest.toml
```

This takes a few minutes and emits ~84 MB of C++. It writes
`nx1_mp\generated\5-nx1mp_demo\`, which step 6 compiles.

**6. Build the multiplayer target.**

`REXSDK_DIR` is required — it is a CMake cache variable, and setting it as an environment variable
is silently ignored.

```
cd nx1_mp
cmake --preset win-amd64-release -DREXSDK_DIR="<absolute path to your clone>/rexglue-sdk"
cmake --build --preset win-amd64-release --target nx1_mp
```

The executable lands at `nx1_mp\out\build\win-amd64-release\nx1_mp.exe`.

The single-player target (`nx1_sp`) follows the same pattern.

### Running

Launch straight into a map:

```powershell
.\tools\Start-Nx1MpDevmap.ps1 -Map mp_nx_deadzone -NoOcclusionQuery
```

Use that script rather than passing `--cl` yourself: a multi-word command line passed via
`Start-Process -ArgumentList` gets split on spaces and silently truncated, so `+devmap` never
reaches the guest and the game quietly loads the default map instead.

Maps with a real `.ff` bulk half load (15 of them, e.g. `mp_nx_deadzone`). Maps that exist only as
`.ffm` are not visible to the runtime.

If you run several emulators on one machine, set `systemlink_port_offset` in the generated
`nx1_mp.toml` (e.g. `30000`). The default System Link UDP port 1000 is often already taken, and the
guest shuts down shortly after boot if the bind fails.

Discord rich presence is optional and requires the Discord Social SDK in a `Discord SDK/` folder at
the repo root. Without it the build still succeeds and the feature is simply disabled.

---

## Layout

```
nx1_sp/           Single-player target
nx1_mp/           Multiplayer target (native D3D9 renderer)
rexglue-sdk/      ReXGlue SDK — vendored with NX1-specific changes
XenosRecomp/      Xenos shader → HLSL recompiler — vendored with NX1-specific changes
tools/            Dev scripts
res/              Icon and logo
```

`rexglue-sdk` and `XenosRecomp` are modified forks. Local work includes the netplay stack, native shader cache, Discord presence, debug HUD, and mouse-look on the SDK side; and the Shader Model 3 transform plus an `fxc` compiler backend on the XenosRecomp side.

---

## Contributing

Issues and pull requests are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for scope and constraints.

- Runtime fixes, netplay improvements, and renderer work are in scope.
- Do not commit game code, assets, or generated C++.
- Include the target, dump version, and logs when reporting issues.

---

## Credits

Built on the work of others:

- **ReXGlue** — recompiler and runtime SDK
- **XenosRecomp** (hedge-dev) — Xenos shader recompilation
- **Xenia** — foundation for the above

Their respective licenses apply to the vendored copies.

---

## Legal Disclaimer

This repository contains **only** the recompilation harness, runtime glue, and local modifications. It does **not** contain any game code, assets, textures, models, sound, or other copyrighted material from Call of Duty: Future Warfare or any other title.

You must legally obtain your own dump of the original game. This project is not affiliated with, endorsed by, or sponsored by Activision, Neversoft, or any rights holder. All trademarks and copyrights remain the property of their respective owners.

Use of this software is at your own risk. The authors provide no warranty and accept no liability for any damages, legal consequences, or other issues arising from its use.

---

## License

The recompilation harness and local modifications in this repository are licensed under the [MIT License](LICENSE).

Vendored third-party components (ReXGlue, XenosRecomp, and their dependencies) retain their original licenses. See the respective directories for details.

Game code and assets are **not** included and are not licensed by this project.

See also: [Code of Conduct](CODE_OF_CONDUCT.md) · [Security Policy](SECURITY.md)
