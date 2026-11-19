import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'botao_alternar_tema.dart';

/// Cabeçalho de navegação compartilhado pelas telas do fluxo do aluno.
class CabecalhoPaginaAluno extends StatelessWidget {
  const CabecalhoPaginaAluno({
    required this.title,
    required this.subtitle,
    this.actions = const [],
    super.key,
  });

  final String title;
  final String subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    final safeTop = MediaQuery.paddingOf(context).top;
    return SizedBox(
      height: (compact ? 148 : 174) + safeTop,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/brand_background.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          ColoredBox(
            color: const Color(0xFF05285A).withValues(
              alpha: Theme.of(context).brightness == Brightness.dark ? .76 : .68,
            ),
          ),
          Positioned(
            left: compact ? 8 : 20,
            right: 4,
            top: safeTop + (compact ? 28 : 34),
            child: Row(children: [
              IconButton(
                tooltip: 'Voltar',
                onPressed: () => Navigator.maybePop(context),
                color: Colors.white,
                icon: const Icon(Icons.arrow_back_rounded, size: 28),
              ),
              Expanded(child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 21 : 29,
                  fontWeight: FontWeight.w800,
                ),
              )),
              ...actions,
              const BotaoAlternarTema(color: Colors.white),
            ]),
          ),
          Positioned(
            left: compact ? 16 : 30,
            right: 14,
            bottom: compact ? 18 : 22,
            child: Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: .94),
                fontSize: compact ? 14 : 17,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Visual tokens for the light/dark student workflow pages.
abstract final class EstiloPaginaAluno {
  static Color accent(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? AppTheme.gold
      : Theme.of(context).colorScheme.primary;

  static Color background(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? AppTheme.darkBackground
      : const Color(0xFFF7F8FA);

  static ThemeData readableTheme(BuildContext context) {
    final base = Theme.of(context);
    final dark = base.brightness == Brightness.dark;
    return base.copyWith(
      colorScheme: dark
          ? base.colorScheme.copyWith(
              primary: AppTheme.gold,
              onPrimary: AppTheme.navy,
              secondary: AppTheme.gold,
              onSecondary: AppTheme.navy,
            )
          : base.colorScheme,
      textTheme: base.textTheme.apply(fontSizeFactor: 1.08),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: dark ? AppTheme.gold : AppTheme.navy,
          foregroundColor: dark ? AppTheme.navy : Colors.white,
          minimumSize: const Size(48, 48),
        ),
      ),
      cardTheme: base.cardTheme.copyWith(
        margin: const EdgeInsets.symmetric(vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
