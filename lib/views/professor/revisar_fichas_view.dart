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

// ---------------------------------------------------------------------------
// Paleta (mesma das telas Início e Pendências)
// ---------------------------------------------------------------------------

class _P {
  _P(this.dark);
  final bool dark;

  static _P of(BuildContext context) => _P(Theme.of(context).brightness == Brightness.dark);

  Color get page => dark ? AppTheme.darkBackground : const Color(0xFFF7F8FA);
  Color get card => dark ? AppTheme.darkSurface : Colors.white;
  Color get line => dark ? const Color(0xFF263A56) : const Color(0xFFE1E5EB);
  Color get muted => dark ? const Color(0xFFB9C7DD) : const Color(0xFF52647E);
  Color get soft => dark ? const Color(0xFF14243A) : const Color(0xFFEEF3FC);
  Color get field => dark ? const Color(0xFF101D30) : const Color(0xFFFAFBFE);
  Color get navy => dark ? const Color(0xFFD6E4FA) : AppTheme.navy;
  Color get title => dark ? const Color(0xFF9DBBFF) : const Color(0xFF1D4ED8);
  Color get yellowSoft => dark ? AppTheme.gold.withValues(alpha: .18) : const Color(0xFFFDEFB8);
  Color get green => const Color(0xFF16813A);
}

// ---------------------------------------------------------------------------
// Tela
// ---------------------------------------------------------------------------

class RevisarFichasView extends StatefulWidget {
  const RevisarFichasView({super.key});

  @override
  State<RevisarFichasView> createState() => _RevisarFichasViewState();
}

class _RevisarFichasViewState extends State<RevisarFichasView> {
  final ValueNotifier<bool> _sidebarCollapsed = ValueNotifier(false);
  final TextEditingController _obs = TextEditingController();
  final List<GlobalKey> _keys = List.generate(12, (_) => GlobalKey());
  final Set<int> _collapsedSections = {};

  int _tab = 0;
  int _activeSection = 0;
  String? _obsError;

  static const _tabs = ['Ficha preenchida', 'Odontograma', 'Exames e anexos', 'Histórico de versões'];

  @override
  void dispose() {
    _sidebarCollapsed.dispose();
    _obs.dispose();
    super.dispose();
  }

  void _logout() {
    context.read<AutenticacaoViewModel>().logout();
    Navigator.of(context).pushAndRemoveUntil<void>(MaterialPageRoute<void>(builder: (_) => const EntrarView()), (_) => false);
  }

  void _openSearch() => Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => const BuscarPacienteView()));

  void _selectMenu(String item) {
    if (item == 'Pacientes' || item == 'Prontuários') {
      _openSearch();
    } else if (item == 'Início' || item == 'Pendências') {
      Navigator.of(context).maybePop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$item estará disponível nesta área em breve.')));
    }
  }

  void _goToSection(int index) {
    setState(() {
      _activeSection = index;
      _collapsedSections.remove(index);
    });
    final ctx = _keys[index].currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300), alignment: .05);
    }
  }

  Future<void> _decide(DecisaoProfessor decision) async {
    final model = context.read<ProfessorViewModel>();
    final observation = _obs.text.trim();

    if (decision == DecisaoProfessor.correcaoSolicitada) {
      if (observation.isEmpty) {
        setState(() => _obsError = 'A observação é obrigatória para devolver a ficha.');
        return;
      }
      setState(() => _obsError = null);
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Aprovar ficha?'),
          content: const Text('A ficha será finalizada conforme as regras do sistema.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Aprovar')),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    final success = await model.decide(
      decisao: decision,
      observacao: observation.isEmpty ? null : observation,
    );
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(decision == DecisaoProfessor.aprovada ? 'Ficha aprovada.' : 'Correção solicitada.')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _P.of(context);
    final usuario = context.watch<AutenticacaoViewModel>().usuario;
    final compact = MediaQuery.sizeOf(context).width < 760;

    return Scaffold(
      backgroundColor: p.page,
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
            child: Consumer<ProfessorViewModel>(builder: (context, model, _) {
              final ficha = model.selected;
              if (ficha == null) {
                return Center(child: Text(model.errorMessage ?? 'Ficha indisponível.', style: TextStyle(color: p.muted)));
              }
              final data = ficha.data;
              final info = _Info(data);
              final status = _statusLabel((data['status'] ?? ficha.status)?.toString());
              final sections = info.sections;

              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(compact ? 14 : 26, 14, compact ? 14 : 26, 28),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1360),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      _TopBar(p: p, compact: compact, onSearch: _openSearch),
                      const SizedBox(height: 14),
                      _PatientCard(p: p, info: info, onRecord: _openSearch),
                      const SizedBox(height: 16),
                      _TabsBar(p: p, tabs: _tabs, selected: _tab, onSelect: (i) => setState(() => _tab = i)),
                      const SizedBox(height: 16),
                      LayoutBuilder(builder: (context, box) {
                        final wide = box.maxWidth >= 1100;
                        final panel = _DecisionPanel(
                          p: p,
                          model: model,
                          status: status,
                          controller: _obs,
                          errorText: _obsError,
                          onApprove: () => _decide(DecisaoProfessor.aprovada),
                          onReturn: () => _decide(DecisaoProfessor.correcaoSolicitada),
                          onCancel: () => Navigator.of(context).maybePop(),
                          onChanged: () {
                            if (_obsError != null) setState(() => _obsError = null);
                          },
                        );

                        if (_tab != 0) {
                          final placeholder = _Placeholder(p: p, label: _tabs[_tab]);
                          return wide
                              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: placeholder), const SizedBox(width: 16), SizedBox(width: 340, child: panel)])
                              : Column(children: [placeholder, const SizedBox(height: 16), panel]);
                        }

                        final content = Column(children: [
                          for (var i = 0; i < sections.length; i++)
                            KeyedSubtree(
                              key: _keys[i],
                              child: _SectionCard(
                                p: p,
                                index: i + 1,
                                section: sections[i],
                                expanded: !_collapsedSections.contains(i),
                                onToggle: () => setState(() {
                                  if (!_collapsedSections.add(i)) _collapsedSections.remove(i);
                                }),
                              ),
                            ),
                        ]);

                        if (!wide) return Column(children: [content, const SizedBox(height: 4), panel]);

                        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          SizedBox(width: 250, child: _SectionsList(p: p, sections: sections, active: _activeSection, onTap: _goToSection)),
                          const SizedBox(width: 16),
                          Expanded(child: content),
                          const SizedBox(width: 16),
                          SizedBox(width: 340, child: panel),
                        ]);
                      }),
                    ]),
                  ),
                ),
              );
            }),
          ),
        ),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Dados da ficha
// ---------------------------------------------------------------------------

class _Secao {
  const _Secao(this.title, this.fields);
  final String title;
  final Map<String, dynamic> fields;

  bool get filled => fields.values.any((v) => v != null && (v is! String || v.trim().isNotEmpty));
}

class _Info {
  _Info(this.data);
  final Map<String, dynamic> data;

  Map<String, dynamic> _map(Object? v) => v is Map ? Map<String, dynamic>.from(v) : const <String, dynamic>{};

  Map<String, dynamic> get paciente => _map(data['paciente']);
  Map<String, dynamic> get aluno => _map(data['aluno'] ?? data['aluno_responsavel']);
  Map<String, dynamic> get semiologia => _map(data['semiologia']);

  String get nome => paciente['nome_completo']?.toString() ?? 'Paciente';

  String get iniciais => nome.trim().split(RegExp(r'\s+')).take(2).map((s) => s.isEmpty ? '' : s[0].toUpperCase()).join();

  String get cpf {
    final d = (paciente['cpf']?.toString() ?? '').replaceAll(RegExp(r'\D'), '');
    return d.length < 2 ? 'CPF não informado' : 'CPF: ***.***.***-${d.substring(d.length - 2)}';
  }

  String get nascimentoEIdade {
    final raw = paciente['data_nascimento']?.toString();
    final d = raw == null ? null : DateTime.tryParse(raw);
    if (d == null) return '';
    final now = DateTime.now();
    var age = now.year - d.year;
    if (now.month < d.month || (now.month == d.month && now.day < d.day)) age--;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ($age anos)';
  }

  String get sexo => switch (paciente['sexo']?.toString().toUpperCase()) {
        'F' || 'FEMININO' => 'Feminino',
        'M' || 'MASCULINO' => 'Masculino',
        _ => '',
      };

  String get tipo => data['tipo'] == 'SEMIOLOGIA' ? 'Semiologia' : _humanize(data['tipo']?.toString() ?? 'Ficha');
  String get subtipo => (data['subtipo'] ?? data['procedimento'] ?? data['descricao'] ?? '').toString();
  String get alunoNome => aluno['nome']?.toString() ?? '—';
  String get alunoMatricula => (aluno['matricula'] ?? aluno['turma'] ?? '').toString();

  String get enviadaEm {
    final raw = data['enviada_em'] ?? data['data_envio'] ?? data['created_at'];
    final d = raw == null ? null : DateTime.tryParse(raw.toString())?.toLocal();
    if (d == null) return '—';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} às ${two(d.hour)}:${two(d.minute)}';
  }

  String get atendimento => (data['atendimento_codigo'] ?? (data['atendimento_id'] != null ? '#${data['atendimento_id']}' : '—')).toString();

  List<_Secao> get sections {
    final s = semiologia;
    const known = {
      'queixa_principal',
      'historia_doenca_atual',
      'antecedentes_familiares',
      'medicamentos_alergias',
      'habitos_historia_odontologica',
      'observacoes_gerais',
      'diagnostico',
      'plano_tratamento',
      'necessita_encaminhamento',
      'especialidade_encaminhamento_id',
      'motivo_encaminhamento',
    };
    final others = {
      for (final e in s.entries)
        if (!known.contains(e.key)) _humanize(e.key): e.value,
    };
    return [
      _Secao('Queixa e história atual', {'Queixa principal': s['queixa_principal'], 'História da doença atual': s['historia_doenca_atual']}),
      _Secao('Histórico médico', {'Antecedentes familiares': s['antecedentes_familiares']}),
      _Secao('Medicamentos e alergias', {'Medicamentos e alergias': s['medicamentos_alergias']}),
      _Secao('Hábitos e história odontológica', {'Descrição registrada': s['habitos_historia_odontologica']}),
      _Secao('Diagnóstico e plano', {'Diagnóstico': s['diagnostico'], 'Plano de tratamento': s['plano_tratamento']}),
      _Secao('Encaminhamento', {
        'Necessita encaminhamento': s['necessita_encaminhamento'],
        'Especialidade de destino (ID)': s['especialidade_encaminhamento_id'],
        'Motivo do encaminhamento': s['motivo_encaminhamento'],
      }),
      _Secao('Observações gerais', {'Observações': s['observacoes_gerais']}),
      if (others.isNotEmpty) _Secao('Outras informações', others),
    ];
  }
}

String _humanize(String value) => value
    .replaceAll('_', ' ')
    .split(' ')
    .where((w) => w.isNotEmpty)
    .map((w) => '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
    .join(' ');

String _statusLabel(String? status) => switch (status) {
      'RASCUNHO' => 'Rascunho',
      'AGUARDANDO_APROVACAO' => 'Aguardando aprovação',
      'CORRECAO_SOLICITADA' => 'Correção solicitada',
      'APROVADA' => 'Aprovada',
      null || '' => 'Aguardando aprovação',
      _ => _humanize(status),
    };

// ---------------------------------------------------------------------------
// Barra superior
// ---------------------------------------------------------------------------

class _TopBar extends StatelessWidget {
  const _TopBar({required this.p, required this.compact, required this.onSearch});
  final _P p;
  final bool compact;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).colorScheme.onSurface;
    return Row(children: [
      TextButton.icon(
        onPressed: () => Navigator.of(context).maybePop(),
        icon: const Icon(Icons.chevron_left),
        label: const Text('Voltar'),
        style: TextButton.styleFrom(foregroundColor: p.title),
      ),
      Container(width: 1, height: 34, margin: const EdgeInsets.symmetric(horizontal: 12), color: p.line),
      Flexible(
        child: Text('Revisão de ficha', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: fg, fontSize: compact ? 20 : 27, fontWeight: FontWeight.w800, letterSpacing: -.5)),
      ),
      const SizedBox(width: 12),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: p.yellowSoft, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppTheme.gold)),
        child: Text('PENDENTE', style: TextStyle(color: p.dark ? AppTheme.gold : AppTheme.navy, fontSize: 11, fontWeight: FontWeight.w800)),
      ),
      const Spacer(),
      if (!compact)
        SizedBox(
          width: 300,
          height: 44,
          child: OutlinedButton.icon(
            onPressed: onSearch,
            icon: const Icon(Icons.search),
            label: const Align(alignment: Alignment.centerLeft, child: Text('Buscar paciente por nome, CPF ou código...', overflow: TextOverflow.ellipsis)),
            style: OutlinedButton.styleFrom(
              foregroundColor: p.navy,
              side: BorderSide(color: p.line),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      const BotaoAlternarTema(),
      IconButton(tooltip: 'Notificações', onPressed: () {}, icon: const Icon(Icons.notifications_none)),
    ]);
  }
}

// ---------------------------------------------------------------------------
// Cartão do paciente
// ---------------------------------------------------------------------------

class _PatientCard extends StatelessWidget {
  const _PatientCard({required this.p, required this.info, required this.onRecord});
  final _P p;
  final _Info info;
  final VoidCallback onRecord;

  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).colorScheme.onSurface;

    Widget meta(String label, String value, [String? sub]) => Padding(
          padding: const EdgeInsets.only(right: 28),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(color: p.muted, fontSize: 11)),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 14)),
            if (sub != null && sub.isNotEmpty) ...[const SizedBox(height: 4), Text(sub, style: TextStyle(color: p.muted, fontSize: 12))],
          ]),
        );

    final details = [info.nascimentoEIdade, info.sexo].where((e) => e.isNotEmpty).join('  •  ');

    final identity = Row(mainAxisSize: MainAxisSize.min, children: [
      CircleAvatar(
        radius: 34,
        backgroundColor: p.dark ? const Color(0xFF0A356D) : const Color(0xFFE4ECFB),
        foregroundColor: p.dark ? const Color(0xFFD5E5FF) : const Color(0xFF1D4ED8),
        child: Text(info.iniciais, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 24)),
      ),
      const SizedBox(width: 16),
      Flexible(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(info.nome, style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 19)),
          const SizedBox(height: 4),
          Text([info.cpf, details].where((e) => e.isNotEmpty).join('  •  '), style: TextStyle(color: p.muted, fontSize: 12)),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onRecord,
            icon: const Icon(Icons.arrow_forward, size: 16),
            label: const Text('Ver prontuário completo'),
            iconAlignment: IconAlignment.end,
            style: OutlinedButton.styleFrom(foregroundColor: p.title, side: BorderSide(color: p.title.withValues(alpha: .6)), minimumSize: const Size(0, 36)),
          ),
        ]),
      ),
    ]);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: p.card, border: Border.all(color: p.line), borderRadius: BorderRadius.circular(14)),
      child: LayoutBuilder(builder: (context, box) {
        final metas = Wrap(runSpacing: 16, children: [
          meta('Tipo de ficha', info.tipo, info.subtipo),
          meta('Aluno responsável', info.alunoNome, info.alunoMatricula.isEmpty ? null : 'Matrícula: ${info.alunoMatricula}'),
          meta('Enviada em', info.enviadaEm),
          meta('Código do atendimento', info.atendimento),
        ]);
        if (box.maxWidth < 980) {
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [identity, const SizedBox(height: 18), metas]);
        }
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 5, child: identity),
          Container(width: 1, height: 84, margin: const EdgeInsets.symmetric(horizontal: 20), color: p.line),
          Expanded(flex: 6, child: metas),
        ]);
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// Abas
// ---------------------------------------------------------------------------

class _TabsBar extends StatelessWidget {
  const _TabsBar({required this.p, required this.tabs, required this.selected, required this.onSelect});
  final _P p;
  final List<String> tabs;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: p.line))),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (var i = 0; i < tabs.length; i++)
              InkWell(
                onTap: () => onSelect(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: i == selected ? AppTheme.gold : Colors.transparent, width: 3))),
                  child: Text(tabs[i], style: TextStyle(color: i == selected ? p.navy : p.muted, fontWeight: i == selected ? FontWeight.w700 : FontWeight.w500)),
                ),
              ),
          ]),
        ),
      );
}

// ---------------------------------------------------------------------------
// Lista lateral de seções
// ---------------------------------------------------------------------------

class _SectionsList extends StatelessWidget {
  const _SectionsList({required this.p, required this.sections, required this.active, required this.onTap});
  final _P p;
  final List<_Secao> sections;
  final int active;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: p.card, border: Border.all(color: p.line), borderRadius: BorderRadius.circular(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 12),
            child: Text('Seções da ficha', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w800)),
          ),
          for (var i = 0; i < sections.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Material(
                color: i == active ? p.yellowSoft : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: () => onTap(i),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: i == active ? AppTheme.gold : Colors.transparent),
                    ),
                    child: Row(children: [
                      Icon(sections[i].filled ? Icons.check_circle_outline : Icons.radio_button_unchecked, size: 20, color: sections[i].filled ? p.green : p.muted),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text('${i + 1}. ${sections[i].title}', style: TextStyle(color: i == active ? p.navy : p.muted, fontSize: 13, fontWeight: i == active ? FontWeight.w700 : FontWeight.w500)),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
        ]),
      );
}

// ---------------------------------------------------------------------------
// Cartão de seção + campos
// ---------------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.p, required this.index, required this.section, required this.expanded, required this.onToggle});
  final _P p;
  final int index;
  final _Secao section;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final populated = section.fields.entries.where((e) => e.value != null && (e.value is! String || (e.value as String).trim().isNotEmpty)).toList();
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(color: p.card, border: Border.all(color: p.line), borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
            child: Row(children: [
              Expanded(child: Text('$index.  ${section.title}', style: TextStyle(color: p.title, fontWeight: FontWeight.w700, fontSize: 16))),
              Icon(expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: p.title),
            ]),
          ),
        ),
        if (expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: populated.isEmpty
                ? Text('Nenhuma informação registrada nesta seção.', style: TextStyle(color: p.muted))
                : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    for (final e in populated) _Field(p: p, label: e.key, value: e.value),
                  ]),
          ),
      ]),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.p, required this.label, required this.value});
  final _P p;
  final String label;
  final Object? value;

  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 8),
        _valueView(context),
      ]),
    );
  }

  Widget _valueView(BuildContext context) {
    final v = value;
    if (v is Map) {
      return Wrap(spacing: 8, runSpacing: 8, children: [
        for (final e in v.entries) _AnswerChip(p: p, label: _humanize(e.key.toString()), value: e.value),
      ]);
    }
    if (v is bool) return Wrap(children: [_AnswerChip(p: p, label: null, value: v)]);
    final text = v is List ? v.map((i) => i.toString()).join(', ') : v.toString().trim();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: p.field, border: Border.all(color: p.line), borderRadius: BorderRadius.circular(8)),
      child: SelectableText(text, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13.5, height: 1.45)),
    );
  }
}

class _AnswerChip extends StatelessWidget {
  const _AnswerChip({required this.p, required this.label, required this.value});
  final _P p;
  final String? label;
  final Object? value;

  @override
  Widget build(BuildContext context) {
    final yes = value == true;
    final text = value is bool ? (yes ? 'Sim' : 'Não') : (value?.toString() ?? 'Não informado');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: yes ? p.green.withValues(alpha: .12) : p.soft,
        border: Border.all(color: yes ? p.green.withValues(alpha: .5) : p.line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label == null ? text : '$label: $text', style: TextStyle(color: yes ? p.green : p.muted, fontSize: 12, fontWeight: yes ? FontWeight.w700 : FontWeight.w500)),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.p, required this.label});
  final _P p;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(color: p.card, border: Border.all(color: p.line), borderRadius: BorderRadius.circular(14)),
        child: Column(children: [
          Icon(Icons.hourglass_empty, size: 36, color: p.muted),
          const SizedBox(height: 10),
          Text('$label estará disponível nesta área em breve.', textAlign: TextAlign.center, style: TextStyle(color: p.muted)),
        ]),
      );
}

// ---------------------------------------------------------------------------
// Painel de decisão
// ---------------------------------------------------------------------------

class _DecisionPanel extends StatelessWidget {
  const _DecisionPanel({
    required this.p,
    required this.model,
    required this.status,
    required this.controller,
    required this.errorText,
    required this.onApprove,
    required this.onReturn,
    required this.onCancel,
    required this.onChanged,
  });
  final _P p;
  final ProfessorViewModel model;
  final String status;
  final TextEditingController controller;
  final String? errorText;
  final VoidCallback onApprove, onReturn, onCancel, onChanged;

  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).colorScheme.onSurface;
    final busy = model.isSubmittingDecision;
    const amber = Color(0xFFD97706);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: p.card, border: Border.all(color: p.line), borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: Text('Status da ficha', style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 16))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: p.yellowSoft, borderRadius: BorderRadius.circular(8)),
            child: Text(status, style: TextStyle(color: p.dark ? AppTheme.gold : const Color(0xFF8A5A00), fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 10),
        Text('Revise todas as informações e decida se a ficha pode ser aprovada ou se precisa de correções.', style: TextStyle(color: p.muted, fontSize: 13, height: 1.4)),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: p.soft, border: Border.all(color: p.line), borderRadius: BorderRadius.circular(10)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.info_outline, size: 20, color: p.title),
              const SizedBox(width: 8),
              Text('Dicas para revisão', style: TextStyle(color: p.title, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 8),
            for (final tip in const [
              'Verifique se todas as seções foram preenchidas corretamente',
              'Confira a coerência das informações',
              'Avalie o diagnóstico e plano propostos',
              'Deixe observações claras ao solicitar correções',
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('•  ', style: TextStyle(color: p.muted)),
                  Expanded(child: Text(tip, style: TextStyle(color: p.muted, fontSize: 12.5, height: 1.35))),
                ]),
              ),
          ]),
        ),
        const SizedBox(height: 18),
        Text.rich(TextSpan(children: [
          TextSpan(text: 'Observações para o aluno ', style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 13)),
          TextSpan(text: '(obrigatória ao devolver)', style: TextStyle(color: p.muted, fontSize: 12)),
        ])),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          minLines: 3,
          maxLines: 5,
          maxLength: 1000,
          onChanged: (_) => onChanged(),
          decoration: InputDecoration(
            hintText: 'Escreva suas observações e orientações para o aluno...',
            errorText: errorText,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 8),
        Text('Ações', style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 10),
        if (model.errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(model.errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13)),
          ),
        FilledButton.icon(
          onPressed: busy ? null : onApprove,
          icon: const Icon(Icons.check),
          label: const Text('Aprovar ficha'),
          style: FilledButton.styleFrom(backgroundColor: p.green, foregroundColor: Colors.white, minimumSize: const Size(0, 46)),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: busy ? null : onReturn,
          icon: const Icon(Icons.assignment_return_outlined),
          label: const Text('Devolver para correção'),
          style: OutlinedButton.styleFrom(
            foregroundColor: p.dark ? AppTheme.gold : const Color(0xFFB45309),
            backgroundColor: p.dark ? Colors.transparent : const Color(0xFFFFF7E0),
            side: const BorderSide(color: amber),
            minimumSize: const Size(0, 46),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: busy ? null : onCancel,
          style: OutlinedButton.styleFrom(foregroundColor: p.navy, side: BorderSide(color: p.line), minimumSize: const Size(0, 46)),
          child: const Text('Cancelar'),
        ),
        if (busy) const Padding(padding: EdgeInsets.only(top: 16), child: Center(child: CircularProgressIndicator())),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: p.soft, borderRadius: BorderRadius.circular(10)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.info_outline, size: 18, color: p.title),
            const SizedBox(width: 10),
            Expanded(child: Text('Ao aprovar, a ficha será finalizada e ficará disponível no prontuário do paciente.', style: TextStyle(color: p.muted, fontSize: 12.5, height: 1.4))),
          ]),
        ),
      ]),
    );
  }
}
