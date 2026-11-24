import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/professor_ficha_model.dart';
import '../../view_models/autenticacao_view_model.dart';
import '../../view_models/professor_view_model.dart';
import '../../widgets/botao_alternar_tema.dart';
import 'widgets/menu_lateral_professor.dart';
import '../autenticacao/entrar_view.dart';
import '../pacientes/buscar_paciente_view.dart';

part 'widgets/revisao_ficha_content.dart';
part 'widgets/painel_decisao_ficha.dart';

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
