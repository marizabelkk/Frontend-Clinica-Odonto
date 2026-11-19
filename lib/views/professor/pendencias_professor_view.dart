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
import 'revisar_fichas_view.dart';

class PendenciasProfessorView extends StatefulWidget {
  const PendenciasProfessorView({super.key});

  @override
  State<PendenciasProfessorView> createState() => _PendenciasProfessorViewState();
}

class _PendenciasProfessorViewState extends State<PendenciasProfessorView> {
  final ValueNotifier<bool> _sidebarCollapsed = ValueNotifier(false);

  String _tab = 'Todas';
  int _page = 0;
  int _perPage = 10;
  bool _oldestFirst = true;

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

  void _openSearch() => Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => const BuscarPacienteView()));

  void _selectMenu(String item) {
    if (item == 'Pacientes' || item == 'Prontuários') {
      _openSearch();
    } else if (item == 'Início') {
      Navigator.of(context).maybePop();
    } else if (item != 'Pendências') {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$item estará disponível nesta área em breve.')));
    }
  }

  Future<void> _openFilters() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Ordenar por'),
        children: [
          RadioListTile<bool>(value: true, groupValue: _oldestFirst, onChanged: (v) => Navigator.pop(context, v), title: const Text('Mais antigas primeiro')),
          RadioListTile<bool>(value: false, groupValue: _oldestFirst, onChanged: (v) => Navigator.pop(context, v), title: const Text('Mais recentes primeiro')),
        ],
      ),
    );
    if (result != null) {
      setState(() {
        _oldestFirst = result;
        _page = 0;
      });
    }
  }

  List<ProfessorFichaModel> _applyFilters(List<ProfessorFichaModel> all) {
    final list = _tab == 'Todas' ? List<ProfessorFichaModel>.of(all) : all.where((f) => _FichaInfo(f).tipo == _tab).toList();
    list.sort((a, b) {
      final da = _FichaInfo(a).enviadaEm;
      final db = _FichaInfo(b).enviadaEm;
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return _oldestFirst ? da.compareTo(db) : db.compareTo(da);
    });
    return list;
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
    final compact = MediaQuery.sizeOf(context).width < 760;

    return Scaffold(
      backgroundColor: page,
      body: Row(children: [
        if (usuario != null)
          ValueListenableBuilder<bool>(
            valueListenable: _sidebarCollapsed,
            builder: (context, collapsed, _) => MenuLateralProfessor(
              usuario: usuario,
              selecionado: 'Pendências',
              recolhido: collapsed,
              onSelecionar: _selectMenu,
              onAlternar: () => _sidebarCollapsed.value = !_sidebarCollapsed.value,
              onSair: _logout,
            ),
          ),
        Expanded(
          child: SafeArea(
            child: RefreshIndicator(
              onRefresh: context.read<ProfessorViewModel>().loadPending,
              child: CustomScrollView(slivers: [
                SliverToBoxAdapter(child: _Header(dark: dark, compact: compact, onSearch: _openSearch)),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(compact ? 14 : 28, 12, compact ? 14 : 28, 28),
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1280),
                        child: Consumer<ProfessorViewModel>(builder: (context, model, _) {
                          final all = model.pending;
                          final filtered = _applyFilters(all);
                          final totalPages = (filtered.length / _perPage).ceil().clamp(1, 9999);
                          final currentPage = _page.clamp(0, totalPages - 1);
                          final start = currentPage * _perPage;
                          final end = (start + _perPage).clamp(0, filtered.length);
                          final visible = filtered.sublist(start, end);

                          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                            _Tabs(
                              all: all,
                              selected: _tab,
                              dark: dark,
                              line: line,
                              card: card,
                              onSelect: (t) => setState(() {
                                _tab = t;
                                _page = 0;
                              }),
                              onFilters: _openFilters,
                            ),
                            const SizedBox(height: 14),
                            Container(
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(color: card, border: Border.all(color: line), borderRadius: BorderRadius.circular(14)),
                              child: _content(model, visible, dark, colors.onSurface, muted, line),
                            ),
                            const SizedBox(height: 16),
                            _Footer(
                              shown: visible.length,
                              total: filtered.length,
                              page: currentPage,
                              totalPages: totalPages,
                              perPage: _perPage,
                              dark: dark,
                              muted: muted,
                              line: line,
                              card: card,
                              onPage: (p) => setState(() => _page = p),
                              onPerPage: (v) => setState(() {
                                _perPage = v;
                                _page = 0;
                              }),
                            ),
                          ]);
                        }),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _content(ProfessorViewModel model, List<ProfessorFichaModel> visible, bool dark, Color fg, Color muted, Color line) {
    if (model.isLoading && model.pending.isEmpty) {
      return const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()));
    }
    if (model.errorMessage != null && model.pending.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          Text(model.errorMessage!, textAlign: TextAlign.center, style: TextStyle(color: muted)),
          TextButton.icon(onPressed: model.loadPending, icon: const Icon(Icons.refresh), label: const Text('Tentar novamente')),
        ]),
      );
    }
    if (visible.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(36),
        child: Column(children: [
          Icon(Icons.task_alt, size: 38, color: dark ? AppTheme.gold : AppTheme.navy),
          const SizedBox(height: 8),
          Text('Não há fichas aguardando aprovação.', style: TextStyle(color: muted)),
        ]),
      );
    }

    return LayoutBuilder(builder: (context, box) {
      final wide = box.maxWidth >= 900;
      return Column(children: [
        if (wide) _TableHeader(muted: muted, dark: dark),
        if (wide) Divider(height: 1, color: line),
        for (var i = 0; i < visible.length; i++) ...[
          _PendingRow(
            ficha: visible[i],
            dark: dark,
            foreground: fg,
            muted: muted,
            wide: wide,
            onReview: () => _review(visible[i]),
          ),
          if (i < visible.length - 1) Divider(height: 1, color: line, indent: 16, endIndent: 16),
        ],
      ]);
    });
  }
}

// ---------------------------------------------------------------------------
// Extração dos dados da ficha (mesmos campos usados na home)
// ---------------------------------------------------------------------------

class _FichaInfo {
  _FichaInfo(this.ficha);
  final ProfessorFichaModel ficha;

  Map<dynamic, dynamic>? get _paciente => ficha.data['paciente'] is Map ? ficha.data['paciente'] as Map : null;
  Map<dynamic, dynamic>? get _aluno {
    final a = ficha.data['aluno'] ?? ficha.data['aluno_responsavel'];
    return a is Map ? a : null;
  }

  String get paciente => _paciente?['nome_completo']?.toString() ?? 'Ficha #${ficha.id}';

  String get cpfMascarado {
    final digits = (_paciente?['cpf']?.toString() ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length < 2) return 'Ficha #${ficha.id}';
    return 'CPF: ***.***.***-${digits.substring(digits.length - 2)}';
  }

  String get iniciais => paciente.trim().split(RegExp(r'\s+')).take(2).map((s) => s.isEmpty ? '' : s[0].toUpperCase()).join();

  String get tipo => (ficha.data['tipo'] ?? ficha.data['tipo_ficha'] ?? ficha.data['categoria'] ?? 'Ficha clínica').toString();

  String get subtipo => (ficha.data['subtipo'] ?? ficha.data['procedimento'] ?? ficha.data['descricao'] ?? '').toString();

  String get aluno => _aluno?['nome']?.toString() ?? '—';

  String get turma => (_aluno?['turma'] ?? _aluno?['matricula'] ?? '').toString();

  DateTime? get enviadaEm {
    final raw = ficha.data['enviada_em'] ?? ficha.data['data_envio'] ?? ficha.data['created_at'];
    return raw == null ? null : DateTime.tryParse(raw.toString())?.toLocal();
  }

  String get enviadaFormatada {
    final d = enviadaEm;
    if (d == null) return '—';
    String p(int n) => n.toString().padLeft(2, '0');
    return '${p(d.day)}/${p(d.month)}/${d.year}, ${p(d.hour)}:${p(d.minute)}';
  }

  Duration? get pendenteHa {
    final d = enviadaEm;
    return d == null ? null : DateTime.now().difference(d);
  }

  String get pendenteTexto {
    final d = pendenteHa;
    if (d == null) return '—';
    if (d.inDays >= 2) return '${d.inDays} dias';
    if (d.inDays == 1) return '1 dia';
    if (d.inHours >= 1) return '${d.inHours} horas';
    return 'Agora há pouco';
  }

  /// 0 = normal, 1 = atenção (1 dia), 2 = urgente (2+ dias)
  int get urgencia {
    final d = pendenteHa;
    if (d == null) return 0;
    if (d.inDays >= 2) return 2;
    if (d.inDays >= 1) return 1;
    return 0;
  }

  Color get corTipo {
    final t = tipo.toLowerCase();
    if (t.contains('cirurg')) return const Color(0xFF16A34A);
    if (t.contains('odontoped')) return const Color(0xFFF59E0B);
    return const Color(0xFF1D4ED8);
  }
}

// ---------------------------------------------------------------------------
// Cabeçalho
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({required this.dark, required this.compact, required this.onSearch});
  final bool dark, compact;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).colorScheme.onSurface;
    final muted = dark ? const Color(0xFFB9C7DD) : const Color(0xFF52647E);
    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 8 : 18, 14, compact ? 8 : 18, 8),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Pendências de aprovação', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: fg, fontSize: compact ? 20 : 27, fontWeight: FontWeight.w800, letterSpacing: -.5)),
            const SizedBox(height: 3),
            Text('Visualize todas as fichas aguardando sua revisão.', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: muted, fontSize: compact ? 11 : 14)),
          ]),
        ),
        if (!compact) const SizedBox(width: 18),
        if (!compact)
          SizedBox(
            width: 300,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: onSearch,
              icon: const Icon(Icons.search),
              label: const Align(alignment: Alignment.centerLeft, child: Text('Buscar paciente por nome, CPF ou código...', overflow: TextOverflow.ellipsis)),
              style: OutlinedButton.styleFrom(
                foregroundColor: dark ? const Color(0xFFD6E4FA) : AppTheme.navy,
                side: BorderSide(color: dark ? const Color(0xFF34445C) : const Color(0xFFDCE3ED)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        const BotaoAlternarTema(),
        IconButton(tooltip: 'Notificações', onPressed: () {}, icon: const Icon(Icons.notifications_none)),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Abas por tipo de ficha + botão Filtros
// ---------------------------------------------------------------------------

class _Tabs extends StatelessWidget {
  const _Tabs({required this.all, required this.selected, required this.dark, required this.line, required this.card, required this.onSelect, required this.onFilters});
  final List<ProfessorFichaModel> all;
  final String selected;
  final bool dark;
  final Color line, card;
  final ValueChanged<String> onSelect;
  final VoidCallback onFilters;

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final f in all) {
      final t = _FichaInfo(f).tipo;
      counts[t] = (counts[t] ?? 0) + 1;
    }
    final tipos = counts.keys.toList()..sort((a, b) => counts[b]!.compareTo(counts[a]!));
    final fg = dark ? const Color(0xFFD6E4FA) : AppTheme.navy;

    return Wrap(spacing: 10, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: [
      _TabChip(label: 'Todas', count: all.length, active: selected == 'Todas', dark: dark, line: line, card: card, onTap: () => onSelect('Todas')),
      for (final t in tipos) _TabChip(label: t, count: counts[t]!, active: selected == t, dark: dark, line: line, card: card, onTap: () => onSelect(t)),
      OutlinedButton.icon(
        onPressed: onFilters,
        icon: const Icon(Icons.filter_alt_outlined, size: 18),
        label: const Text('Filtros'),
        style: OutlinedButton.styleFrom(
          foregroundColor: fg,
          minimumSize: const Size(0, 46),
          backgroundColor: card,
          side: BorderSide(color: line),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    ]);
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({required this.label, required this.count, required this.active, required this.dark, required this.line, required this.card, required this.onTap});
  final String label;
  final int count;
  final bool active, dark;
  final Color line, card;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = active ? (dark ? AppTheme.gold.withValues(alpha: .18) : const Color(0xFFFDEFB8)) : card;
    final fg = dark ? const Color(0xFFD6E4FA) : AppTheme.navy;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: active ? AppTheme.gold : line),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(label, style: TextStyle(color: fg, fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: active ? AppTheme.navy : (dark ? const Color(0xFF14243A) : const Color(0xFFE8EEFB)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('$count', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: active ? Colors.white : fg)),
            ),
          ]),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tabela
// ---------------------------------------------------------------------------

class _TableHeader extends StatelessWidget {
  const _TableHeader({required this.muted, required this.dark});
  final Color muted;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(color: muted, fontWeight: FontWeight.w600, fontSize: 13);
    return Container(
      color: dark ? const Color(0xFF14243A) : const Color(0xFFEEF3FC),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Expanded(flex: 22, child: Text('Paciente', style: style)),
        Expanded(flex: 22, child: Text('Tipo de ficha', style: style)),
        Expanded(flex: 18, child: Text('Aluno responsável', style: style)),
        Expanded(flex: 17, child: Text('Enviada em', style: style)),
        Expanded(flex: 13, child: Text('Tempo pendente', style: style)),
        const SizedBox(width: 120),
      ]),
    );
  }
}

class _PendingRow extends StatelessWidget {
  const _PendingRow({required this.ficha, required this.dark, required this.foreground, required this.muted, required this.wide, required this.onReview});
  final ProfessorFichaModel ficha;
  final bool dark, wide;
  final Color foreground, muted;
  final VoidCallback onReview;

  Color _urgencyColor(int u) => switch (u) {
        2 => const Color(0xFFD92D20),
        1 => const Color(0xFFD97706),
        _ => muted,
      };

  @override
  Widget build(BuildContext context) {
    final info = _FichaInfo(ficha);
    final urgencyColor = _urgencyColor(info.urgencia);

    final avatar = CircleAvatar(
      radius: 21,
      backgroundColor: dark ? const Color(0xFF0A356D) : const Color(0xFFE4ECFB),
      foregroundColor: dark ? const Color(0xFFD5E5FF) : const Color(0xFF1D4ED8),
      child: Text(info.iniciais, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
    );

    final paciente = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(info.paciente, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: foreground, fontWeight: FontWeight.bold, fontSize: 13)),
      Text(info.cpfMascarado, style: TextStyle(color: muted, fontSize: 11)),
    ]);

    final tipo = Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Container(width: 8, height: 8, decoration: BoxDecoration(color: info.corTipo, shape: BoxShape.circle)),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(info.tipo, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: foreground, fontWeight: FontWeight.w600, fontSize: 12)),
          if (info.subtipo.isNotEmpty) Text(info.subtipo, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: muted, fontSize: 11)),
        ]),
      ),
    ]);

    final aluno = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(info.aluno, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: foreground, fontWeight: FontWeight.w600, fontSize: 12)),
      if (info.turma.isNotEmpty) Text(info.turma, style: TextStyle(color: muted, fontSize: 11)),
    ]);

    final tempo = Row(children: [
      Icon(Icons.schedule, size: 18, color: urgencyColor),
      const SizedBox(width: 6),
      Flexible(
        child: Text(
          info.pendenteTexto,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: urgencyColor, fontWeight: info.urgencia > 0 ? FontWeight.w700 : FontWeight.w600, fontSize: 12),
        ),
      ),
    ]);

    final reviewButton = FilledButton(
      onPressed: onReview,
      style: FilledButton.styleFrom(minimumSize: const Size(76, 36), padding: const EdgeInsets.symmetric(horizontal: 14)),
      child: const Text('Revisar'),
    );

    final menu = PopupMenuButton<String>(
      tooltip: 'Mais ações',
      icon: Icon(Icons.more_vert, color: dark ? const Color(0xFFD6E4FA) : AppTheme.navy),
      onSelected: (v) {
        if (v == 'revisar') onReview();
      },
      itemBuilder: (_) => const [PopupMenuItem(value: 'revisar', child: Text('Revisar ficha'))],
    );

    return InkWell(
      onTap: onReview,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: wide
            ? Row(children: [
                Expanded(flex: 22, child: Row(children: [avatar, const SizedBox(width: 12), Expanded(child: paciente)])),
                Expanded(flex: 22, child: Padding(padding: const EdgeInsets.only(right: 12), child: tipo)),
                Expanded(flex: 18, child: aluno),
                Expanded(flex: 17, child: Text(info.enviadaFormatada, style: TextStyle(color: muted, fontSize: 12))),
                Expanded(flex: 13, child: tempo),
                SizedBox(width: 120, child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [reviewButton, menu])),
              ])
            : Row(children: [
                avatar,
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    paciente,
                    const SizedBox(height: 6),
                    Text('${info.tipo}${info.subtipo.isEmpty ? '' : ' · ${info.subtipo}'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: foreground, fontSize: 11)),
                    const SizedBox(height: 4),
                    tempo,
                  ]),
                ),
                const SizedBox(width: 8),
                reviewButton,
              ]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Rodapé: contagem, paginação e itens por página
// ---------------------------------------------------------------------------

class _Footer extends StatelessWidget {
  const _Footer({
    required this.shown,
    required this.total,
    required this.page,
    required this.totalPages,
    required this.perPage,
    required this.dark,
    required this.muted,
    required this.line,
    required this.card,
    required this.onPage,
    required this.onPerPage,
  });
  final int shown, total, page, totalPages, perPage;
  final bool dark;
  final Color muted, line, card;
  final ValueChanged<int> onPage;
  final ValueChanged<int> onPerPage;

  @override
  Widget build(BuildContext context) {
    final fg = dark ? const Color(0xFFD6E4FA) : AppTheme.navy;

    Widget pageButton(int p) {
      final active = p == page;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Material(
          color: active ? AppTheme.navy : card,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: () => onPage(p),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: active ? AppTheme.navy : line)),
              child: Text('${p + 1}', style: TextStyle(color: active ? Colors.white : fg, fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
            ),
          ),
        ),
      );
    }

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 12,
      spacing: 16,
      children: [
        Text('Mostrando $shown de $total pendências', style: TextStyle(color: muted, fontSize: 13)),
        Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(tooltip: 'Anterior', onPressed: page > 0 ? () => onPage(page - 1) : null, icon: const Icon(Icons.chevron_left)),
          for (var p = 0; p < totalPages; p++) pageButton(p),
          IconButton(tooltip: 'Próxima', onPressed: page < totalPages - 1 ? () => onPage(page + 1) : null, icon: const Icon(Icons.chevron_right)),
        ]),
        Row(mainAxisSize: MainAxisSize.min, children: [
          Text('Itens por página', style: TextStyle(color: muted, fontSize: 13)),
          const SizedBox(width: 12),
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: card, border: Border.all(color: line), borderRadius: BorderRadius.circular(8)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: perPage,
                dropdownColor: card,
                style: TextStyle(color: fg, fontSize: 14),
                items: const [10, 20, 50].map((n) => DropdownMenuItem(value: n, child: Text('$n'))).toList(),
                onChanged: (v) {
                  if (v != null) onPerPage(v);
                },
              ),
            ),
          ),
        ]),
      ],
    );
  }
}