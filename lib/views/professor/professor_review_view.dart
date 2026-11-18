import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/professor_ficha_dto.dart';
import '../../data/viewmodels/professor_view_model.dart';
import '../widgets/theme_toggle_button.dart';

class ProfessorReviewView extends StatelessWidget {
  const ProfessorReviewView({super.key});

  Future<void> _decide(BuildContext context, DecisaoProfessor decision) async {
    final model = context.read<ProfessorViewModel>();
    String? observation;
    if (decision == DecisaoProfessor.correcaoSolicitada) {
      observation = await showDialog<String>(
        context: context,
        builder: (_) => const _CorrectionDialog(),
      );
      if (observation == null ||
          observation.trim().isEmpty ||
          !context.mounted) {
        return;
      }
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Aprovar ficha?'),
          content: const Text(
            'A ficha será finalizada conforme as regras do sistema.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Aprovar'),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
    }

    final success = await model.decide(
      decisao: decision,
      observacao: observation,
    );
    if (!context.mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            decision == DecisaoProfessor.aprovada
                ? 'Ficha aprovada.'
                : 'Correção solicitada.',
          ),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Revisão da ficha'),
        actions: const [ThemeToggleButton()],
      ),
      body: Consumer<ProfessorViewModel>(
        builder: (context, model, _) {
          final ficha = model.selected;
          if (ficha == null) {
            return Center(
              child: Text(model.errorMessage ?? 'Ficha indisponível.'),
            );
          }
          return LayoutBuilder(
            builder: (context, constraints) {
              final actions = _decisionPanel(context, model);
              final details = _FichaDataView(data: ficha.data);
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1280),
                    child: constraints.maxWidth >= 900
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 3, child: details),
                              const SizedBox(width: 16),
                              SizedBox(width: 340, child: actions),
                            ],
                          )
                        : Column(
                            children: [
                              details,
                              const SizedBox(height: 16),
                              actions,
                            ],
                          ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _decisionPanel(BuildContext context, ProfessorViewModel model) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Status da ficha',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(model.selected?.status ?? ''),
          const SizedBox(height: 16),
          if (model.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                model.errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          FilledButton.icon(
            onPressed: model.isSubmittingDecision
                ? null
                : () => _decide(context, DecisaoProfessor.aprovada),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Aprovar ficha'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: model.isSubmittingDecision
                ? null
                : () => _decide(context, DecisaoProfessor.correcaoSolicitada),
            icon: const Icon(Icons.assignment_return_outlined),
            label: const Text('Solicitar correção'),
          ),
          if (model.isSubmittingDecision)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    ),
  );
}

class _CorrectionDialog extends StatefulWidget {
  const _CorrectionDialog();

  @override
  State<_CorrectionDialog> createState() => _CorrectionDialogState();
}

class _CorrectionDialogState extends State<_CorrectionDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Solicitar correção'),
    content: TextField(
      controller: _controller,
      autofocus: true,
      minLines: 3,
      maxLines: 5,
      maxLength: 1000,
      decoration: InputDecoration(
        labelText: 'Observação para o aluno',
        errorText: _error,
        alignLabelWithHint: true,
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: () {
          final value = _controller.text.trim();
          if (value.isEmpty) {
            setState(() => _error = 'A observação é obrigatória.');
            return;
          }
          Navigator.pop(context, value);
        },
        child: const Text('Enviar correção'),
      ),
    ],
  );
}

class _FichaDataView extends StatelessWidget {
  const _FichaDataView({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final semiologia = _asMap(data['semiologia']);
    const knownFields = {
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
    final otherFields = {
      for (final entry in semiologia.entries)
        if (!knownFields.contains(entry.key)) _humanize(entry.key): entry.value,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resumo da ficha',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetadataChip(
                      label: 'Ficha',
                      value: '#${data['id'] ?? '—'}',
                    ),
                    _MetadataChip(
                      label: 'Atendimento',
                      value: '#${data['atendimento_id'] ?? '—'}',
                    ),
                    _MetadataChip(
                      label: 'Tipo',
                      value: data['tipo'] == 'SEMIOLOGIA'
                          ? 'Semiologia'
                          : _humanize(data['tipo']?.toString() ?? 'Ficha'),
                    ),
                    _MetadataChip(
                      label: 'Status',
                      value: _statusLabel(data['status']?.toString()),
                    ),
                    _MetadataChip(
                      label: 'Versão',
                      value: data['versao']?.toString() ?? '—',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _ReviewSection(
          title: 'Queixa e história atual',
          icon: Icons.chat_bubble_outline,
          fields: {
            'Queixa principal': semiologia['queixa_principal'],
            'História da doença atual': semiologia['historia_doenca_atual'],
          },
        ),
        _ReviewSection(
          title: 'Histórico médico, medicamentos e alergias',
          icon: Icons.medical_information_outlined,
          fields: {
            'Antecedentes familiares': semiologia['antecedentes_familiares'],
            'Medicamentos e alergias': semiologia['medicamentos_alergias'],
          },
        ),
        _ReviewSection(
          title: 'Hábitos e história odontológica',
          icon: Icons.health_and_safety_outlined,
          fields: {
            'Descrição registrada': semiologia['habitos_historia_odontologica'],
          },
        ),
        _ReviewSection(
          title: 'Diagnóstico e plano de tratamento',
          icon: Icons.fact_check_outlined,
          fields: {
            'Diagnóstico': semiologia['diagnostico'],
            'Plano de tratamento': semiologia['plano_tratamento'],
            'Necessita encaminhamento': semiologia['necessita_encaminhamento'],
            'Especialidade de destino (ID)':
                semiologia['especialidade_encaminhamento_id'],
            'Motivo do encaminhamento': semiologia['motivo_encaminhamento'],
          },
        ),
        _ReviewSection(
          title: 'Observações gerais',
          icon: Icons.notes_outlined,
          fields: {'Observações': semiologia['observacoes_gerais']},
        ),
        if (otherFields.isNotEmpty)
          _ReviewSection(
            title: 'Outras informações',
            icon: Icons.more_horiz,
            fields: otherFields,
          ),
      ],
    );
  }

  static Map<String, dynamic> _asMap(Object? value) => value is Map
      ? Map<String, dynamic>.from(value)
      : const <String, dynamic>{};

  static String _statusLabel(String? status) => switch (status) {
    'RASCUNHO' => 'Rascunho',
    'AGUARDANDO_APROVACAO' => 'Aguardando aprovação',
    'CORRECAO_SOLICITADA' => 'Correção solicitada',
    'APROVADA' => 'Aprovada',
    null || '' => 'Não informado',
    _ => _humanize(status),
  };

  static String _humanize(String value) => value
      .replaceAll('_', ' ')
      .split(' ')
      .where((word) => word.isNotEmpty)
      .map(
        (word) => '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
      )
      .join(' ');
}

class _MetadataChip extends StatelessWidget {
  const _MetadataChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) =>
      Chip(label: Text('$label: $value'), visualDensity: VisualDensity.compact);
}

class _ReviewSection extends StatelessWidget {
  const _ReviewSection({
    required this.title,
    required this.icon,
    required this.fields,
  });

  final String title;
  final IconData icon;
  final Map<String, dynamic> fields;

  @override
  Widget build(BuildContext context) {
    final populated = fields.entries.where((entry) {
      final value = entry.value;
      return value != null && (value is! String || value.trim().isNotEmpty);
    }).toList();
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: colors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (populated.isEmpty)
              Text(
                'Nenhuma informação registrada nesta seção.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              )
            else
              for (var index = 0; index < populated.length; index++) ...[
                if (index > 0) const Divider(height: 20),
                _ReviewField(
                  label: populated[index].key,
                  value: _format(populated[index].value),
                ),
              ],
          ],
        ),
      ),
    );
  }

  String _format(Object? value) {
    if (value == null) return 'Não informado';
    if (value is bool) return value ? 'Sim' : 'Não';
    if (value is List) return value.map((item) => item.toString()).join(', ');
    if (value is Map) {
      return value.entries
          .map(
            (entry) => '${_FichaDataView._humanize(entry.key)}: ${entry.value}',
          )
          .join('\n');
    }
    return value.toString().trim();
  }
}

class _ReviewField extends StatelessWidget {
  const _ReviewField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: 5),
      SelectableText(value),
    ],
  );
}
