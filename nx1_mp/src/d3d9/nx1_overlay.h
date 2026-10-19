#pragma once

#ifdef _WIN32

#include <cstdint>

struct HWND__;
using HWND = HWND__*;
struct IDirect3DDevice9Ex;

namespace nx1::d3d9 {

/// F11 settings overlay drawn over the native D3D9 window.
/// Modelled after the COD3 Reborn F11 menu.
namespace Overlay {

/// Call once after the D3D9 device and window exist.
void Initialize(HWND hwnd, IDirect3DDevice9Ex* device);

/// Call from Present, after the frame is in the back buffer and before PresentEx.
void Render(int width, int height);

/// Call from the window procedure. Returns true if the message was consumed.
bool HandleMessage(HWND hwnd, uint32_t msg, uint64_t wparam, int64_t lparam);

/// True while the menu is open (input should go to ImGui, not the game).
bool IsOpen();

/// Toggle the menu (also bound to F11).
void Toggle();

}  // namespace Overlay

}  // namespace nx1::d3d9

#endif  // _WIN32
