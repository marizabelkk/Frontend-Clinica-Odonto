import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/usuario_model.dart';

/// Barra de navegação fixa e reutilizável na área do professor.
class MenuLateralProfessor extends StatelessWidget {
  const MenuLateralProfessor({
    required this.usuario,
    required this.selecionado,
    required this.recolhido,
    required this.onSelecionar,
    required this.onAlternar,
    required this.onSair,
    super.key,
  });

  final UsuarioModel usuario;
  final String selecionado;
  final bool recolhido;
  final ValueChanged<String> onSelecionar;
  final VoidCallback onAlternar;
  final VoidCallback onSair;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final foreground = Theme.of(context).colorScheme.onSurface;
    final muted = dark ? const Color(0xFFB9C7DD) : const Color(0xFF52647E);
    final line = dark ? const Color(0xFF263A56) : const Color(0xFFE1E5EB);
    final width = recolhido ? 72.0 : 228.0;
    final items = <(IconData, String)>[
      (Icons.home_outlined, 'Início'),
      (Icons.assignment_outlined, 'Pendências'),
      (Icons.check_circle_outline, 'Aprovadas'),
      (Icons.reply_outlined, 'Devolvidas'),
      (Icons.people_outline, 'Pacientes'),
      (Icons.folder_open_outlined, 'Prontuários'),
      (Icons.assignment_turned_in_outlined, 'Atendimentos'),
      (Icons.biotech_outlined, 'Exames'),
      (Icons.bar_chart_outlined, 'Relatórios'),
      (Icons.manage_accounts_outlined, 'Usuários'),
      (Icons.settings_outlined, 'Configurações'),
    ];

    // The child switches between compact icons and ListTiles. Changing width
    // immediately keeps each child under constraints it can actually render;
    // animating here briefly lays out expanded ListTiles at only 72 px.
    return SizedBox(
      width: width,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(right: BorderSide(color: line)),
        ),
        child: SafeArea(
          child: Column(children: [
          SizedBox(
            height: 138,
            width: double.infinity,
            child: Stack(fit: StackFit.expand, children: [
              Image.asset('assets/images/brand_background.png', fit: BoxFit.cover),
              ColoredBox(color: (dark ? const Color(0xFF06152A) : AppTheme.navy).withValues(alpha: .76)),
              if (!recolhido)
                const Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.health_and_safety_outlined, color: Colors.white, size: 38),
                  SizedBox(height: 4),
                  Text('Clínica Odonto', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                  Text('Prontuário Digital', style: TextStyle(color: Colors.white, fontSize: 12)),
                ])
              else
                const Center(child: Icon(Icons.health_and_safety_outlined, color: Colors.white, size: 38)),
            ]),
          ),
          Align(
            alignment: recolhido ? Alignment.center : Alignment.centerRight,
            child: IconButton(
              tooltip: recolhido ? 'Expandir menu' : 'Recolher menu',
              onPressed: onAlternar,
              icon: Icon(recolhido ? Icons.chevron_right : Icons.chevron_left),
            ),
          ),
          Expanded(child: ListView(padding: const EdgeInsets.symmetric(vertical: 4), children: [
            for (final item in items)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                child: recolhido
                    ? SizedBox(
                        height: 48,
                        child: Tooltip(
                          message: item.$2,
                          child: Material(
                            color: selecionado == item.$2
                                ? (dark ? const Color(0xFF1B2A41) : const Color(0xFFEAF0F9))
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            child: InkWell(
                              onTap: () => onSelecionar(item.$2),
                              borderRadius: BorderRadius.circular(10),
                              child: Center(
                                child: Icon(
                                  item.$1,
                                  color: selecionado == item.$2
                                      ? (dark ? AppTheme.gold : AppTheme.navy)
                                      : muted,
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    : Material(
                        color: Colors.transparent,
                        child: ListTile(
                          selected: selecionado == item.$2,
                          selectedColor: dark ? AppTheme.gold : AppTheme.navy,
                          selectedTileColor: dark ? const Color(0xFF1B2A41) : const Color(0xFFEAF0F9),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          leading: Icon(item.$1, color: selecionado == item.$2 ? (dark ? AppTheme.gold : AppTheme.navy) : muted),
                          title: Text(item.$2, style: TextStyle(color: selecionado == item.$2 ? foreground : muted, fontWeight: selecionado == item.$2 ? FontWeight.w700 : FontWeight.w500, fontSize: 13)),
                          trailing: item.$2 == 'Pendências' ? const CircleAvatar(radius: 10, backgroundColor: Color(0xFF174CCB), child: Text('12', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))) : null,
                          onTap: () => onSelecionar(item.$2),
                        ),
                      ),
              ),
          ])),
          Divider(height: 1, color: line),
          if (!recolhido)
            ListTile(
              leading: CircleAvatar(backgroundColor: dark ? const Color(0xFF263A56) : const Color(0xFFEAF0F9), child: Text(_iniciais(usuario.nome), style: TextStyle(color: dark ? AppTheme.gold : AppTheme.navy, fontWeight: FontWeight.bold))),
              title: Text(usuario.nome, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: foreground, fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: Text('Professor', style: TextStyle(color: muted, fontSize: 12)),
            )
          else
            Padding(padding: const EdgeInsets.all(8), child: CircleAvatar(backgroundColor: dark ? const Color(0xFF263A56) : const Color(0xFFEAF0F9), child: Text(_iniciais(usuario.nome), style: TextStyle(color: dark ? AppTheme.gold : AppTheme.navy, fontWeight: FontWeight.bold)))),
          IconButton(onPressed: onSair, tooltip: 'Sair', icon: const Icon(Icons.logout)),
          const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }

  String _iniciais(String nome) => nome.trim().split(RegExp(r'\s+')).take(2).map((p) => p.isEmpty ? '' : p[0].toUpperCase()).join();
}
