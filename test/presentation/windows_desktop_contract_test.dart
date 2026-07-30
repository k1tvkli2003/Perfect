import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Windows host restores placement and enforces a usable minimum', () {
    final main = File('windows/runner/main.cpp').readAsStringSync();
    final header = File('windows/runner/win32_window.h').readAsStringSync();
    final implementation = File(
      'windows/runner/win32_window.cpp',
    ).readAsStringSync();

    expect(main, contains('ReadSavedPlacement'));
    expect(main, contains('SetInitialMaximized'));
    expect(main, contains('L"Perfect!"'));
    expect(header, contains('SetInitialMaximized'));
    expect(implementation, contains('WM_GETMINMAXINFO'));
    expect(implementation, contains('kMinimumWindowWidth = 760'));
    expect(implementation, contains('kMinimumWindowHeight = 560'));
    expect(implementation, contains('SavePlacement(hwnd)'));
    expect(implementation, contains('MONITOR_DEFAULTTONULL'));
    expect(implementation, contains('origin.x - static_cast<int>(work.left)'));
    expect(implementation, contains('(saved.left - work.left) / scale_factor'));
  });
}
