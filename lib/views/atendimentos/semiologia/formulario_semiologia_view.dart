import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/atendimento_model.dart';
import '../../../models/ficha_semiologia_model.dart';
import '../../../models/paciente_model.dart';
import '../../../view_models/atendimento_view_model.dart';
import '../../../view_models/semiologia_view_model.dart';
import '../../../widgets/atendimentos/anexos_documentos_demo.dart';
import '../../../widgets/cabecalho_pagina_aluno.dart';
import '../../odontograma/odontograma_view.dart';

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

  List<Widget> _odontogramaSection(BuildContext context) {
    final prontuarioId =
        widget.paciente.prontuarioId ??
        context.read<AtendimentoViewModel>().activeProntuarioId;
    final canEdit = _canEdit;
    if (prontuarioId == null) {
      return const [
        Text('O prontuário deste paciente não foi retornado pela API.'),
      ];
    }
    return [
      const Text(
        'Marque no odontograma os defeitos de cada dente (cárie, fratura, restauração...).',
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
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: EstiloPaginaAluno.background(context),
      body: Theme(
        data: EstiloPaginaAluno.readableTheme(context),
        child: Column(children: [
          CabecalhoPaginaAluno(
            title: _canEdit ? 'Ficha de Semiologia' : 'Visualizar ficha',
            subtitle: 'Avaliação inicial · ${widget.paciente.nomeCompleto ?? 'Paciente'}',
            actions: _canEdit ? [
              TextButton.icon(
            onPressed: _saveDraft,
            icon: const Icon(Icons.save_outlined, color: Colors.white, size: 19),
            label: const Text(
              'Salvar rascunho',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
            ] : const [],
          ),
          Expanded(child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _patientHeader(context),
            const SizedBox(height: 16),
            if (widget.teacherComment?.trim().isNotEmpty == true) ...[
              Card(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF3A1B24)
                    : const Color(0xFFFFF1F0),
                child: ListTile(
                  leading: const Icon(
                    Icons.rate_review_outlined,
                    color: Color(0xFFD92332),
                  ),
                  title: const Text('Observação do professor'),
                  subtitle: Text(widget.teacherComment!),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Card(
              color: colors.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  _canEdit
                      ? 'O rascunho salva os campos disponíveis nesta ficha. Consentimento e assinatura ainda não fazem parte do fluxo.'
                      : 'Ficha em modo de visualização. Os campos estão bloqueados para edição.',
                ),
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              number: '1',
              title: 'Queixa principal e história da doença atual',
              children: [
                TextFormField(
                  controller: _queixaController,
                  readOnly: !_canEdit,
                  maxLength: 200,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Queixa principal',
                    hintText: 'Descreva o motivo da consulta',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _historiaController,
                  readOnly: !_canEdit,
                  maxLength: 1000,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'História da doença atual',
                    hintText: 'Descreva a história e cronologia da queixa',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SectionCard(
              number: '2',
              title: 'Histórico médico geral',
              children: [
                _basicTextField(
                  _antecedentesController,
                  'Antecedentes familiares',
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SectionCard(
              number: '3',
              title: 'Medicamentos e alergias',
              children: [
                _clinicalTextField(
                  _medicamentosAlergiasController,
                  label: 'Medicamentos em uso e alergias',
                  hint:
                      'Informe medicamentos, alergias, reações conhecidas e observações relevantes.',
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SectionCard(
              number: '4',
              title: 'Hábitos e história odontológica',
              children: [
                _clinicalTextField(
                  _habitosHistoriaOdontologicaController,
                  label: 'Descrição dos hábitos e do histórico',
                  hint:
                      'Descreva higiene bucal, frequência de consultas e tratamentos odontológicos anteriores.',
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SectionCard(
              number: '5',
              title: 'Avaliação física e sinais vitais',
              children: [
                const Text(
                  'Os valores são associados ao atendimento atual. Data, horário e aluno responsável são registrados pelo backend.',
                ),
                const SizedBox(height: 12),
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
                _vitalInput('peso', 'Peso', suffix: 'kg', decimal: true),
                _vitalInput('altura', 'Altura', suffix: 'm', decimal: true),
                _vitalInput(
                  'glicemia',
                  'Glicemia capilar',
                  suffix: 'mg/dL',
                  decimal: true,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const _PendingSection(
              number: '6',
              title: 'Exame extraoral e intraoral',
            ),
            const SizedBox(height: 12),
            _SectionCard(
              number: '7',
              title: 'Odontograma',
              children: _odontogramaSection(context),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              number: '8',
              title: 'Exames complementares',
              children: const [AnexosDocumentosDemo()],
            ),
            const SizedBox(height: 12),
            _SectionCard(
              number: '9',
              title: 'Diagnóstico, plano e encaminhamento',
              children: [
                _basicTextField(_diagnosticoController, 'Diagnóstico'),
                _basicTextField(_planoController, 'Plano de tratamento'),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Necessita encaminhamento'),
                  value: _necessitaEncaminhamento,
                  onChanged: _canEdit
                      ? (value) => setState(() => _necessitaEncaminhamento = value ?? false)
                      : null,
                ),
                TextFormField(
                  controller: _especialidadeEncaminhamentoController,
                  readOnly: !_canEdit,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'ID da especialidade de destino',
                    helperText: 'Use o ID cadastrado no banco de dados.',
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    return text.isEmpty || int.tryParse(text) != null
                        ? null
                        : 'Informe um ID numérico.';
                  },
                ),
                const SizedBox(height: 12),
                _basicTextField(
                  _motivoEncaminhamentoController,
                  'Motivo do encaminhamento',
                ),
                _basicTextField(_observacoesController, 'Observações gerais'),
              ],
            ),
            const SizedBox(height: 12),
            const _PendingSection(
              number: '10',
              title: 'Consentimento e assinatura',
            ),
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
            if (_canEdit) Consumer<SemiologiaViewModel>(
              builder: (context, model, _) => ElevatedButton.icon(
                onPressed: model.isSaving ? null : _submit,
                icon: model.isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.send_outlined),
                label: const Text('Enviar para aprovação'),
              ),
            ),
          ],
        ),
          )),
        ]),
      ),
    );
  }

  Widget _patientHeader(BuildContext context) => Card(
    child: ListTile(
      leading: const CircleAvatar(child: Icon(Icons.person_outline)),
      title: Text(widget.paciente.nomeCompleto ?? 'Paciente'),
      subtitle: Text(
        [
          if (widget.paciente.cpf != null) 'CPF: ${widget.paciente.cpf}',
          'Atendimento: ${widget.atendimentoId} · Ficha: ${widget.ficha.id}',
        ].join('\n'),
      ),
    ),
  );

  Widget _vitalInput(
    String key,
    String label, {
    required String suffix,
    bool decimal = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: _vitals[key],
      readOnly: !_canEdit,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label, suffixText: suffix),
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
  );

  Widget _basicTextField(TextEditingController controller, String label) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: controller,
          readOnly: !_canEdit,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: label,
            alignLabelWithHint: true,
          ),
        ),
      );

  Widget _clinicalTextField(
    TextEditingController controller, {
    required String label,
    required String hint,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      readOnly: !_canEdit,
      minLines: 3,
      maxLines: 6,
      maxLength: 4000,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        alignLabelWithHint: true,
      ),
    ),
  );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.number,
    required this.title,
    required this.children,
  });

  final String number;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    child: ExpansionTile(
      initiallyExpanded: number == '1' || number == '5',
      leading: CircleAvatar(child: Text(number)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: children,
    ),
  );
}

class _PendingSection extends StatelessWidget {
  const _PendingSection({required this.number, required this.title});

  final String number;
  final String title;

  @override
  Widget build(BuildContext context) => _SectionCard(
    number: number,
    title: title,
    children: const [
      Text(
        'A implementação desta seção depende da definição do payload e dos endpoints correspondentes no contrato da API.',
      ),
    ],
  );
}
