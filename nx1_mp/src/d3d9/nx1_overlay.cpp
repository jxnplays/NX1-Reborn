#include "nx1_overlay.h"

#ifdef _WIN32

#include <atomic>
#include <mutex>

#include <Windows.h>
#include <d3d9.h>

#include <imgui.h>
#include <backends/imgui_impl_dx9.h>
#include <backends/imgui_impl_win32.h>

extern IMGUI_IMPL_API LRESULT ImGui_ImplWin32_WndProcHandler(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam);

namespace nx1::d3d9 {
namespace Overlay {

namespace {

std::mutex g_mutex;
std::atomic<bool> g_open{false};
std::atomic<bool> g_ready{false};

HWND g_hwnd = nullptr;
IDirect3DDevice9Ex* g_device = nullptr;

bool g_vsync = false;
bool g_show_fps = true;
int g_fov = 65;

void DrawMenu(int width, int height) {
  ImGui::SetNextWindowSize(ImVec2(520.0f, 0.0f), ImGuiCond_FirstUseEver);
  ImGui::SetNextWindowPos(ImVec2(width * 0.5f, height * 0.5f), ImGuiCond_FirstUseEver, ImVec2(0.5f, 0.5f));

  bool open = true;
  if (!ImGui::Begin("NX1 Settings (F11)", &open, ImGuiWindowFlags_NoCollapse)) {
    ImGui::End();
    if (!open) g_open.store(false);
    return;
  }

  if (ImGui::BeginTabBar("nx1_tabs")) {
    if (ImGui::BeginTabItem("Graphics")) {
      ImGui::TextDisabled("Renderer: Native D3D9");
      ImGui::Separator();

      ImGui::Checkbox("Show FPS", &g_show_fps);
      ImGui::Checkbox("VSync (host)", &g_vsync);
      ImGui::TextDisabled("VSync requires a restart of the D3D9 device to take effect.");

      ImGui::SliderInt("Field of view (placeholder)", &g_fov, 65, 120);
      ImGui::TextDisabled("FOV is not yet wired to the guest. This control is a placeholder.");

      ImGui::EndTabItem();
    }

    if (ImGui::BeginTabItem("Controls")) {
      ImGui::TextUnformatted("Mouse look and raw input are controlled by the ReXGlue host.");
      ImGui::TextDisabled("Additional host-side control options can be added here.");
      ImGui::EndTabItem();
    }

    if (ImGui::BeginTabItem("Mods")) {
      ImGui::TextDisabled("No guest cvars are exposed yet.");
      ImGui::TextUnformatted("This tab will list accessible NX1 console variables once they can be read and written from the host.");
      ImGui::EndTabItem();
    }

    ImGui::EndTabBar();
  }

  ImGui::Separator();
  ImGui::TextDisabled("Press F11 or Esc to close.");

  ImGui::End();

  if (!open) {
    g_open.store(false);
  }
}

}  // namespace

void Initialize(HWND hwnd, IDirect3DDevice9Ex* device) {
  if (g_ready.load()) return;

  g_hwnd = hwnd;
  g_device = device;

  IMGUI_CHECKVERSION();
  ImGui::CreateContext();
  ImGuiIO& io = ImGui::GetIO();
  io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;

  ImGui::StyleColorsDark();

  ImGui_ImplWin32_Init(hwnd);
  ImGui_ImplDX9_Init(device);

  g_ready.store(true);
}

void Render(int width, int height) {
  if (!g_ready.load() || !g_device) return;

  std::lock_guard lock(g_mutex);

  ImGui_ImplDX9_NewFrame();
  ImGui_ImplWin32_NewFrame();
  ImGui::NewFrame();

  if (g_open.load()) {
    DrawMenu(width, height);
  } else if (g_show_fps) {
    // Lightweight FPS counter when the menu is closed.
    ImGui::SetNextWindowPos(ImVec2(10.0f, 10.0f), ImGuiCond_Always);
    ImGui::SetNextWindowBgAlpha(0.4f);
    if (ImGui::Begin("fps", nullptr,
                     ImGuiWindowFlags_NoDecoration | ImGuiWindowFlags_NoMove |
                         ImGuiWindowFlags_AlwaysAutoResize | ImGuiWindowFlags_NoSavedSettings |
                         ImGuiWindowFlags_NoFocusOnAppearing | ImGuiWindowFlags_NoNav)) {
      ImGui::Text("%.1f FPS", ImGui::GetIO().Framerate);
    }
    ImGui::End();
  }

  ImGui::EndFrame();
  ImGui::Render();
  ImGui_ImplDX9_RenderDrawData(ImGui::GetDrawData());
}

bool HandleMessage(HWND hwnd, uint32_t msg, uint64_t wparam, int64_t lparam) {
  if (!g_ready.load()) return false;

  // F11 toggles the menu.
  if (msg == WM_KEYDOWN && wparam == VK_F11) {
    Toggle();
    return true;
  }

  // Escape closes the menu if it is open.
  if (msg == WM_KEYDOWN && wparam == VK_ESCAPE && g_open.load()) {
    g_open.store(false);
    return true;
  }

  if (g_open.load()) {
    return ImGui_ImplWin32_WndProcHandler(hwnd, msg, wparam, lparam) != 0;
  }

  return false;
}

bool IsOpen() { return g_open.load(); }

void Toggle() { g_open.store(!g_open.load()); }

}  // namespace Overlay
}  // namespace nx1::d3d9

#endif  // _WIN32
