import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/paciente_dto.dart';
import '../../data/models/usuario_dto.dart';
import '../../data/viewmodels/patient_view_model.dart';
import '../../data/viewmodels/auth_view_model.dart';
import '../semiologia/atendimento_start_view.dart';

class ProntuarioView extends StatefulWidget {
  const ProntuarioView({
    required this.pacienteId,
    super.key,
  });

  final int pacienteId;

  @override
  State<ProntuarioView> createState() => _ProntuarioViewState();
}

class _ProntuarioViewState extends State<ProntuarioView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<PatientViewModel>().loadProntuario(widget.pacienteId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isStudent =
        context.watch<AuthViewModel>().perfil == PerfilUsuario.aluno;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prontuário do paciente'),
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer<PatientViewModel>(
        builder: (context, model, _) {
          if (model.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (model.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_outlined, size: 42),
                    const SizedBox(height: 12),
                    Text(model.errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () =>
                          model.loadProntuario(widget.pacienteId),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            );
          }

          final paciente = model.pacienteAtual;
          if (paciente == null) {
            return const Center(child: Text('Paciente não encontrado.'));
          }
          return _RecordContent(
            paciente: paciente,
            dados: model.prontuario?.resumo ?? const {},
            canStartAttendance: isStudent,
          );
        },
      ),
    );
  }
}

class _RecordContent extends StatelessWidget {
  const _RecordContent({
    required this.paciente,
    required this.dados,
    required this.canStartAttendance,
  });

  final PacienteDto paciente;
  final Map<String, dynamic> dados;
  final bool canStartAttendance;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: colors.primary.withValues(alpha: 0.1),
                      foregroundColor: colors.primary,
                      child: Text(_initials(paciente.nomeCompleto)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        paciente.nomeCompleto ?? 'Paciente',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (paciente.cpf != null)
                  _PatientFact(label: 'CPF', value: paciente.cpf!),
                if (paciente.rg != null)
                  _PatientFact(label: 'RG', value: paciente.rg!),
                if (paciente.dataNascimento != null)
                  _PatientFact(
                    label: 'Data de nascimento',
                    value: paciente.dataNascimento!,
                  ),
                if (paciente.sexo != null)
                  _PatientFact(label: 'Sexo/gênero', value: paciente.sexo!),
                if (paciente.celular != null)
                  _PatientFact(label: 'Celular', value: paciente.celular!),
                if (paciente.pacienteId != null)
                  _PatientFact(
                    label: 'Código do paciente',
                    value: paciente.pacienteId.toString(),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (canStartAttendance && paciente.prontuarioId != null)
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => AtendimentoStartView(
                  paciente: paciente,
                  prontuarioId: paciente.prontuarioId,
                ),
              ),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Novo atendimento'),
          )
        else if (canStartAttendance)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                'O prontuario_id deste paciente não foi retornado pela API; não é possível iniciar um atendimento.',
              ),
            ),
          ),
        const SizedBox(height: 18),
        Text(
          'Resumo do prontuário',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        if (dados.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Nenhum dado clínico compartilhado ou atendimento foi retornado para este prontuário.',
              ),
            ),
          )
        else
          ...dados.entries.map(
            (entry) => _RecordValue(label: entry.key, value: entry.value),
          ),
        const SizedBox(height: 12),
        const Text(
          'Dados exibidos carregados da API do prontuário.',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _initials(String? name) {
    final parts = (name ?? '').trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    return parts.length == 1
        ? parts.first.substring(0, 1).toUpperCase()
        : '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
              .toUpperCase();
  }
}

class _PatientFact extends StatelessWidget {
  const _PatientFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 150,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}

class _RecordValue extends StatelessWidget {
  const _RecordValue({required this.label, required this.value});

  final String label;
  final Object? value;

  @override
  Widget build(BuildContext context) {
    if (value is Map) {
      final entries = Map<String, dynamic>.from(value as Map);
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _humanize(label),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              ...entries.entries.map(
                (entry) => _RecordValue(label: entry.key, value: entry.value),
              ),
            ],
          ),
        ),
      );
    }
    if (value is List) {
      final items = value as List;
      if (items.isEmpty) return const SizedBox.shrink();
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _humanize(label),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              ...items.indexed.map(
                (item) => _RecordValue(
                  label: item.$2 is Map || item.$2 is List
                      ? '${_humanize(label)} ${item.$1 + 1}'
                      : '${_humanize(label)} ${item.$1 + 1}',
                  value: item.$2,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListTile(
      dense: true,
      title: Text(_humanize(label)),
      subtitle: Text(value?.toString() ?? '—'),
    );
  }

  String _humanize(String key) => key
      .replaceAll('_', ' ')
      .replaceAllMapped(RegExp(r'\b\w'), (match) => match[0]!.toUpperCase());
}
