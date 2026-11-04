import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/professor_ficha_dto.dart';
import '../../data/viewmodels/professor_view_model.dart';

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
      appBar: AppBar(title: const Text('Revisão da ficha')),
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
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ficha preenchida',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          for (final entry in data.entries)
            if (entry.value != null)
              _DataEntry(label: _humanize(entry.key), value: entry.value),
        ],
      ),
    ),
  );

  String _humanize(String key) => key
      .replaceAll('_', ' ')
      .split(' ')
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
}

class _DataEntry extends StatelessWidget {
  const _DataEntry({required this.label, required this.value});

  final String label;
  final Object value;

  @override
  Widget build(BuildContext context) {
    if (value is Map) {
      final map = Map<String, dynamic>.from(value as Map);
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          children: [
            for (final entry in map.entries)
              _DataEntry(label: entry.key, value: entry.value ?? ''),
          ],
        ),
      );
    }
    final display = value is List
        ? (value as List).map((e) => e.toString()).join(', ')
        : value.toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          SelectableText(display),
        ],
      ),
    );
  }
}
