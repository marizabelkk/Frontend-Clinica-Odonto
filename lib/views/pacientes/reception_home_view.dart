import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/paciente_dto.dart';
import '../../data/repositories/demo_auth_repository.dart';
import '../../data/viewmodels/auth_view_model.dart';
import '../auth/login_view.dart';
import 'patient_create_view.dart';
import 'patient_search_view.dart';

class ReceptionHomeView extends StatelessWidget {
  const ReceptionHomeView({super.key});

  Future<void> _createPatient(BuildContext context) async {
    final created = await Navigator.of(context).push<PacienteDto>(
      MaterialPageRoute<PacienteDto>(builder: (_) => const PatientCreateView()),
    );
    if (!context.mounted || created == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const PatientSearchView(allowOpenRecord: false),
      ),
    );
  }

  void _logout(BuildContext context) {
    context.read<AuthViewModel>().logout();
    Navigator.of(context).pushAndRemoveUntil<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            LoginView(demoAuthEnabled: DemoAuthRepository.isEnabled),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().usuario;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recepção · Pacientes'),
        actions: [
          IconButton(
            tooltip: 'Sair',
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Olá, ${user?.nome ?? 'Recepção'}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Acesse o cadastro e a consulta de pacientes da clínica-escola.',
                ),
                const SizedBox(height: 24),
                _ReceptionAction(
                  icon: Icons.person_search_outlined,
                  title: 'Buscar pacientes',
                  description: 'Localize cadastros por nome ou CPF.',
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => const PatientSearchView(
                        allowOpenRecord: false,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _ReceptionAction(
                  icon: Icons.person_add_alt_1_outlined,
                  title: 'Cadastrar paciente',
                  description: 'Registre os dados cadastrais do paciente.',
                  onPressed: () => _createPatient(context),
                ),
                const SizedBox(height: 20),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'O perfil RECEPCAO é destinado ao fluxo de pacientes. A autorização final das operações continua sendo validada pela API.',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReceptionAction extends StatelessWidget {
  const _ReceptionAction({
    required this.icon,
    required this.title,
    required this.description,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.all(16),
      leading: CircleAvatar(child: Icon(icon)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(description),
      trailing: const Icon(Icons.chevron_right),
      onTap: onPressed,
    ),
  );
}
