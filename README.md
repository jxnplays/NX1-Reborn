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

A user with an extracted ISO can build and run this project. The required steps are:

1. Place the dump contents in `nx1/`.
2. Initialize the `thirdparty/` submodules from the committed `.gitmodules` files in `rexglue-sdk/` and `XenosRecomp/`.
3. Run ReXGlue against the dump to produce `generated/`.
4. Configure and build with CMake.

## Missing files

This repository does not contain the game or its build dependencies. You must supply:

| Path | What it is | Where to get it |
| --- | --- | --- |
| `nx1/` | Game dump (`.xex` + assets) | Internet Archive v1.1.1.14 build |
| `generated/` | C++ from ReXGlue | Run ReXGlue against your dump |
| `thirdparty/` | Vendored trees | Restore via `git submodule update --init --recursive` |
| Discord SDK | Rich presence | Discord Social SDK |

Earlier or incomplete dumps are missing bulk data for several maps. Place the files from the v1.1.1.14 build in `nx1/` before building or running.

---

## Building

This is not a one-command build. You need three things before CMake will succeed:

1. **Game dump** in `nx1/` (your extracted ISO or the Internet Archive v1.1.1.14 files).
2. **Generated C++** in `generated/` (produced by running ReXGlue against the dump).
3. **Vendored third-party trees** in `thirdparty/` (gitignored; restore via `git submodule update --init --recursive` from the committed `.gitmodules`).

### Prerequisites

- Windows
- CMake 3.25+
- Clang 20.1.8 (MSVC ABI) — the project is configured for this toolchain
- A full NX1 dump (`.xex` + asset files)

### Steps

1. Clone the repo and enter it:
   ```
   git clone https://github.com/jxnplays/NX1-Reborn.git
   cd NX1-Reborn
   ```

2. Place your dump in `nx1/`. The expected layout is the raw dump contents (not a nested folder).

3. Initialize thirdparty submodules. The URLs and commits are recorded in the committed `.gitmodules` files:
   ```
   git submodule update --init --recursive
   ```
   If needed, initialize from the vendored projects:
   ```
   cd rexglue-sdk && git submodule update --init --recursive && cd ..
   cd XenosRecomp && git submodule update --init --recursive && cd ..
   ```

4. Run ReXGlue against your dump to produce `generated/`. The SDK is vendored under `rexglue-sdk/`. Follow the ReXGlue documentation for generating the C++ from your `.xex`.

5. Configure and build the multiplayer target:
   ```
   cmake -S nx1_mp -B out/build/win-amd64-release -G Ninja -DCMAKE_BUILD_TYPE=Release
   cmake --build out/build/win-amd64-release
   ```

The single-player target (`nx1_sp`) follows the same pattern.

Builds land in `out/build/win-amd64-release/`. Discord rich presence is optional and requires the Discord Social SDK in a `Discord SDK/` folder at the repo root.

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
