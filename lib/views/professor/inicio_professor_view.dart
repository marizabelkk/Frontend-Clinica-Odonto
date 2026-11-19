import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/professor_ficha_model.dart';
import '../../view_models/autenticacao_view_model.dart';
import '../../view_models/professor_view_model.dart';
import '../../widgets/botao_alternar_tema.dart';
import '../../widgets/menu_lateral_professor.dart';
import '../autenticacao/entrar_view.dart';
import '../pacientes/buscar_paciente_view.dart';
import 'pendencias_professor_view.dart';
import 'revisar_fichas_view.dart';

class InicioProfessorView extends StatefulWidget {
  const InicioProfessorView({super.key});

  @override
  State<InicioProfessorView> createState() => _InicioProfessorViewState();
}

class _InicioProfessorViewState extends State<InicioProfessorView> {
  final ValueNotifier<bool> _sidebarCollapsed = ValueNotifier(false);

  @override
  void dispose() {
    _sidebarCollapsed.dispose();
    super.dispose();
  }
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ProfessorViewModel>().loadPending();
    });
  }

  Future<void> _review(ProfessorFichaModel ficha) async {
    final loaded = await context.read<ProfessorViewModel>().loadFicha(ficha.id);
    if (!mounted || !loaded) return;
    await Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => const RevisarFichasView()));
  }

  void _logout() {
    context.read<AutenticacaoViewModel>().logout();
    Navigator.of(context).pushAndRemoveUntil<void>(MaterialPageRoute<void>(builder: (_) => const EntrarView()), (_) => false);
  }

  void _openPending() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const PendenciasProfessorView()),
    );
  }

  void _selectMenu(String item) {
    if (item == 'Pacientes' || item == 'Prontuários') {
      Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => const BuscarPacienteView()));
    } else if (item == 'Pendências') {
      _openPending();
    } else if (item != 'Início') {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$item estará disponível nesta área em breve.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;
    final page = dark ? AppTheme.darkBackground : const Color(0xFFF7F8FA);
    final card = dark ? AppTheme.darkSurface : Colors.white;
    final line = dark ? const Color(0xFF263A56) : const Color(0xFFE1E5EB);
    final muted = dark ? const Color(0xFFB9C7DD) : const Color(0xFF52647E);
    final usuario = context.watch<AutenticacaoViewModel>().usuario;
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 760;
    return Scaffold(
      backgroundColor: page,
      body: Row(children: [
        if (usuario != null)
          ValueListenableBuilder<bool>(
            valueListenable: _sidebarCollapsed,
            builder: (context, collapsed, _) => MenuLateralProfessor(
              usuario: usuario,
              selecionado: 'Início',
              recolhido: collapsed,
              onSelecionar: _selectMenu,
              onAlternar: () => _sidebarCollapsed.value = !_sidebarCollapsed.value,
              onSair: _logout,
            ),
          ),
        Expanded(child: SafeArea(child: RefreshIndicator(
        onRefresh: context.read<ProfessorViewModel>().loadPending,
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(child: _Header(name: usuario?.nome ?? 'Professor(a)', dark: dark, compact: compact)),
          SliverPadding(padding: EdgeInsets.fromLTRB(compact ? 14 : 28, 16, compact ? 14 : 28, 28), sliver: SliverToBoxAdapter(
            child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1280), child: Consumer<ProfessorViewModel>(builder: (context, model, _) {
              final pending = model.pending;
              return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                _DashboardCards(pending: pending.length, card: card, line: line, muted: muted),
                const SizedBox(height: 16),
                LayoutBuilder(builder: (context, box) {
                  final wide = box.maxWidth >= 900;
                  final table = _Panel(title: 'Pendências de aprovação', action: 'Ver todas', onAction: _openPending, card: card, line: line, foreground: colors.onSurface, child: _pendingContent(model, dark, colors.onSurface, muted, line));
                  final side = Column(children: [
                    _Panel(title: 'Devolvidas para correção', action: 'Ver todas', onAction: () => _selectMenu('Devolvidas'), card: card, line: line, foreground: colors.onSurface, child: _EmptyActivity(icon: Icons.reply, message: 'Nenhuma ficha devolvida para correção.', muted: muted)),
                    const SizedBox(height: 12),
                    _Panel(title: 'Aprovações recentes', action: 'Ver todas', onAction: () => _selectMenu('Aprovadas'), card: card, line: line, foreground: colors.onSurface, child: _EmptyActivity(icon: Icons.check_circle_outline, message: 'As aprovações recentes aparecerão aqui.', muted: muted)),
                  ]);
                  final lower = Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: _Panel(title: 'Busca rápida de paciente', card: card, line: line, foreground: colors.onSurface, child: _PatientSearch(dark: dark, muted: muted, onTap: () => Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => const BuscarPacienteView()))))),
                    const SizedBox(width: 12),
                    Expanded(child: _Panel(title: 'Ações rápidas', card: card, line: line, foreground: colors.onSurface, child: _QuickActions(dark: dark, foreground: colors.onSurface, muted: muted, onSearch: () => Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => const BuscarPacienteView())), onReview: _openPending))),
                  ]);
                  if (!wide) return Column(children: [table, const SizedBox(height: 12), side, const SizedBox(height: 12), _Panel(title: 'Busca rápida de paciente', card: card, line: line, foreground: colors.onSurface, child: _PatientSearch(dark: dark, muted: muted, onTap: () => Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => const BuscarPacienteView())))), const SizedBox(height: 12), _Panel(title: 'Ações rápidas', card: card, line: line, foreground: colors.onSurface, child: _QuickActions(dark: dark, foreground: colors.onSurface, muted: muted, onSearch: () => Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => const BuscarPacienteView())), onReview: _openPending))]);
                  return Column(children: [Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 7, child: Column(children: [table, const SizedBox(height: 12), lower])), const SizedBox(width: 14), Expanded(flex: 3, child: side)]), const SizedBox(height: 12), _PrivacyBanner(dark: dark, card: card, line: line, foreground: colors.onSurface, muted: muted)]);
                }),
                if (model.errorMessage != null && pending.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12), child: Text(model.errorMessage!, style: TextStyle(color: muted))),
              ]);
            }))),
          )),
        ]),
      )),
        ),
      ]),
    );
  }

  Widget _pendingContent(ProfessorViewModel model, bool dark, Color foreground, Color muted, Color line) {
    if (model.isLoading && model.pending.isEmpty) return const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()));
    if (model.errorMessage != null && model.pending.isEmpty) return Padding(padding: const EdgeInsets.all(22), child: Column(children: [Text(model.errorMessage!, textAlign: TextAlign.center, style: TextStyle(color: muted)), TextButton.icon(onPressed: model.loadPending, icon: const Icon(Icons.refresh), label: const Text('Tentar novamente'))]));
    if (model.pending.isEmpty) return Padding(padding: const EdgeInsets.all(28), child: Column(children: [Icon(Icons.task_alt, size: 36, color: dark ? AppTheme.gold : AppTheme.navy), const SizedBox(height: 8), Text('Não há fichas aguardando aprovação.', style: TextStyle(color: muted))]));
    return LayoutBuilder(builder: (context, constraints) {
      final showDetails = constraints.maxWidth >= 700;
      return Column(children: [
        if (showDetails)
          Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), child: Row(children: [Expanded(flex: 4, child: Text('Paciente', style: TextStyle(color: muted, fontWeight: FontWeight.w600))), Expanded(flex: 3, child: Text('Tipo de ficha', style: TextStyle(color: muted, fontWeight: FontWeight.w600))), Expanded(flex: 3, child: Text('Aluno responsável', style: TextStyle(color: muted, fontWeight: FontWeight.w600))), const SizedBox(width: 75)])),
        if (showDetails) Divider(height: 1, color: line),
        for (var i = 0; i < model.pending.length; i++) ...[
          _PendingRow(ficha: model.pending[i], dark: dark, foreground: foreground, muted: muted, showDetails: showDetails, onTap: () => _review(model.pending[i])),
          if (i < model.pending.length - 1) Divider(height: 1, color: line, indent: 14, endIndent: 14),
        ],
      ]);
    });
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.name, required this.dark, required this.compact});
  final String name; final bool dark; final bool compact;
  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).colorScheme.onSurface;
    final muted = dark ? const Color(0xFFB9C7DD) : const Color(0xFF52647E);
    return Padding(padding: EdgeInsets.fromLTRB(compact ? 8 : 18, 14, compact ? 8 : 18, 8), child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Olá, ${name.split(' ').first}! 👋', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: fg, fontSize: compact ? 20 : 27, fontWeight: FontWeight.w800, letterSpacing: -.5)), const SizedBox(height: 3), Text('Acompanhe as atividades da clínica escola.', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: muted, fontSize: compact ? 11 : 14))])),
      if (!compact) const SizedBox(width: 18),
      if (!compact) SizedBox(width: 300, height: 44, child: OutlinedButton.icon(onPressed: () => Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => const BuscarPacienteView())), icon: const Icon(Icons.search), label: const Align(alignment: Alignment.centerLeft, child: Text('Buscar paciente por nome, CPF ou código...', overflow: TextOverflow.ellipsis)), style: OutlinedButton.styleFrom(foregroundColor: dark ? const Color(0xFFD6E4FA) : AppTheme.navy, side: BorderSide(color: dark ? const Color(0xFF34445C) : const Color(0xFFDCE3ED)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))))),
      const BotaoAlternarTema(), IconButton(tooltip: 'Notificações', onPressed: () {}, icon: const Icon(Icons.notifications_none)),
    ]));
  }
}

class _DashboardCards extends StatelessWidget {
  const _DashboardCards({required this.pending, required this.card, required this.line, required this.muted});
  final int pending; final Color card, line, muted;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
    final count = constraints.maxWidth >= 1100 ? 4 : (constraints.maxWidth >= 560 ? 2 : 1);
    final gap = 12.0;
    final itemWidth = (constraints.maxWidth - gap * (count - 1)) / count;
    final primary = Theme.of(context).colorScheme.primary;
    return Wrap(spacing: gap, runSpacing: gap, children: [
      _MetricCard(width: itemWidth, title: 'Pendências', value: '$pending', subtitle: 'Aguardando sua revisão', icon: Icons.assignment_outlined, accent: primary, card: card, line: line, muted: muted),
      _MetricCard(width: itemWidth, title: 'Devolvidas', value: '5', subtitle: 'Fichas para correção', icon: Icons.access_time, accent: const Color(0xFFE9A000), card: card, line: line, muted: muted),
      _MetricCard(width: itemWidth, title: 'Aprovadas (este mês)', value: '28', subtitle: 'Total de fichas aprovadas', icon: Icons.check_circle_outline, accent: const Color(0xFF16813A), card: card, line: line, muted: muted),
      _MetricCard(width: itemWidth, title: 'Pacientes cadastrados', value: '156', subtitle: 'Total no sistema', icon: Icons.people_outline, accent: primary, card: card, line: line, muted: muted),
    ]);
  });
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.width, required this.title, required this.value, required this.subtitle, required this.icon, required this.accent, required this.card, required this.line, required this.muted});
  final double width; final String title, value, subtitle; final IconData icon; final Color accent, card, line, muted;
  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).colorScheme.onSurface;
    return SizedBox(width: width, child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: card, border: Border.all(color: line), borderRadius: BorderRadius.circular(14)), child: Row(children: [Container(width: 52, height: 52, decoration: BoxDecoration(color: accent.withValues(alpha: .12), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: accent, size: 28)), const SizedBox(width: 13), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: TextStyle(color: fg, fontSize: 28, height: 1, fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text(title, style: TextStyle(color: fg, fontWeight: FontWeight.bold)), Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: muted, fontSize: 12))]))])));
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.card, required this.line, required this.foreground, required this.child, this.action, this.onAction});
  final String title; final Color card, line, foreground; final Widget child; final String? action; final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Container(decoration: BoxDecoration(color: card, border: Border.all(color: line), borderRadius: BorderRadius.circular(14)), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Padding(padding: const EdgeInsets.fromLTRB(15, 12, 10, 10), child: Row(children: [Expanded(child: Text(title, style: TextStyle(color: foreground, fontWeight: FontWeight.w800, fontSize: 16))), if (action != null) TextButton(onPressed: onAction, child: Text(action!))])), Divider(height: 1, color: line), child]));
}

class _PendingRow extends StatelessWidget {
  const _PendingRow({required this.ficha, required this.dark, required this.foreground, required this.muted, required this.showDetails, required this.onTap});
  final ProfessorFichaModel ficha; final bool dark, showDetails; final Color foreground, muted; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final patient = ficha.data['paciente'];
    final student = ficha.data['aluno'] ?? ficha.data['aluno_responsavel'];
    final patientName = patient is Map ? (patient['nome_completo']?.toString() ?? 'Ficha #${ficha.id}') : 'Ficha #${ficha.id}';
    final studentName = student is Map ? (student['nome']?.toString() ?? '—') : '—';
    final initials = patientName.trim().split(RegExp(r'\s+')).take(2).map((s) => s.isEmpty ? '' : s[0].toUpperCase()).join();
    final fichaType = (ficha.data['tipo'] ?? ficha.data['tipo_ficha'] ?? ficha.data['categoria'] ?? 'Ficha clínica').toString();
    return InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11), child: Row(children: [CircleAvatar(radius: 21, backgroundColor: dark ? const Color(0xFF0A356D) : const Color(0xFFEAF0F9), foregroundColor: dark ? const Color(0xFFD5E5FF) : AppTheme.navy, child: Text(initials)), const SizedBox(width: 10), Expanded(flex: showDetails ? 4 : 1, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(patientName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: foreground, fontWeight: FontWeight.bold, fontSize: 13)), Text('Ficha #${ficha.id}', style: TextStyle(color: muted, fontSize: 11))])), if (showDetails) ...[Expanded(flex: 3, child: Text(fichaType, maxLines: 2, style: TextStyle(color: foreground, fontSize: 12))), Expanded(flex: 3, child: Text(studentName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: foreground, fontSize: 12)))], FilledButton(onPressed: onTap, style: FilledButton.styleFrom(minimumSize: const Size(72, 36), padding: const EdgeInsets.symmetric(horizontal: 12)), child: const Text('Revisar'))])));
  }
}

class _EmptyActivity extends StatelessWidget {
  const _EmptyActivity({required this.icon, required this.message, required this.muted});
  final IconData icon; final String message; final Color muted;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18), child: Row(children: [Icon(icon, color: muted.withValues(alpha: .8), size: 22), const SizedBox(width: 10), Expanded(child: Text(message, style: TextStyle(color: muted, fontSize: 12)))]));
}

class _PatientSearch extends StatelessWidget {
  const _PatientSearch({required this.dark, required this.muted, required this.onTap});
  final bool dark; final Color muted; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final border = dark ? const Color(0xFF34445C) : const Color(0xFFDCE3ED);
    return Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Material(color: Colors.transparent, child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(11), child: Container(height: 42, padding: const EdgeInsets.symmetric(horizontal: 11), decoration: BoxDecoration(border: Border.all(color: border), borderRadius: BorderRadius.circular(11)), child: Row(children: [Expanded(child: Text('Buscar paciente por nome, CPF ou código...', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: muted, fontSize: 11))), Icon(Icons.search, color: dark ? const Color(0xFFB9C7DD) : AppTheme.navy)])))),
      const SizedBox(height: 12), Text('Pesquisas recentes', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 12)),
      const SizedBox(height: 8), Wrap(spacing: 6, runSpacing: 6, children: ['Maria da Silva', 'João Souza', 'Ana Luiza'].map((name) => ActionChip(label: Text(name, style: const TextStyle(fontSize: 10)), onPressed: onTap, visualDensity: VisualDensity.compact, padding: EdgeInsets.zero)).toList()),
      const SizedBox(height: 7), TextButton.icon(onPressed: onTap, icon: const Icon(Icons.arrow_forward, size: 16), label: const Text('Ver todos os pacientes', style: TextStyle(fontSize: 11))),
    ]));
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.dark, required this.foreground, required this.muted, required this.onSearch, required this.onReview});
  final bool dark; final Color foreground, muted; final VoidCallback onSearch; final VoidCallback? onReview;
  @override
  Widget build(BuildContext context) {
    final actions = <(IconData, String, String, VoidCallback?)>[
      (Icons.search, 'Buscar\npaciente', 'Consultar prontuário', onSearch),
      (Icons.assignment_outlined, 'Ver pendências', 'Fichas para revisar', onReview),
      (Icons.bar_chart_outlined, 'Relatórios', 'Aprovações e atividades', null),
      (Icons.people_outline, 'Usuários', 'Gerenciar acessos', null),
    ];
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          for (var i = 0; i < actions.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Material(
                  color: dark
                      ? const Color(0xFF14243A)
                      : const Color(0xFFF1F4FA),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: actions[i].$4,
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 11,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            actions[i].$1,
                            color: dark ? AppTheme.gold : AppTheme.navy,
                            size: 23,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            actions[i].$2,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: foreground,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            actions[i].$3,
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: muted,
                              fontSize: 8,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PrivacyBanner extends StatelessWidget {
  const _PrivacyBanner({required this.dark, required this.card, required this.line, required this.foreground, required this.muted});
  final bool dark; final Color card, line, foreground, muted;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: dark ? const Color(0xFF14243A) : const Color(0xFFEEF3FC), border: Border.all(color: line), borderRadius: BorderRadius.circular(14)), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.info_outline, color: dark ? AppTheme.gold : AppTheme.navy), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Informações clínicas confidenciais', style: TextStyle(color: foreground, fontWeight: FontWeight.bold, fontSize: 13)), const SizedBox(height: 3), Text('Acesse apenas prontuários sob sua responsabilidade acadêmica.', style: TextStyle(color: muted, fontSize: 12))]))]));
}
