import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/usuario_dto.dart';
import '../../data/viewmodels/auth_view_model.dart';
import '../admin/admin_home_view.dart';
import '../pacientes/patient_search_view.dart';
import '../pacientes/reception_home_view.dart';
import '../professor/professor_home_view.dart';
import 'login_view.dart';
import '../widgets/theme_toggle_button.dart';

/// Routes authenticated users to the area allowed by their profile.
class ProfileLandingView extends StatelessWidget {
  const ProfileLandingView({required this.usuario, super.key});

  final UsuarioDto usuario;

  String get _title => switch (usuario.perfil) {
    PerfilUsuario.aluno => 'Área do aluno',
    PerfilUsuario.professor => 'Área do professor',
    PerfilUsuario.recepcao => 'Área da recepção',
    PerfilUsuario.admin => 'Perfil administrativo',
    PerfilUsuario.desconhecido => 'Perfil não reconhecido',
  };

  String get _message => switch (usuario.perfil) {
    PerfilUsuario.aluno => 'Acesse a busca de pacientes para consultar cadastros e iniciar um atendimento.',
    PerfilUsuario.professor =>
      'A área do professor será desenvolvida nas próximas etapas.',
    PerfilUsuario.recepcao => 'A recepção pode buscar e cadastrar pacientes.',
    PerfilUsuario.admin =>
      'O painel administrativo está fora do escopo do MVP.',
    PerfilUsuario.desconhecido =>
      'O perfil retornado pela API não está definido no contrato do MVP.',
  };

  @override
  Widget build(BuildContext context) {
    if (usuario.perfil == PerfilUsuario.professor) {
      return const ProfessorHomeView();
    }
    if (usuario.perfil == PerfilUsuario.recepcao) {
      return const ReceptionHomeView();
    }
    if (usuario.perfil == PerfilUsuario.admin) {
      return const AdminHomeView();
    }
    return Scaffold(
      appBar: AppBar(title: Text(_title), actions: const [ThemeToggleButton()]),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_user_outlined, size: 48),
                const SizedBox(height: 16),
                Text(
                  usuario.nome,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(_message, textAlign: TextAlign.center),
                if (usuario.perfil == PerfilUsuario.aluno) ...[
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => const PatientSearchView(),
                      ),
                    ),
                    icon: const Icon(Icons.search),
                    label: const Text('Buscar pacientes'),
                  ),
                ],
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () {
                    context.read<AuthViewModel>().logout();
                    Navigator.of(context).pushAndRemoveUntil<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => const LoginView(),
                      ),
                      (_) => false,
                    );
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Sair'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
