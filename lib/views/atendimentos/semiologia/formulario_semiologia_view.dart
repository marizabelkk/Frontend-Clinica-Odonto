import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/atendimento_model.dart';
import '../../../models/ficha_semiologia_model.dart';
import '../../../models/odontograma_model.dart';
import '../../../models/paciente_model.dart';
import '../../../view_models/atendimento_view_model.dart';
import '../../../view_models/odontograma_view_model.dart';
import '../../../view_models/semiologia_view_model.dart';
import 'widgets/anexos_documentos_demo.dart';
import '../../../widgets/cabecalho_pagina_aluno.dart';
import '../../odontograma/odontograma_view.dart';
import '../revisao_ficha_aluno_view.dart';

part 'widgets/patient_header_card.dart';
part 'widgets/semiologia_navigation_sections.dart';

// ---------------------------------------------------------------------------
// Cores de apoio (apenas estética)
// ---------------------------------------------------------------------------

Color _heading(bool dark) => dark ? AppTheme.darkText : AppTheme.navy;
Color _link(bool dark) =>
    dark ? const Color(0xFF9DBBFF) : const Color(0xFF1D4ED8);
Color _softFill(bool dark) =>
    dark ? const Color(0xFF16304F) : const Color(0xFFE4ECFB);
Color _softBox(bool dark) =>
    dark ? const Color(0xFF12233A) : const Color(0xFFEEF3FC);
Color _lineColor(bool dark) =>
    dark ? const Color(0xFF263A56) : const Color(0xFFDCE4F2);
Color _surface(bool dark) => dark ? AppTheme.darkSurface : Colors.white;
Color _mutedColor(bool dark) =>
    dark ? const Color(0xFFB9C7DD) : const Color(0xFF52647E);

class FormularioSemiologiaView extends StatefulWidget {
  const FormularioSemiologiaView({
    required this.paciente,
    required this.atendimentoId,
    required this.ficha,
    this.readOnly = false,
    this.teacherComment,
    super.key,
  });

  final PacienteModel paciente;
  final int atendimentoId;
  final FichaSemiologiaModel ficha;
  final bool readOnly;
  final String? teacherComment;

  @override
  State<FormularioSemiologiaView> createState() =>
      _FormularioSemiologiaViewState();
}

class _FormularioSemiologiaViewState extends State<FormularioSemiologiaView> {
  final _formKey = GlobalKey<FormState>();
  bool _vitalsSaved = false;
  bool _isPreparingReview = false;
  final _queixaController = TextEditingController();
  final _historiaController = TextEditingController();
  final _antecedentesController = TextEditingController();
  final _medicamentosAlergiasController = TextEditingController();
  final _habitosHistoriaOdontologicaController = TextEditingController();
  final _observacoesController = TextEditingController();
  final _diagnosticoController = TextEditingController();
  final _planoController = TextEditingController();
  final _especialidadeEncaminhamentoController = TextEditingController();
  final _motivoEncaminhamentoController = TextEditingController();
  bool _necessitaEncaminhamento = false;
  bool get _canEdit =>
      !widget.readOnly &&
      (widget.ficha.status == StatusFicha.rascunho ||
          widget.ficha.status == StatusFicha.correcaoSolicitada);
  final Map<String, TextEditingController> _vitals = {
    'pressao_sistolica': TextEditingController(),
    'pressao_diastolica': TextEditingController(),
    'pulso': TextEditingController(),
    'frequencia_respiratoria': TextEditingController(),
    'temperatura': TextEditingController(),
    'peso': TextEditingController(),
    'altura': TextEditingController(),
    'glicemia': TextEditingController(),
  };

  // Apenas navegação visual entre as seções (indicador de etapas).
  int _activeStep = 0;
  final List<ExpansionTileController> _tiles = List.generate(
    10,
    (_) => ExpansionTileController(),
  );
  final List<GlobalKey> _sectionKeys = List.generate(10, (_) => GlobalKey());
  static const _stepSection = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
  static const _sectionStep = {
    1: 0,
    2: 1,
    3: 2,
    4: 3,
    5: 4,
    6: 5,
    7: 6,
    8: 7,
    9: 8,
    10: 9,
  };

  @override
  void initState() {
    super.initState();
    final draft = widget.ficha.semiologia;
    if (draft != null) {
      _queixaController.text = draft.queixaPrincipal ?? '';
      _historiaController.text = draft.historiaDoencaAtual ?? '';
      _antecedentesController.text = draft.antecedentesFamiliares ?? '';
      _medicamentosAlergiasController.text = draft.medicamentosAlergias ?? '';
      _habitosHistoriaOdontologicaController.text =
          draft.habitosHistoriaOdontologica ?? '';
      _observacoesController.text = draft.observacoesGerais ?? '';
      _diagnosticoController.text = draft.diagnostico ?? '';
      _planoController.text = draft.planoTratamento ?? '';
      _necessitaEncaminhamento = draft.necessitaEncaminhamento;
      _especialidadeEncaminhamentoController.text =
          draft.especialidadeEncaminhamentoId?.toString() ?? '';
      _motivoEncaminhamentoController.text = draft.motivoEncaminhamento ?? '';
    }
    if (widget.readOnly) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadVitalSigns());
    }
  }

  Future<void> _loadVitalSigns() async {
    try {
      final records = await context.read<AtendimentoViewModel>().listVitalSigns(
        widget.atendimentoId,
      );
      if (!mounted || records.isEmpty) return;
      final latest = records.last.toJson();
      for (final entry in latest.entries) {
        final controller = _vitals[entry.key];
        if (controller != null && entry.value != null) {
          controller.text = entry.value.toString();
        }
      }
      setState(() {});
    } catch (_) {
      // A ficha continua legível mesmo quando a API de sinais vitais falha.
    }
  }

  @override
  void dispose() {
    _queixaController.dispose();
    _historiaController.dispose();
    _antecedentesController.dispose();
    _medicamentosAlergiasController.dispose();
    _habitosHistoriaOdontologicaController.dispose();
    _observacoesController.dispose();
    _diagnosticoController.dispose();
    _planoController.dispose();
    _especialidadeEncaminhamentoController.dispose();
    _motivoEncaminhamentoController.dispose();
    for (final controller in _vitals.values) {
      controller.dispose();
    }
    super.dispose();
  }

  SinaisVitaisModel _vitalSigns() => SinaisVitaisModel(
    pressaoSistolica: _intValue('pressao_sistolica'),
    pressaoDiastolica: _intValue('pressao_diastolica'),
    pulso: _intValue('pulso'),
    frequenciaRespiratoria: _intValue('frequencia_respiratoria'),
    temperatura: _doubleValue('temperatura'),
    peso: _doubleValue('peso'),
    altura: _doubleValue('altura'),
    glicemia: _doubleValue('glicemia'),
  );

  int? _intValue(String key) {
    final value = _vitals[key]!.text.trim();
    return value.isEmpty ? null : int.tryParse(value);
  }

  double? _doubleValue(String key) {
    final value = _vitals[key]!.text.trim().replaceAll(',', '.');
    return value.isEmpty ? null : double.tryParse(value);
  }

  bool _vitalsValid() {
    for (final key in [
      'pressao_sistolica',
      'pressao_diastolica',
      'pulso',
      'frequencia_respiratoria',
    ]) {
      final value = _vitals[key]!.text.trim();
      if (value.isNotEmpty && int.tryParse(value) == null) return false;
    }
    for (final key in ['temperatura', 'peso', 'altura', 'glicemia']) {
      final value = _vitals[key]!.text.trim().replaceAll(',', '.');
      if (value.isNotEmpty && double.tryParse(value) == null) return false;
    }
    return true;
  }

  Future<bool> _saveVitalSigns(AtendimentoViewModel atendimento) async {
    if (_vitalsSaved) return true;
    if (_vitalSigns().toJson().isEmpty) return true;
    if (!_vitalsValid()) {
      _showMessage('Confira os valores numéricos dos sinais vitais.');
      return false;
    }
    final hasValues = _vitalSigns().toJson().isNotEmpty;
    final saved = await atendimento.saveVitalSigns(
      _vitalSigns(),
      atendimentoId: widget.atendimentoId,
    );
    if (saved && hasValues) _vitalsSaved = true;
    return saved;
  }

  SemiologiaDraftModel _draftFromForm() => SemiologiaDraftModel(
    queixaPrincipal: _queixaController.text.trim(),
    historiaDoencaAtual: _historiaController.text.trim(),
    antecedentesFamiliares: _antecedentesController.text.trim(),
    medicamentosAlergias: _medicamentosAlergiasController.text.trim(),
    habitosHistoriaOdontologica: _habitosHistoriaOdontologicaController.text
        .trim(),
    observacoesGerais: _observacoesController.text.trim(),
    diagnostico: _diagnosticoController.text.trim(),
    planoTratamento: _planoController.text.trim(),
    necessitaEncaminhamento: _necessitaEncaminhamento,
    especialidadeEncaminhamentoId: int.tryParse(
      _especialidadeEncaminhamentoController.text.trim(),
    ),
    motivoEncaminhamento: _motivoEncaminhamentoController.text.trim(),
  );

  Future<bool> _persistDraft() async {
    if (!_formKey.currentState!.validate()) return false;
    final atendimento = context.read<AtendimentoViewModel>();
    final vitalsSaved = await _saveVitalSigns(atendimento);
    if (!mounted || !vitalsSaved) return false;
    return context.read<SemiologiaViewModel>().saveDraft(
      fichaId: widget.ficha.id,
      currentStatus: widget.ficha.status,
      draft: _draftFromForm(),
    );
  }

  Future<void> _saveDraft() async {
    final success = await _persistDraft();
    if (success && mounted) _showMessage('Rascunho salvo.');
  }

  Future<void> _continueToReview() async {
    if (_isPreparingReview) return;
    setState(() => _isPreparingReview = true);
    try {
      final saved = await _persistDraft();
      if (!saved || !mounted) return;
      final odontograma = context.read<OdontogramaViewModel>();
      final prontuarioId =
          widget.paciente.prontuarioId ??
          context.read<AtendimentoViewModel>().activeProntuarioId;
      if (prontuarioId != null) {
        await odontograma.load(
          prontuarioId: prontuarioId,
          atendimentoId: widget.atendimentoId,
        );
      }
      if (!mounted) return;
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => RevisaoFichaAlunoView(
            paciente: widget.paciente,
            fichaId: widget.ficha.id,
            atendimentoId: widget.atendimentoId,
            fichaDescricao: 'Semiologia · Avaliação inicial',
            statusLabel: widget.ficha.status == StatusFicha.correcaoSolicitada
                ? 'Correção solicitada'
                : 'Rascunho',
            sections: _reviewSections(odontograma.registros, odontograma),
            onSubmit: _submitForApproval,
          ),
        ),
      );
      if (result == true && mounted) {
        _showMessage('Ficha enviada para aprovação.');
        Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) setState(() => _isPreparingReview = false);
    }
  }

  List<RevisaoFichaSecao> _reviewSections(
    List<OdontogramaRegistroModel> registros,
    OdontogramaViewModel odontograma,
  ) {
    String summary(Iterable<String> values) {
      final present = values.where((value) => value.trim().isNotEmpty).toList();
      return present.isEmpty
          ? 'Nenhuma informação preenchida.'
          : present.join(' • ');
    }

    final vitals = <String>[
      if (_vitals['pressao_sistolica']!.text.trim().isNotEmpty ||
          _vitals['pressao_diastolica']!.text.trim().isNotEmpty)
        'Pressão: ${_vitals['pressao_sistolica']!.text.trim()}/${_vitals['pressao_diastolica']!.text.trim()} mmHg',
      if (_vitals['pulso']!.text.trim().isNotEmpty)
        'Pulso: ${_vitals['pulso']!.text.trim()} bpm',
      if (_vitals['frequencia_respiratoria']!.text.trim().isNotEmpty)
        'Respiração: ${_vitals['frequencia_respiratoria']!.text.trim()} irpm',
      if (_vitals['temperatura']!.text.trim().isNotEmpty)
        'Temperatura: ${_vitals['temperatura']!.text.trim()} °C',
      if (_vitals['peso']!.text.trim().isNotEmpty)
        'Peso: ${_vitals['peso']!.text.trim()} kg',
      if (_vitals['altura']!.text.trim().isNotEmpty)
        'Altura: ${_vitals['altura']!.text.trim()} m',
      if (_vitals['glicemia']!.text.trim().isNotEmpty)
        'Glicemia: ${_vitals['glicemia']!.text.trim()} mg/dL',
    ];
    final odonto = registros.isEmpty
        ? 'Nenhuma condição registrada no odontograma.'
        : registros
              .map(
                (r) =>
                    'Dente ${r.numeroDente} · ${r.face.label} · ${odontograma.condicaoNome(r.condicaoId)}',
              )
              .join(' • ');
    final encaminhamento = _necessitaEncaminhamento
        ? 'Encaminhamento solicitado${_especialidadeEncaminhamentoController.text.trim().isNotEmpty ? ' · especialidade ${_especialidadeEncaminhamentoController.text.trim()}' : ''}${_motivoEncaminhamentoController.text.trim().isNotEmpty ? ' · ${_motivoEncaminhamentoController.text.trim()}' : ''}'
        : 'Sem encaminhamento solicitado.';
    return [
      RevisaoFichaSecao(
        title: 'Queixa principal e história da doença atual',
        summary: summary([_queixaController.text, _historiaController.text]),
        completed:
            _queixaController.text.trim().isNotEmpty ||
            _historiaController.text.trim().isNotEmpty,
      ),
      RevisaoFichaSecao(
        title: 'Histórico médico geral',
        summary: summary([_antecedentesController.text]),
        completed: _antecedentesController.text.trim().isNotEmpty,
      ),
      RevisaoFichaSecao(
        title: 'Medicamentos e alergias',
        summary: summary([_medicamentosAlergiasController.text]),
        completed: _medicamentosAlergiasController.text.trim().isNotEmpty,
      ),
      RevisaoFichaSecao(
        title: 'Hábitos e história odontológica',
        summary: summary([_habitosHistoriaOdontologicaController.text]),
        completed: _habitosHistoriaOdontologicaController.text
            .trim()
            .isNotEmpty,
      ),
      RevisaoFichaSecao(
        title: 'Exame físico e sinais vitais',
        summary: summary(vitals),
        completed: vitals.isNotEmpty,
      ),
      const RevisaoFichaSecao(
        title: 'Exame extraoral e intraoral',
        summary: 'Seção ainda não disponível para preenchimento.',
        completed: false,
      ),
      RevisaoFichaSecao(
        title: 'Odontograma',
        summary: odonto,
        completed: registros.isNotEmpty,
      ),
      const RevisaoFichaSecao(
        title: 'Exames complementares',
        summary: 'Anexos de demonstração não são enviados junto com a ficha.',
        completed: false,
      ),
      RevisaoFichaSecao(
        title: 'Diagnóstico, plano e encaminhamento',
        summary: summary([
          _diagnosticoController.text,
          _planoController.text,
          _necessitaEncaminhamento ? encaminhamento : '',
          _observacoesController.text,
        ]),
        completed:
            _diagnosticoController.text.trim().isNotEmpty ||
            _planoController.text.trim().isNotEmpty ||
            _necessitaEncaminhamento ||
            _observacoesController.text.trim().isNotEmpty,
      ),
      const RevisaoFichaSecao(
        title: 'Consentimento e assinatura',
        summary: 'Seção ainda não disponível para preenchimento.',
        completed: false,
      ),
    ];
  }

  Future<String?> _submitForApproval() async {
    final viewModel = context.read<SemiologiaViewModel>();
    final submitted = await viewModel.submit(
      fichaId: widget.ficha.id,
      currentStatus: widget.ficha.status,
    );
    if (submitted) return null;
    return viewModel.errorMessage ??
        'Não foi possível enviar a ficha para aprovação.';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _goToStep(int step) {
    final index = _stepSection[step] - 1;
    setState(() => _activeStep = step);
    _tiles[index].expand();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _sectionKeys[index].currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 300),
          alignment: .02,
        );
      }
    });
  }

  List<Widget> _odontogramaSection(BuildContext context) {
    final prontuarioId =
        widget.paciente.prontuarioId ??
        context.read<AtendimentoViewModel>().activeProntuarioId;
    final canEdit = _canEdit;
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (prontuarioId == null) {
      return const [
        Text('O prontuário deste paciente não foi retornado pela API.'),
      ];
    }
    return [
      const Text(
        'Marque no odontograma as condições de cada dente (cárie, fratura, restauração...).',
      ),
      const SizedBox(height: 12),
      FilledButton.icon(
        key: const Key('open-odontograma'),
        onPressed: () => Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => OdontogramaView(
              prontuarioId: prontuarioId,
              atendimentoId: widget.atendimentoId,
              canEdit: canEdit,
              pacienteNome: widget.paciente.nomeCompleto,
            ),
          ),
        ),
        icon: const Icon(Icons.grid_view_rounded),
        label: Text(canEdit ? 'Abrir odontograma' : 'Ver odontograma'),
        style: FilledButton.styleFrom(
          backgroundColor: dark ? AppTheme.gold : AppTheme.navy,
          foregroundColor: dark ? AppTheme.navy : Colors.white,
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    ];
  }

  _SectionCard _card(int number, String title, List<Widget> children) =>
      _SectionCard(
        number: '$number',
        title: title,
        controller: _tiles[number - 1],
        scrollKey: _sectionKeys[number - 1],
        onExpanded: () => setState(() => _activeStep = _sectionStep[number]!),
        children: children,
      );

  _PendingSection _pending(int number, String title) => _PendingSection(
    number: '$number',
    title: title,
    controller: _tiles[number - 1],
    scrollKey: _sectionKeys[number - 1],
    onExpanded: () => setState(() => _activeStep = _sectionStep[number]!),
  );

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: EstiloPaginaAluno.background(context),
      body: Theme(
        data: EstiloPaginaAluno.readableTheme(context),
        child: Container(
          color: AppTheme.navy,
          child: Column(
            children: [
              _CabecalhoFicha(
                title: _canEdit ? 'Ficha de Semiologia' : 'Visualizar ficha',
                subtitle: 'Semiologia (Avaliação inicial)',
                actions: _canEdit
                    ? [
                        TextButton.icon(
                          onPressed: _saveDraft,
                          icon: const Icon(
                            Icons.save_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                          label: const Text(
                            'Salvar rascunho',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                      ]
                    : const [],
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  child: Container(
                    color: EstiloPaginaAluno.background(context),
                    child: Column(
                      children: [
                        Expanded(
                          child: Form(
                            key: _formKey,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(16),
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 900,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _PatientHeaderCard(
                                        paciente: widget.paciente,
                                        atendimentoId: widget.atendimentoId,
                                        fichaId: widget.ficha.id,
                                      ),
                                      const SizedBox(height: 16),
                                      _Stepper(
                                        active: _activeStep,
                                        onTap: _goToStep,
                                      ),
                                      const SizedBox(height: 14),
                                      if (widget.teacherComment
                                              ?.trim()
                                              .isNotEmpty ==
                                          true) ...[
                                        Container(
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            color: dark
                                                ? const Color(0xFF3A1B24)
                                                : const Color(0xFFFFF1F0),
                                            border: Border.all(
                                              color: const Color(
                                                0xFFD92332,
                                              ).withValues(alpha: .35),
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Icon(
                                                Icons.rate_review_outlined,
                                                color: Color(0xFFD92332),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const Text(
                                                      'Observação do professor',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w800,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      widget.teacherComment!,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                      ],
                                      const SizedBox(height: 16),
                                      _card(
                                        1,
                                        'Queixa principal e história da doença atual',
                                        [
                                          _labeled(
                                            'Queixa principal',
                                            TextFormField(
                                              controller: _queixaController,
                                              readOnly: !_canEdit,
                                              maxLength: 200,
                                              maxLines: 3,
                                              decoration: _dec(
                                                hint:
                                                    'Descreva de forma resumida o motivo da consulta',
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          _labeled(
                                            'História da doença atual',
                                            TextFormField(
                                              controller: _historiaController,
                                              readOnly: !_canEdit,
                                              maxLength: 1000,
                                              maxLines: 5,
                                              decoration: _dec(
                                                hint:
                                                    'Descreva a história da doença atual e cronologia da queixa',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      _card(2, 'Histórico médico geral', [
                                        _basicTextField(
                                          _antecedentesController,
                                          'Antecedentes familiares',
                                        ),
                                      ]),
                                      const SizedBox(height: 12),
                                      _card(3, 'Medicamentos e alergias', [
                                        _clinicalTextField(
                                          _medicamentosAlergiasController,
                                          label:
                                              'Medicamentos em uso e alergias',
                                          hint:
                                              'Informe medicamentos, alergias, reações conhecidas e observações relevantes.',
                                        ),
                                      ]),
                                      const SizedBox(height: 12),
                                      _card(4, 'Hábitos e história odontológica', [
                                        _clinicalTextField(
                                          _habitosHistoriaOdontologicaController,
                                          label:
                                              'Descrição dos hábitos e do histórico',
                                          hint:
                                              'Descreva higiene bucal, frequência de consultas e tratamentos odontológicos anteriores.',
                                        ),
                                      ]),
                                      const SizedBox(height: 12),
                                      _card(5, 'Exame físico e sinais vitais', [
                                        const Text(
                                          'Os valores são associados ao atendimento atual. Data, horário e aluno responsável são registrados pelo backend.',
                                        ),
                                        const SizedBox(height: 14),
                                        _vitalInput(
                                          'pressao_sistolica',
                                          'Pressão sistólica',
                                          suffix: 'mmHg',
                                        ),
                                        _vitalInput(
                                          'pressao_diastolica',
                                          'Pressão diastólica',
                                          suffix: 'mmHg',
                                        ),
                                        _vitalInput(
                                          'pulso',
                                          'Pulso/frequência cardíaca',
                                          suffix: 'bpm',
                                        ),
                                        _vitalInput(
                                          'frequencia_respiratoria',
                                          'Frequência respiratória',
                                          suffix: 'irpm',
                                        ),
                                        _vitalInput(
                                          'temperatura',
                                          'Temperatura',
                                          suffix: '°C',
                                          decimal: true,
                                        ),
                                        _vitalInput(
                                          'peso',
                                          'Peso',
                                          suffix: 'kg',
                                          decimal: true,
                                        ),
                                        _vitalInput(
                                          'altura',
                                          'Altura',
                                          suffix: 'm',
                                          decimal: true,
                                        ),
                                        _vitalInput(
                                          'glicemia',
                                          'Glicemia capilar',
                                          suffix: 'mg/dL',
                                          decimal: true,
                                        ),
                                      ]),
                                      const SizedBox(height: 12),
                                      _pending(
                                        6,
                                        'Exame extraoral e intraoral',
                                      ),
                                      const SizedBox(height: 12),
                                      _card(
                                        7,
                                        'Odontograma',
                                        _odontogramaSection(context),
                                      ),
                                      const SizedBox(height: 12),
                                      _card(8, 'Exames complementares', const [
                                        AnexosDocumentosDemo(),
                                      ]),
                                      const SizedBox(height: 12),
                                      _card(
                                        9,
                                        'Diagnóstico, plano e encaminhamento',
                                        [
                                          _basicTextField(
                                            _diagnosticoController,
                                            'Diagnóstico',
                                          ),
                                          _basicTextField(
                                            _planoController,
                                            'Plano de tratamento',
                                          ),
                                          CheckboxListTile(
                                            contentPadding: EdgeInsets.zero,
                                            activeColor: dark
                                                ? AppTheme.gold
                                                : AppTheme.navy,
                                            checkColor: dark
                                                ? AppTheme.navy
                                                : Colors.white,
                                            controlAffinity:
                                                ListTileControlAffinity.leading,
                                            title: const Text(
                                              'Necessita encaminhamento',
                                            ),
                                            value: _necessitaEncaminhamento,
                                            onChanged: _canEdit
                                                ? (value) => setState(
                                                    () =>
                                                        _necessitaEncaminhamento =
                                                            value ?? false,
                                                  )
                                                : null,
                                          ),
                                          _labeled(
                                            'ID da especialidade de destino',
                                            TextFormField(
                                              controller:
                                                  _especialidadeEncaminhamentoController,
                                              readOnly: !_canEdit,
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: _dec(
                                                helper:
                                                    'Use o ID cadastrado no banco de dados.',
                                              ),
                                              validator: (value) {
                                                final text =
                                                    value?.trim() ?? '';
                                                return text.isEmpty ||
                                                        int.tryParse(text) !=
                                                            null
                                                    ? null
                                                    : 'Informe um ID numérico.';
                                              },
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          _basicTextField(
                                            _motivoEncaminhamentoController,
                                            'Motivo do encaminhamento',
                                          ),
                                          _basicTextField(
                                            _observacoesController,
                                            'Observações gerais',
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      _pending(
                                        10,
                                        'Consentimento e assinatura',
                                      ),
                                      const SizedBox(height: 12),
                                      Consumer2<
                                        AtendimentoViewModel,
                                        SemiologiaViewModel
                                      >(
                                        builder:
                                            (context, atendimento, ficha, _) {
                                              final error =
                                                  ficha.errorMessage ??
                                                  atendimento.errorMessage;
                                              if (error == null)
                                                return const SizedBox.shrink();
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 12,
                                                ),
                                                child: Text(
                                                  error,
                                                  style: TextStyle(
                                                    color: colors.error,
                                                  ),
                                                ),
                                              );
                                            },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        _bottomBar(context, dark),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomBar(BuildContext context, bool dark) {
    final accent = dark ? AppTheme.gold : AppTheme.navy;
    return Container(
      decoration: BoxDecoration(
        color: _surface(dark),
        border: Border(top: BorderSide(color: _lineColor(dark))),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back, size: 20),
                    label: const Text(
                      'Voltar',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: accent,
                      minimumSize: const Size.fromHeight(52),
                      side: BorderSide(color: accent, width: 1.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                if (_canEdit) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Consumer<SemiologiaViewModel>(
                      builder: (context, model, _) => ElevatedButton.icon(
                        onPressed: model.isSaving || _isPreparingReview
                            ? null
                            : _continueToReview,
                        icon: model.isSaving || _isPreparingReview
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: dark ? AppTheme.navy : Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.arrow_forward_rounded, size: 20),
                        label: const Text(
                          'Continuar',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: dark ? AppTheme.gold : AppTheme.navy,
                          foregroundColor: dark ? AppTheme.navy : Colors.white,
                          minimumSize: const Size.fromHeight(52),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Campos
  // -------------------------------------------------------------------------

  InputDecoration _dec({String? hint, String? suffix, String? helper}) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: color, width: width),
        );
    return InputDecoration(
      hintText: hint,
      helperText: helper,
      suffixText: suffix,
      hintStyle: TextStyle(
        color: _mutedColor(dark).withValues(alpha: .85),
        fontSize: 14,
      ),
      filled: true,
      fillColor: dark ? const Color(0xFF0D1B2E) : const Color(0xFFFAFBFE),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: border(_lineColor(dark)),
      disabledBorder: border(_lineColor(dark)),
      focusedBorder: border(_link(dark), 1.6),
      errorBorder: border(Theme.of(context).colorScheme.error),
      focusedErrorBorder: border(Theme.of(context).colorScheme.error, 1.6),
    );
  }

  Widget _labeled(String label, Widget field) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: _heading(dark),
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        field,
      ],
    );
  }

  Widget _vitalInput(
    String key,
    String label, {
    required String suffix,
    bool decimal = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: _labeled(
      label,
      TextFormField(
        controller: _vitals[key],
        onChanged: (_) => _vitalsSaved = false,
        readOnly: !_canEdit,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: _dec(suffix: suffix),
        validator: (value) {
          final text = value?.trim() ?? '';
          if (text.isEmpty) return null;
          final normalized = text.replaceAll(',', '.');
          final valid = decimal
              ? double.tryParse(normalized) != null
              : int.tryParse(normalized) != null;
          return valid ? null : 'Informe um valor numérico.';
        },
      ),
    ),
  );

  Widget _basicTextField(TextEditingController controller, String label) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: _labeled(
          label,
          TextFormField(
            controller: controller,
            readOnly: !_canEdit,
            maxLines: 3,
            decoration: _dec(),
          ),
        ),
      );

  Widget _clinicalTextField(
    TextEditingController controller, {
    required String label,
    required String hint,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: _labeled(
      label,
      TextFormField(
        controller: controller,
        readOnly: !_canEdit,
        minLines: 3,
        maxLines: 6,
        maxLength: 4000,
        decoration: _dec(hint: hint),
      ),
    ),
  );
}
