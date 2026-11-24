import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class NavegacaoInferiorCoordenacao extends StatelessWidget {
  const NavegacaoInferiorCoordenacao({
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
      (Icons.manage_accounts_outlined, 'Usuários'),
      (Icons.logout_outlined, 'Sair'),
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
                        Icon(
                          items[i].$1,
                          color: i == currentIndex ? active : inactive,
                          size: 24,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          items[i].$2,
                          style: TextStyle(
                            color: i == currentIndex ? active : inactive,
                            fontSize: 12,
                            fontWeight: i == currentIndex
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        if (i == currentIndex)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            height: 3,
                            width: 70,
                            decoration: BoxDecoration(
                              color: active,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
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
