# NX1 Reborn

A static recompilation of **Call of Duty: Future Warfare** (NX1) into native Windows executables. PowerPC code is translated ahead of time into C++ and compiled; Xenos shaders are converted to HLSL and run on a real GPU driver. This is a maintained fork of [NX1recomp](https://github.com/goshavindtburg/NX1recomp).

Two targets:

| Target | Description |
| --- | --- |
| `nx1_sp` | Single-player. ReXGlue graphics backend with a developer overlay. |
| `nx1_mp` | Multiplayer. Native D3D9 renderer with working netplay. |

---

## Required game files

The recomp requires the **Internet Archive v1.1.1.14** build of Call of Duty: Future Warfare.

Earlier or incomplete dumps are missing bulk data for several maps. Place the files from that build in the `nx1/` folder before building or running.

---

## No game code or assets are in this repository

This repo contains only the recompilation harness: build configs, runtime code, and tooling. Game files and generated C++ are excluded.

- `nx1/` — game files (`.xex`, assets). You must supply your own copy.
- `generated/` — C++ emitted by ReXGlue from the game's PowerPC code.
- Shader dumps and baked caches under `tools/`.

---

## Current status

Maps that exist as `.ff` (not `.ffm`) can load without crashing. 15 maps have a real `.ff` bulk half and are loadable. 12 maps exist only as `.ffm` and are currently invisible to the runtime, which has no `.ff` → `.ffm` fallback.

The multiplayer target uses a native D3D9 renderer and has working netplay. The single-player target uses the ReXGlue graphics backend.

---

## Building

Requires CMake and Clang 20.1.8 (MSVC ABI). Each target is a standalone CMake project. Builds land in `out/build/win-amd64-release/`.

**Restore `thirdparty/` before building.** Those trees are gitignored. They are not fully recoverable from the committed `.gitmodules` — 11 non-submodule vendored trees plus the aggregator `CMakeLists.txt` must be obtained from upstream commit `e8ce24f`.

You also need a game dump in `nx1/` and must run ReXGlue to produce `generated/`.

Discord Social SDK is required for rich presence.

---

## Layout

```
nx1_sp/           Single-player target
nx1_mp/           Multiplayer target (includes native D3D9 renderer)
rexglue-sdk/      ReXGlue SDK — vendored with NX1-specific changes
XenosRecomp/      Xenos shader → HLSL recompiler — vendored with NX1-specific changes
tools/            Dev scripts
res/              Icon
```

`rexglue-sdk` and `XenosRecomp` are modified forks. Local work includes the netplay stack, native shader cache, Discord presence, debug HUD, and mouse-look on the SDK side; and the Shader Model 3 transform plus an `fxc` compiler backend on the XenosRecomp side.

---

## Credits

Built on the work of others:

- **ReXGlue** — recompiler and runtime SDK
- **XenosRecomp** (hedge-dev) — Xenos shader recompilation
- **Xenia** — foundation for the above

Their respective licenses apply to the vendored copies.