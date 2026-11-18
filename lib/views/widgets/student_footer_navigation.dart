import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Returns to the authenticated landing route, regardless of which student
/// page opened the current screen.
void navigateToStudentHome(BuildContext context) {
  Navigator.of(context).popUntil((route) => route.isFirst);
}

/// Navegação fixa reutilizável nas telas do aluno.
class StudentFooterNavigation extends StatelessWidget {
  const StudentFooterNavigation({
    required this.currentIndex,
    required this.onDestinationSelected,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final active = dark ? AppTheme.gold : AppTheme.navy;
    final inactive = dark ? const Color(0xFF99AACA) : const Color(0xFF48607F);
    const items = [
      (Icons.home_outlined, 'Início'),
      (Icons.people_outline, 'Pacientes'),
      (Icons.assignment_outlined, 'Atendimentos'),
      (Icons.person_outline, 'Perfil'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF091629) : Colors.white,
        border: Border(
          top: BorderSide(
            color: dark ? const Color(0xFF21334B) : const Color(0xFFE6E9EE),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: InkWell(
                    onTap: () => onDestinationSelected(i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(items[i].$1, color: i == currentIndex ? active : inactive, size: 25),
                        const SizedBox(height: 3),
                        Text(items[i].$2, style: TextStyle(color: i == currentIndex ? active : inactive, fontSize: 11, fontWeight: i == currentIndex ? FontWeight.bold : FontWeight.normal)),
                        if (i == currentIndex)
                          Container(margin: const EdgeInsets.only(top: 4), height: 3, width: 78, decoration: BoxDecoration(color: active, borderRadius: BorderRadius.circular(3))),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
