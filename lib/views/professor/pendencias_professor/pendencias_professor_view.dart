import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/professor_ficha_model.dart';
import '../../../view_models/autenticacao_view_model.dart';
import '../../../view_models/professor_view_model.dart';
import '../../../widgets/botao_alternar_tema.dart';
import '../widgets/menu_lateral_professor.dart';
import '../../autenticacao/entrar_view.dart';
import '../../pacientes/buscar_paciente_view.dart';
import '../revisar_fichas_view.dart';

part 'widgets/pendencias_controls_widgets.dart';
part 'widgets/pendencias_lista_widgets.dart';

class PendenciasProfessorView extends StatefulWidget {
  const PendenciasProfessorView({super.key});

  @override
  State<PendenciasProfessorView> createState() =>
      _PendenciasProfessorViewState();
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
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const RevisarFichasView()),
    );
  }

  void _logout() {
    context.read<AutenticacaoViewModel>().logout();
    Navigator.of(context).pushAndRemoveUntil<void>(
      MaterialPageRoute<void>(builder: (_) => const EntrarView()),
      (_) => false,
    );
  }

  void _openSearch() => Navigator.of(context).push<void>(
    MaterialPageRoute<void>(builder: (_) => const BuscarPacienteView()),
  );

  void _selectMenu(String item) {
    if (item == 'Pacientes' || item == 'Prontuários') {
      _openSearch();
    } else if (item == 'Início') {
      Navigator.of(context).maybePop();
    } else if (item != 'Pendências') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$item estará disponível nesta área em breve.')),
      );
    }
  }

  Future<void> _openFilters() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Ordenar por'),
        children: [
          RadioListTile<bool>(
            value: true,
            groupValue: _oldestFirst,
            onChanged: (v) => Navigator.pop(context, v),
            title: const Text('Mais antigas primeiro'),
          ),
          RadioListTile<bool>(
            value: false,
            groupValue: _oldestFirst,
            onChanged: (v) => Navigator.pop(context, v),
            title: const Text('Mais recentes primeiro'),
          ),
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
    final list = _tab == 'Todas'
        ? List<ProfessorFichaModel>.of(all)
        : all.where((f) => _FichaInfo(f).tipo == _tab).toList();
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
      body: Row(
        children: [
          if (usuario != null)
            ValueListenableBuilder<bool>(
              valueListenable: _sidebarCollapsed,
              builder: (context, collapsed, _) => MenuLateralProfessor(
                usuario: usuario,
                selecionado: 'Pendências',
                recolhido: collapsed,
                onSelecionar: _selectMenu,
                onAlternar: () =>
                    _sidebarCollapsed.value = !_sidebarCollapsed.value,
                onSair: _logout,
              ),
            ),
          Expanded(
            child: SafeArea(
              child: RefreshIndicator(
                onRefresh: context.read<ProfessorViewModel>().loadPending,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: _Header(
                        dark: dark,
                        compact: compact,
                        onSearch: _openSearch,
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        compact ? 14 : 28,
                        12,
                        compact ? 14 : 28,
                        28,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1280),
                            child: Consumer<ProfessorViewModel>(
                              builder: (context, model, _) {
                                final all = model.pending;
                                final filtered = _applyFilters(all);
                                final totalPages = (filtered.length / _perPage)
                                    .ceil()
                                    .clamp(1, 9999);
                                final currentPage = _page.clamp(
                                  0,
                                  totalPages - 1,
                                );
                                final start = currentPage * _perPage;
                                final end = (start + _perPage).clamp(
                                  0,
                                  filtered.length,
                                );
                                final visible = filtered.sublist(start, end);

                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
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
                                      decoration: BoxDecoration(
                                        color: card,
                                        border: Border.all(color: line),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: _content(
                                        model,
                                        visible,
                                        dark,
                                        colors.onSurface,
                                        muted,
                                        line,
                                      ),
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
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _content(
    ProfessorViewModel model,
    List<ProfessorFichaModel> visible,
    bool dark,
    Color fg,
    Color muted,
    Color line,
  ) {
    if (model.isLoading && model.pending.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (model.errorMessage != null && model.pending.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              model.errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: muted),
            ),
            TextButton.icon(
              onPressed: model.loadPending,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }
    if (visible.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          children: [
            Icon(
              Icons.task_alt,
              size: 38,
              color: dark ? AppTheme.gold : AppTheme.navy,
            ),
            const SizedBox(height: 8),
            Text(
              'Não há fichas aguardando aprovação.',
              style: TextStyle(color: muted),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, box) {
        final wide = box.maxWidth >= 900;
        return Column(
          children: [
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
              if (i < visible.length - 1)
                Divider(height: 1, color: line, indent: 16, endIndent: 16),
            ],
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Extração dos dados da ficha (mesmos campos usados na home)
