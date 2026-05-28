import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Controla el modo de tema de la aplicación.
/// Expuesto como [StateProvider] para que [main.dart] lo observe.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);
