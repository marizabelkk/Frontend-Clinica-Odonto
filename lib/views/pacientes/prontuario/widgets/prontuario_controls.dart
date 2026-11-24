part of '../prontuario_view.dart';

class _PillButton extends StatelessWidget {
  const _PillButton({required this.dark, required this.label, required this.onPressed});
  final bool dark;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: _softFill(dark),
          foregroundColor: dark ? AppTheme.darkText : AppTheme.navy,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          minimumSize: const Size(0, 38),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        ),
        child: Text(label),
      );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.surface, required this.line, required this.title, required this.child, this.trailing});
  final Color surface;
  final Color line;
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        border: Border.all(color: line),
        borderRadius: BorderRadius.circular(18),
        boxShadow: dark ? null : [BoxShadow(color: const Color(0xFF102B53).withValues(alpha: .04), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: Text(title, style: TextStyle(color: _heading(dark), fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -.3))),
          if (trailing != null)
            TextButtonTheme(
              data: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: _link(dark), textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14))),
              child: trailing!,
            ),
        ]),
        const SizedBox(height: 10),
        child,
      ]),
    );
  }
}
