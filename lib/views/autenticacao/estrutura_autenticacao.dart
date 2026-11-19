import 'dart:ui';

import 'package:flutter/material.dart';

import '../../widgets/botao_alternar_tema.dart';

/// Moldura visual das telas de login e recuperação de senha
/// (fundo com arcos azuis + cartão translúcido), inspirada em `docs/telas/Login_referencia.jpg`.
/// Funciona nos modos escuro (como a referência) e claro.
class EstruturaAutenticacao extends StatelessWidget {
  const EstruturaAutenticacao({
    required this.child,
    this.showBack = false,
    this.adaptLoginCard = false,
    super.key,
  });

  final Widget child;
  final bool showBack;
  final bool adaptLoginCard;

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  /// Botão principal em formato de pílula (branco no escuro, azul no claro).
  static ButtonStyle buttonStyle(BuildContext context) {
    final dark = isDark(context);
    return ElevatedButton.styleFrom(
      backgroundColor: dark
          ? Colors.white
          : Theme.of(context).colorScheme.primary,
      foregroundColor: dark ? Colors.black87 : Colors.white,
      minimumSize: const Size.fromHeight(48),
      shape: const StadiumBorder(),
      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
    );
  }

  /// Campo em formato de pílula, como na referência.
  static InputDecoration decoration(
    BuildContext context, {
    required String label,
    String? hint,
    IconData? icon,
    Widget? suffix,
  }) {
    final dark = isDark(context);
    final side = BorderSide(
      color: dark ? Colors.white30 : const Color(0xFFB8C4E8),
    );
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: side,
    );
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon),
      suffixIcon: suffix,
      filled: true,
      fillColor: dark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(
          color: dark
              ? const Color(0xFF3D9BFF)
              : Theme.of(context).colorScheme.primary,
          width: 1.6,
        ),
      ),
    );
  }

  /// Identidade da clínica, usada no topo de cada cartão.
  static Widget brand(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        Image.asset(
          'assets/images/uninassau_odontologia_logo.png',
          width: 88,
          height: 88,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 8),
        Text(
          'Clínica Odonto',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    final iconColor = dark ? Colors.white : null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 64, 20, 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: _GlassCard(
                    dark: dark,
                    child: adaptLoginCard
                        ? Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: Theme.of(context).colorScheme
                                  .copyWith(
                                    onSurface: dark
                                        ? const Color(0xFFF4F7FC)
                                        : const Color(0xFF102B53),
                                  ),
                              textTheme: Theme.of(context).textTheme.apply(
                                bodyColor: dark
                                    ? const Color(0xFFF4F7FC)
                                    : const Color(0xFF102B53),
                                displayColor: dark
                                    ? const Color(0xFFF4F7FC)
                                    : const Color(0xFF102B53),
                              ),
                            ),
                            child: child,
                          )
                        : child,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 8,
              child: BotaoAlternarTema(color: iconColor),
            ),
            if (showBack)
              Positioned(top: 4, left: 8, child: BackButton(color: iconColor)),
          ],
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.dark, required this.child});

  final bool dark;
  final Widget child;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: dark
              ? const Color(0xFF0A1050).withValues(alpha: 0.55)
              : Colors.white.withValues(alpha: 0.9),
          border: Border.all(
            color: dark ? Colors.white24 : const Color(0xFFC9D6F5),
          ),
        ),
        child: child,
      ),
    ),
  );
}
