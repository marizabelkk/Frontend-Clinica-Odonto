import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/viewmodels/theme_view_model.dart';

/// Botão claro/escuro reutilizado em todas as telas.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({this.color, super.key});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeViewModel>();
    return IconButton(
      key: const Key('theme-toggle'),
      tooltip: theme.isDark ? 'Modo claro' : 'Modo escuro',
      onPressed: theme.toggle,
      icon: Icon(
        theme.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
        color: color,
      ),
    );
  }
}
