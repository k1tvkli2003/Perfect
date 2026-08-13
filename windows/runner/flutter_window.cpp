#include "flutter_window.h"

#include <flutter/standard_method_codec.h>
#include <optional>
#include <variant>

#include "flutter/generated_plugin_registrant.h"

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  appearance_channel_ = std::make_unique<
      flutter::MethodChannel<flutter::EncodableValue>>(
      flutter_controller_->engine()->messenger(),
      "com.k1tvkli2003.perfect/system_appearance",
      &flutter::StandardMethodCodec::GetInstance());
  appearance_channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
                 result) {
        if (call.method_name() != "apply" || call.arguments() == nullptr) {
          result->NotImplemented();
          return;
        }
        const auto* arguments =
            std::get_if<flutter::EncodableMap>(call.arguments());
        if (arguments == nullptr) {
          result->Error("invalid_arguments", "Appearance payload is not a map.");
          return;
        }
        const auto read_bool = [arguments](const char* key, bool fallback) {
          const auto entry = arguments->find(flutter::EncodableValue(key));
          if (entry == arguments->end()) return fallback;
          const auto* value = std::get_if<bool>(&entry->second);
          return value == nullptr ? fallback : *value;
        };
        const auto read_argb = [arguments](const char* key, DWORD fallback) {
          const auto entry = arguments->find(flutter::EncodableValue(key));
          if (entry == arguments->end()) return fallback;
          if (const auto* value = std::get_if<int32_t>(&entry->second)) {
            return static_cast<DWORD>(*value);
          }
          if (const auto* value = std::get_if<int64_t>(&entry->second)) {
            return static_cast<DWORD>(*value);
          }
          return fallback;
        };
        ApplyAppTheme(read_bool("dark", false),
                      read_bool("highContrast", false),
                      read_argb("canvasArgb", 0xff141620),
                      read_argb("inkArgb", 0xfff9f7ff),
                      read_argb("outlineArgb", 0xff5a5f72));
        result->Success();
      });
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  appearance_channel_.reset();
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
