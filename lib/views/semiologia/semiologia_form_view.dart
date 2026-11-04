import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/atendimento_dto.dart';
import '../../data/models/ficha_semiologia_dto.dart';
import '../../data/models/paciente_dto.dart';
import '../../data/viewmodels/atendimento_view_model.dart';
import '../../data/viewmodels/semiologia_view_model.dart';
import '../widgets/mock_document_attachments.dart';

class SemiologiaFormView extends StatefulWidget {
  const SemiologiaFormView({
    required this.paciente,
    required this.atendimentoId,
    required this.ficha,
    super.key,
  });

  final PacienteDto paciente;
  final int atendimentoId;
  final FichaSemiologiaDto ficha;

  @override
  State<SemiologiaFormView> createState() => _SemiologiaFormViewState();
}

class _SemiologiaFormViewState extends State<SemiologiaFormView> {
  final _formKey = GlobalKey<FormState>();
  bool _vitalsSaved = false;
  final _queixaController = TextEditingController();
  final _historiaController = TextEditingController();
  final _antecedentesController = TextEditingController();
  final _observacoesController = TextEditingController();
  final _diagnosticoController = TextEditingController();
  final _planoController = TextEditingController();
  final _especialidadeEncaminhamentoController = TextEditingController();
  final _motivoEncaminhamentoController = TextEditingController();
  bool _necessitaEncaminhamento = false;
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
  void dispose() {
    _queixaController.dispose();
    _historiaController.dispose();
    _antecedentesController.dispose();
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

  SinaisVitaisDto _vitalSigns() => SinaisVitaisDto(
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
    if (!_vitalsValid()) {
      _showMessage('Confira os valores numéricos dos sinais vitais.');
      return false;
    }
    final hasValues = _vitalSigns().toJson().isNotEmpty;
    final saved = await atendimento.saveVitalSigns(_vitalSigns());
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
      draft: SemiologiaDraftDto(
        queixaPrincipal: _queixaController.text.trim(),
        historiaDoencaAtual: _historiaController.text.trim(),
        antecedentesFamiliares: _antecedentesController.text.trim(),
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
      draft: SemiologiaDraftDto(
        queixaPrincipal: _queixaController.text.trim(),
        historiaDoencaAtual: _historiaController.text.trim(),
        antecedentesFamiliares: _antecedentesController.text.trim(),
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
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ficha de Semiologia'),
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: _saveDraft,
            icon: const Icon(Icons.save_outlined, color: Colors.white),
            label: const Text(
              'Salvar rascunho',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _patientHeader(context),
            const SizedBox(height: 16),
            Card(
              color: colors.surfaceContainerHighest,
              child: const Padding(
                padding: EdgeInsets.all(14),
                child: Text(
                  'Esta versão envia apenas os campos básicos acordados para o MVP. Campos clínicos estruturados, consentimento e assinatura dependem da expansão do contrato pelo backend.',
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
                const Text(
                  'Os endpoints e o payload completos de medicamentos e alergias ainda não estão definidos no contrato v2.',
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SectionCard(
              number: '4',
              title: 'Hábitos e história odontológica',
              children: [
                const Text(
                  'Os campos clínicos da seção aguardam a validação clínica e o payload da API.',
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
            const _PendingSection(number: '7', title: 'Odontograma'),
            const SizedBox(height: 12),
            _SectionCard(
              number: '8',
              title: 'Exames complementares',
              children: const [MockDocumentAttachments()],
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
                  onChanged: (value) => setState(
                    () => _necessitaEncaminhamento = value ?? false,
                  ),
                ),
                TextFormField(
                  controller: _especialidadeEncaminhamentoController,
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
            Consumer<SemiologiaViewModel>(
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
          maxLines: 3,
          decoration: InputDecoration(
            labelText: label,
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
