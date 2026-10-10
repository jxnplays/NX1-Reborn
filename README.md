![NX1 Reborn](res/nx1-reborn-logo.png)

# NX1 Reborn

A static recompilation of **Call of Duty: Future Warfare** (NX1) into native Windows executables.

PowerPC code is translated ahead of time into C++ and compiled. Xenos shaders are converted to HLSL and run on a real GPU driver. This is a maintained fork of [NX1recomp](https://github.com/goshavindtburg/NX1recomp) with local work on netplay, a native D3D9 path, shader cache, and supporting tooling.

| Target | Backend | Status |
| --- | --- | --- |
| `nx1_sp` | ReXGlue graphics + developer overlay | Bootable |
| `nx1_mp` | Native D3D9 + working netplay | Bootable |

---

## Required game files

The recomp requires the **Internet Archive v1.1.1.14** build of Call of Duty: Future Warfare.

Earlier or incomplete dumps are missing bulk data for several maps. Place the files from that build in the `nx1/` folder before building or running. This repository does not contain game code or assets.

---

## What this is

NX1 Reborn takes the cancelled 2011 Neversoft prototype and produces native Windows binaries. The recompilation harness, runtime, and local modifications live here. The game itself does not.

- **`nx1/`** — your game dump (`.xex` + assets). Not in the repo.
- **`generated/`** — C++ emitted by ReXGlue from the PowerPC code. Not in the repo.
- **`thirdparty/`** — vendored trees. Gitignored; restore from upstream commit `e8ce24f` before building.

---

## Current status

Maps that exist as `.ff` (not `.ffm`) can load without crashing. 15 maps have a real `.ff` bulk half and are loadable. 12 maps exist only as `.ffm` and are currently invisible to the runtime, which has no `.ff` → `.ffm` fallback.

The multiplayer target uses a native D3D9 renderer and has working netplay. The single-player target uses the ReXGlue graphics backend with a developer overlay.

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
nx1_mp/           Multiplayer target (native D3D9 renderer)
rexglue-sdk/      ReXGlue SDK — vendored with NX1-specific changes
XenosRecomp/      Xenos shader → HLSL recompiler — vendored with NX1-specific changes
tools/            Dev scripts
res/              Icon and logo
```

`rexglue-sdk` and `XenosRecomp` are modified forks. Local work includes the netplay stack, native shader cache, Discord presence, debug HUD, and mouse-look on the SDK side; and the Shader Model 3 transform plus an `fxc` compiler backend on the XenosRecomp side.

---

## Credits

Built on the work of others:

- **ReXGlue** — recompiler and runtime SDK
- **XenosRecomp** (hedge-dev) — Xenos shader recompilation
- **Xenia** — foundation for the above

Their respective licenses apply to the vendored copies.

---

## License

This repository contains only the recompilation harness and local modifications. Game code and assets are not included. See the licenses of the vendored projects for their terms.
