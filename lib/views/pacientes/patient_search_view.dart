import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/paciente_dto.dart';
import '../../data/viewmodels/patient_view_model.dart';
import '../prontuario/prontuario_view.dart';
import 'patient_create_view.dart';
import '../widgets/theme_toggle_button.dart';

class PatientSearchView extends StatefulWidget {
  const PatientSearchView({this.allowOpenRecord = true, super.key});

  final bool allowOpenRecord;

  @override
  State<PatientSearchView> createState() => _PatientSearchViewState();
}

class _PatientSearchViewState extends State<PatientSearchView> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<PatientViewModel>().loadPatients();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) {
        context.read<PatientViewModel>().loadPatients(query: value);
      }
    });
  }

  Future<void> _createPatient() async {
    final created = await Navigator.of(context).push<PacienteDto>(
      MaterialPageRoute<PacienteDto>(builder: (_) => const PatientCreateView()),
    );
    if (!mounted || created?.pacienteId == null) return;
    await context.read<PatientViewModel>().loadPatients(
      query: _searchController.text,
    );
    if (!mounted) return;
    if (widget.allowOpenRecord) {
      await _openRecord(created!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paciente cadastrado com sucesso.')),
      );
    }
  }

  Future<void> _openRecord(PacienteDto paciente) async {
    final id = paciente.pacienteId;
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O paciente não possui paciente_id.')),
      );
      return;
    }
    await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => ProntuarioView(
            pacienteId: id,
          ),
        ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar paciente'),
        actions: const [ThemeToggleButton()],
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: colors.primary,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: const Text(
              'Encontre um paciente cadastrado por nome ou CPF.',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          if (!widget.allowOpenRecord)
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'A recepção pode buscar e cadastrar pacientes. O prontuário clínico não é exibido nesta área.',
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Digite o nome ou CPF',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: 'Limpar busca',
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                  icon: const Icon(Icons.close),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              'Resultados da busca',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Expanded(
            child: Consumer<PatientViewModel>(
              builder: (context, model, _) {
                if (model.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (model.errorMessage != null) {
                  return _SearchMessage(
                    icon: Icons.cloud_off_outlined,
                    title: 'Não foi possível carregar os pacientes',
                    message: model.errorMessage!,
                    action: TextButton.icon(
                      onPressed: () =>
                          model.loadPatients(query: _searchController.text),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tentar novamente'),
                    ),
                  );
                }
                if (model.pacientes.isEmpty) {
                  return const _SearchMessage(
                    icon: Icons.person_search_outlined,
                    title: 'Nenhum paciente encontrado',
                    message: 'Verifique o nome ou CPF informado, ou cadastre um novo paciente.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: model.pacientes.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final paciente = model.pacientes[index];
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: colors.primary.withValues(
                            alpha: 0.1,
                          ),
                          foregroundColor: colors.primary,
                          child: Text(_initials(paciente.nomeCompleto)),
                        ),
                        title: Text(paciente.nomeCompleto ?? 'Paciente'),
                        subtitle: Text(
                          [
                            if (paciente.cpf != null) 'CPF: ${paciente.cpf}',
                            if (paciente.dataNascimento != null)
                              'Nascimento: ${paciente.dataNascimento}',
                            if (paciente.pacienteId != null)
                              'Código: ${paciente.pacienteId}',
                          ].join('\n'),
                        ),
                        isThreeLine: true,
                        trailing: widget.allowOpenRecord
                            ? const Icon(Icons.chevron_right)
                            : null,
                        onTap: widget.allowOpenRecord
                            ? () => _openRecord(paciente)
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: ElevatedButton.icon(
                onPressed: _createPatient,
                icon: const Icon(Icons.add),
                label: const Text('Cadastrar novo paciente'),
              ),
            ),
          ),
        ],
      ),
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

class _SearchMessage extends StatelessWidget {
  const _SearchMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 42, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center),
          if (action != null) ...[const SizedBox(height: 12), action!],
        ],
      ),
    ),
  );
}
