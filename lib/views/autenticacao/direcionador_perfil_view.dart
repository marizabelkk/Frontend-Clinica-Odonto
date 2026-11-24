import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/usuario_model.dart';
import '../../view_models/autenticacao_view_model.dart';
import '../administracao/inicio_administrador_view.dart';
import '../aluno/inicio_aluno_view.dart';
import '../recepcao/inicio_recepcao_view.dart';
import '../professor/inicio_professor_view.dart';
import 'perfil_nao_reconhecido_view.dart';
import 'entrar_view.dart';

/// Routes authenticated users to the area allowed by their profile.
class DirecionadorPerfilView extends StatelessWidget {
  const DirecionadorPerfilView({required this.usuario, super.key});

  final UsuarioModel usuario;

  @override
  Widget build(BuildContext context) {
    return switch (usuario.perfil) {
      PerfilUsuario.professor => const InicioProfessorView(),
      PerfilUsuario.recepcao => const InicioRecepcaoView(),
      PerfilUsuario.admin => const InicioAdministradorView(),
      PerfilUsuario.aluno => InicioAlunoView(
        usuario: usuario,
        onLogout: () => _logout(context),
      ),
      _ => PerfilNaoReconhecidoView(
        usuario: usuario,
        onLogout: () => _logout(context),
      ),
    };
  }
}

void _logout(BuildContext context) {
  context.read<AutenticacaoViewModel>().logout();
  Navigator.of(context).pushAndRemoveUntil<void>(
    MaterialPageRoute<void>(builder: (_) => const EntrarView()),
    (_) => false,
  );
}
