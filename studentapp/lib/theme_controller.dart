import 'package:flutter/material.dart';

class ThemeController {
  ThemeController._();

  static final ThemeController instance = ThemeController._();

  final ValueNotifier<bool> isDarkMode = ValueNotifier<bool>(false);

  void setDarkMode(bool value) {
    isDarkMode.value = value;
  }

  void toggle() {
    isDarkMode.value = !isDarkMode.value;
  }

  void dispose() {
    isDarkMode.dispose();
  }
}
