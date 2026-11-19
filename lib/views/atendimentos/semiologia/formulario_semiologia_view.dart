import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/atendimento_model.dart';
import '../../../models/ficha_semiologia_model.dart';
import '../../../models/paciente_model.dart';
import '../../../view_models/atendimento_view_model.dart';
import '../../../view_models/semiologia_view_model.dart';
import '../../../widgets/atendimentos/anexos_documentos_demo.dart';
import '../../../widgets/cabecalho_pagina_aluno.dart';
import '../../odontograma/odontograma_view.dart';

// ---------------------------------------------------------------------------
// Cores de apoio (apenas estética)
// ---------------------------------------------------------------------------

Color _heading(bool dark) => dark ? AppTheme.darkText : AppTheme.navy;
Color _link(bool dark) => dark ? const Color(0xFF9DBBFF) : const Color(0xFF1D4ED8);
Color _softFill(bool dark) => dark ? const Color(0xFF16304F) : const Color(0xFFE4ECFB);
Color _softBox(bool dark) => dark ? const Color(0xFF12233A) : const Color(0xFFEEF3FC);
Color _lineColor(bool dark) => dark ? const Color(0xFF263A56) : const Color(0xFFDCE4F2);
Color _surface(bool dark) => dark ? AppTheme.darkSurface : Colors.white;
Color _mutedColor(bool dark) => dark ? const Color(0xFFB9C7DD) : const Color(0xFF52647E);

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
  State<FormularioSemiologiaView> createState() => _FormularioSemiologiaViewState();
}

class _FormularioSemiologiaViewState extends State<FormularioSemiologiaView> {
  final _formKey = GlobalKey<FormState>();
  bool _vitalsSaved = false;
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
  final List<ExpansionTileController> _tiles = List.generate(10, (_) => ExpansionTileController());
  final List<GlobalKey> _sectionKeys = List.generate(10, (_) => GlobalKey());
  static const _stepSection = [1, 2, 3, 4, 5, 8];
  static const _sectionStep = {1: 0, 2: 1, 3: 2, 4: 3, 5: 4, 6: 4, 7: 5, 8: 5, 9: 5, 10: 5};

  @override
  void initState() {
    super.initState();
    final draft = widget.ficha.semiologia;
    if (draft != null) {
      _queixaController.text = draft.queixaPrincipal ?? '';
      _historiaController.text = draft.historiaDoencaAtual ?? '';
      _antecedentesController.text = draft.antecedentesFamiliares ?? '';
      _medicamentosAlergiasController.text = draft.medicamentosAlergias ?? '';
      _habitosHistoriaOdontologicaController.text = draft.habitosHistoriaOdontologica ?? '';
      _observacoesController.text = draft.observacoesGerais ?? '';
      _diagnosticoController.text = draft.diagnostico ?? '';
      _planoController.text = draft.planoTratamento ?? '';
      _necessitaEncaminhamento = draft.necessitaEncaminhamento;
      _especialidadeEncaminhamentoController.text = draft.especialidadeEncaminhamentoId?.toString() ?? '';
      _motivoEncaminhamentoController.text = draft.motivoEncaminhamento ?? '';
    }
    if (widget.readOnly) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadVitalSigns());
    }
  }

  Future<void> _loadVitalSigns() async {
    try {
      final records = await context
          .read<AtendimentoViewModel>()
          .listVitalSigns(widget.atendimentoId);
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

  Future<void> _saveDraft() async {
    if (!_formKey.currentState!.validate()) return;
    final atendimento = context.read<AtendimentoViewModel>();
    final semiologia = context.read<SemiologiaViewModel>();
    final vitalsSaved = await _saveVitalSigns(atendimento);
    if (!mounted || !vitalsSaved) return;
    final success = await semiologia.saveDraft(
      fichaId: widget.ficha.id,
      currentStatus: widget.ficha.status,
      draft: SemiologiaDraftModel(
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
      ),
    );
    if (success && mounted) _showMessage('Rascunho salvo.');
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final atendimento = context.read<AtendimentoViewModel>();
    final viewModel = context.read<SemiologiaViewModel>();
    final vitalsSaved = await _saveVitalSigns(atendimento);
    if (!mounted || !vitalsSaved) return;
    final saved = await viewModel.saveDraft(
      fichaId: widget.ficha.id,
      currentStatus: widget.ficha.status,
      draft: SemiologiaDraftModel(
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
      ),
    );
    if (!saved || !mounted) return;
    final submitted = await viewModel.submit(
      fichaId: widget.ficha.id,
      currentStatus: widget.ficha.status,
    );
    if (submitted && mounted) {
      _showMessage('Ficha enviada para aprovação.');
      Navigator.of(context).pop(true);
    }
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
        Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300), alignment: .02);
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    ];
  }

  _SectionCard _card(int number, String title, List<Widget> children) => _SectionCard(
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
          child: Column(children: [
            _CabecalhoFicha(
              title: _canEdit ? 'Ficha de Semiologia' : 'Visualizar ficha',
              subtitle: 'Semiologia (Avaliação inicial)',
              actions: _canEdit
                  ? [
                      TextButton.icon(
                        onPressed: _saveDraft,
                        icon: const Icon(Icons.save_outlined, color: Colors.white, size: 20),
                        label: const Text('Salvar rascunho', style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600)),
                        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                      ),
                    ]
                  : const [],
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: Container(
                  color: EstiloPaginaAluno.background(context),
                  child: Column(children: [
                    Expanded(
                      child: Form(
                        key: _formKey,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 900),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                                _patientHeader(context),
                                const SizedBox(height: 16),
                                _Stepper(active: _activeStep, onTap: _goToStep),
                                const SizedBox(height: 14),
                                if (widget.teacherComment?.trim().isNotEmpty == true) ...[
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: dark ? const Color(0xFF3A1B24) : const Color(0xFFFFF1F0),
                                      border: Border.all(color: const Color(0xFFD92332).withValues(alpha: .35)),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      const Icon(Icons.rate_review_outlined, color: Color(0xFFD92332)),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                          const Text('Observação do professor', style: TextStyle(fontWeight: FontWeight.w800)),
                                          const SizedBox(height: 4),
                                          Text(widget.teacherComment!),
                                        ]),
                                      ),
                                    ]),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                const SizedBox(height: 16),
                                _card(1, 'Queixa principal e história da doença atual', [
                                  _labeled('Queixa principal',
                                    TextFormField(
                                      controller: _queixaController,
                                      readOnly: !_canEdit,
                                      maxLength: 200,
                                      maxLines: 3,
                                      decoration: _dec(hint: 'Descreva de forma resumida o motivo da consulta'),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _labeled('História da doença atual',
                                    TextFormField(
                                      controller: _historiaController,
                                      readOnly: !_canEdit,
                                      maxLength: 1000,
                                      maxLines: 5,
                                      decoration: _dec(hint: 'Descreva a história da doença atual e cronologia da queixa'),
                                    ),
                                  ),
                                ]),
                                const SizedBox(height: 12),
                                _card(2, 'Histórico médico geral', [
                                  _basicTextField(_antecedentesController, 'Antecedentes familiares'),
                                ]),
                                const SizedBox(height: 12),
                                _card(3, 'Medicamentos e alergias', [
                                  _clinicalTextField(
                                    _medicamentosAlergiasController,
                                    label: 'Medicamentos em uso e alergias',
                                    hint: 'Informe medicamentos, alergias, reações conhecidas e observações relevantes.',
                                  ),
                                ]),
                                const SizedBox(height: 12),
                                _card(4, 'Hábitos e história odontológica', [
                                  _clinicalTextField(
                                    _habitosHistoriaOdontologicaController,
                                    label: 'Descrição dos hábitos e do histórico',
                                    hint: 'Descreva higiene bucal, frequência de consultas e tratamentos odontológicos anteriores.',
                                  ),
                                ]),
                                const SizedBox(height: 12),
                                _card(5, 'Exame físico e sinais vitais', [
                                  const Text('Os valores são associados ao atendimento atual. Data, horário e aluno responsável são registrados pelo backend.'),
                                  const SizedBox(height: 14),
                                  _vitalInput('pressao_sistolica', 'Pressão sistólica', suffix: 'mmHg'),
                                  _vitalInput('pressao_diastolica', 'Pressão diastólica', suffix: 'mmHg'),
                                  _vitalInput('pulso', 'Pulso/frequência cardíaca', suffix: 'bpm'),
                                  _vitalInput('frequencia_respiratoria', 'Frequência respiratória', suffix: 'irpm'),
                                  _vitalInput('temperatura', 'Temperatura', suffix: '°C', decimal: true),
                                  _vitalInput('peso', 'Peso', suffix: 'kg', decimal: true),
                                  _vitalInput('altura', 'Altura', suffix: 'm', decimal: true),
                                  _vitalInput('glicemia', 'Glicemia capilar', suffix: 'mg/dL', decimal: true),
                                ]),
                                const SizedBox(height: 12),
                                _pending(6, 'Exame extraoral e intraoral'),
                                const SizedBox(height: 12),
                                _card(7, 'Odontograma', _odontogramaSection(context)),
                                const SizedBox(height: 12),
                                _card(8, 'Exames complementares', const [AnexosDocumentosDemo()]),
                                const SizedBox(height: 12),
                                _card(9, 'Diagnóstico, plano e encaminhamento', [
                                  _basicTextField(_diagnosticoController, 'Diagnóstico'),
                                  _basicTextField(_planoController, 'Plano de tratamento'),
                                  CheckboxListTile(
                                    contentPadding: EdgeInsets.zero,
                                    activeColor: dark ? AppTheme.gold : AppTheme.navy,
                                    checkColor: dark ? AppTheme.navy : Colors.white,
                                    controlAffinity: ListTileControlAffinity.leading,
                                    title: const Text('Necessita encaminhamento'),
                                    value: _necessitaEncaminhamento,
                                    onChanged: _canEdit
                                        ? (value) => setState(() => _necessitaEncaminhamento = value ?? false)
                                        : null,
                                  ),
                                  _labeled('ID da especialidade de destino',
                                    TextFormField(
                                      controller: _especialidadeEncaminhamentoController,
                                      readOnly: !_canEdit,
                                      keyboardType: TextInputType.number,
                                      decoration: _dec(helper: 'Use o ID cadastrado no banco de dados.'),
                                      validator: (value) {
                                        final text = value?.trim() ?? '';
                                        return text.isEmpty || int.tryParse(text) != null
                                            ? null
                                            : 'Informe um ID numérico.';
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _basicTextField(_motivoEncaminhamentoController, 'Motivo do encaminhamento'),
                                  _basicTextField(_observacoesController, 'Observações gerais'),
                                ]),
                                const SizedBox(height: 12),
                                _pending(10, 'Consentimento e assinatura'),
                                const SizedBox(height: 12),
                                Consumer2<AtendimentoViewModel, SemiologiaViewModel>(
                                  builder: (context, atendimento, ficha, _) {
                                    final error = ficha.errorMessage ?? atendimento.errorMessage;
                                    if (error == null) return const SizedBox.shrink();
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: Text(error, style: TextStyle(color: colors.error)),
                                    );
                                  },
                                ),
                              ]),
                            ),
                          ),
                        ),
                      ),
                    ),
                    _bottomBar(context, dark),
                  ]),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _bottomBar(BuildContext context, bool dark) {
    final accent = dark ? AppTheme.gold : AppTheme.navy;
    return Container(
      decoration: BoxDecoration(color: _surface(dark), border: Border(top: BorderSide(color: _lineColor(dark)))),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back, size: 20),
                  label: const Text('Voltar', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: accent,
                    minimumSize: const Size.fromHeight(52),
                    side: BorderSide(color: accent, width: 1.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              if (_canEdit) ...[
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Consumer<SemiologiaViewModel>(
                    builder: (context, model, _) => ElevatedButton.icon(
                      onPressed: model.isSaving ? null : _submit,
                      icon: model.isSaving
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: dark ? AppTheme.navy : Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.send_outlined, size: 20),
                      label: const Text('Enviar para aprovação', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: dark ? AppTheme.gold : AppTheme.navy,
                        foregroundColor: dark ? AppTheme.navy : Colors.white,
                        minimumSize: const Size.fromHeight(52),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
              ],
            ]),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Cartão do paciente
  // -------------------------------------------------------------------------

  Widget _patientHeader(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final p = widget.paciente;
    final info = [
      if (p.cpf != null) 'CPF: ${_maskCpf(p.cpf)}',
      if (p.dataNascimento != null) _formatBirth(p.dataNascimento),
      if (p.sexo != null) p.sexo!,
    ].join('   •   ');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface(dark),
        border: Border.all(color: _lineColor(dark)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: dark ? null : [BoxShadow(color: const Color(0xFF102B53).withValues(alpha: .05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: dark ? const Color(0xFF0A356D) : const Color(0xFFE4ECFB),
          foregroundColor: dark ? const Color(0xFFE3ECFC) : AppTheme.navy,
          child: Text(_initials(p.nomeCompleto), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.nomeCompleto ?? 'Paciente', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: _heading(dark), fontSize: 19, fontWeight: FontWeight.w800)),
            if (info.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(info, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: _mutedColor(dark), fontSize: 12.5)),
            ],
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.assignment_outlined, size: 18, color: _link(dark)),
              const SizedBox(width: 6),
              Flexible(
                child: Text('Atendimento: ${widget.atendimentoId} · Ficha: ${widget.ficha.id}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: _link(dark), fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }

  // -------------------------------------------------------------------------
  // Campos
  // -------------------------------------------------------------------------

  InputDecoration _dec({String? hint, String? suffix, String? helper}) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: color, width: width));
    return InputDecoration(
      hintText: hint,
      helperText: helper,
      suffixText: suffix,
      hintStyle: TextStyle(color: _mutedColor(dark).withValues(alpha: .85), fontSize: 14),
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
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: _heading(dark), fontWeight: FontWeight.w700, fontSize: 14)),
      const SizedBox(height: 8),
      field,
    ]);
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

// ---------------------------------------------------------------------------
// Cabeçalho azul-marinho
// ---------------------------------------------------------------------------

class _CabecalhoFicha extends StatelessWidget {
  const _CabecalhoFicha({required this.title, required this.subtitle, required this.actions});
  final String title;
  final String subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Container(
        color: AppTheme.navy,
        padding: const EdgeInsets.only(bottom: 14),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 110),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: .92), fontSize: 12.5)),
                  ]),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.chevron_left, size: 30),
                      label: const Text('Voltar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      style: TextButton.styleFrom(foregroundColor: Colors.white, padding: const EdgeInsets.only(left: 6, right: 8)),
                    ),
                    if (actions.isNotEmpty)
                      Row(mainAxisSize: MainAxisSize.min, children: actions),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}

// ---------------------------------------------------------------------------
// Indicador de etapas
// ---------------------------------------------------------------------------

class _Stepper extends StatelessWidget {
  const _Stepper({required this.active, required this.onTap});
  final int active;
  final ValueChanged<int> onTap;

  static const _labels = [
    'Queixa e História atual',
    'Histórico médico',
    'Medicamentos e alergias',
    'Hábitos e história odontológica',
    'Exame físico e clínico',
    'Exames, diagnóstico e encerramento',
  ];

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final navy = dark ? AppTheme.gold : AppTheme.navy;
    final line = _lineColor(dark);

    return LayoutBuilder(builder: (context, box) {
      final slot = math.max(box.maxWidth / 6, 60.0);
      final total = slot * 6;
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: total,
          child: Stack(children: [
            Positioned(top: 19, left: slot / 2, right: slot / 2, height: 2, child: ColoredBox(color: line)),
            Positioned(top: 19, left: slot / 2, width: (total - slot) * active / 5, height: 2, child: ColoredBox(color: navy)),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (var i = 0; i < _labels.length; i++)
                SizedBox(
                  width: slot,
                  child: InkWell(
                    onTap: () => onTap(i),
                    borderRadius: BorderRadius.circular(10),
                    child: Column(children: [
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == active ? navy : _surface(dark),
                          border: Border.all(color: i == active ? AppTheme.gold : (i < active ? navy : line), width: i == active ? 2.5 : 1.5),
                        ),
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            color: i == active ? (dark ? AppTheme.navy : Colors.white) : (i < active ? navy : _mutedColor(dark)),
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1),
                        child: Text(
                          _labels[i],
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          style: TextStyle(
                            color: i == active ? _heading(dark) : _mutedColor(dark),
                            fontSize: 10,
                            height: 1.2,
                            fontWeight: i == active ? FontWeight.w800 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
            ]),
          ]),
        ),
      );
    });
  }
}

// ---------------------------------------------------------------------------
// Cartões de seção
// ---------------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.number,
    required this.title,
    required this.children,
    this.controller,
    this.onExpanded,
    this.scrollKey,
  });

  final String number;
  final String title;
  final List<Widget> children;
  final ExpansionTileController? controller;
  final VoidCallback? onExpanded;
  final GlobalKey? scrollKey;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return KeyedSubtree(
      key: scrollKey,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: _surface(dark),
          border: Border.all(color: _lineColor(dark)),
          borderRadius: BorderRadius.circular(14),
          boxShadow: dark ? null : [BoxShadow(color: const Color(0xFF102B53).withValues(alpha: .04), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: ExpansionTile(
          controller: controller,
          initiallyExpanded: number == '1' || number == '5',
          onExpansionChanged: (open) {
            if (open) onExpanded?.call();
          },
          shape: const Border(),
          collapsedShape: const Border(),
          iconColor: _link(dark),
          collapsedIconColor: _link(dark),
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          leading: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: _softFill(dark), shape: BoxShape.circle),
            child: Text(number, style: TextStyle(color: dark ? AppTheme.darkText : AppTheme.navy, fontWeight: FontWeight.w800, fontSize: 16)),
          ),
          title: Text(title, style: TextStyle(color: _heading(dark), fontWeight: FontWeight.w700, fontSize: 16)),
          childrenPadding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

class _PendingSection extends StatelessWidget {
  const _PendingSection({
    required this.number,
    required this.title,
    this.controller,
    this.onExpanded,
    this.scrollKey,
  });

  final String number;
  final String title;
  final ExpansionTileController? controller;
  final VoidCallback? onExpanded;
  final GlobalKey? scrollKey;

  @override
  Widget build(BuildContext context) => _SectionCard(
    number: number,
    title: title,
    controller: controller,
    onExpanded: onExpanded,
    scrollKey: scrollKey,
    children: const [
      Text(
        'A implementação desta seção depende da definição do payload e dos endpoints correspondentes no contrato da API.',
      ),
    ],
  );
}

// ---------------------------------------------------------------------------
// Utilitários de formatação (apenas exibição)
// ---------------------------------------------------------------------------

String _initials(String? name) {
  final parts = (name ?? '').trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  return parts.take(2).map((part) => part[0].toUpperCase()).join();
}

String _maskCpf(String? cpf) {
  if (cpf == null || cpf.isEmpty) return 'Não informado';
  final digits = cpf.replaceAll(RegExp(r'\D'), '');
  if (digits.length != 11) return cpf;
  return '***.***.***-${digits.substring(9)}';
}

String _formatBirth(String? value) {
  if (value == null || value.isEmpty) return 'Nascimento não informado';
  final raw = value.trim();
  final americanDate = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(raw);
  final date = americanDate == null
      ? DateTime.tryParse(raw)
      : DateTime(
          int.parse(americanDate.group(3)!),
          int.parse(americanDate.group(1)!),
          int.parse(americanDate.group(2)!),
        );
  if (date == null) return value;
  final now = DateTime.now();
  final age = now.year - date.year - ((now.month < date.month || (now.month == date.month && now.day < date.day)) ? 1 : 0);
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ($age anos)';
}
