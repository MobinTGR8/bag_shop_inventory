import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThemeNotifier extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;
  void setMode(ThemeMode m) {
    _mode = m;
    notifyListeners();
  }
}

final themeProvider = ChangeNotifierProvider((ref) => ThemeNotifier());
