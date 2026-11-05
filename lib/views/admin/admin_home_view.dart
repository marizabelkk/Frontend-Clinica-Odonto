import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/admin_user_demo_dto.dart';
import '../../data/models/usuario_dto.dart';
import '../../data/viewmodels/admin_view_model.dart';
import '../../data/viewmodels/auth_view_model.dart';
import '../auth/login_view.dart';

class AdminHomeView extends StatefulWidget {
  const AdminHomeView({required this.demoMode, super.key});

  final bool demoMode;

  @override
  State<AdminHomeView> createState() => _AdminHomeViewState();
}

class _AdminHomeViewState extends State<AdminHomeView> {
  @override
  void initState() {
    super.initState();
    if (widget.demoMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<AdminViewModel>().loadUsers();
      });
    }
  }

  void _logout() {
    context.read<AuthViewModel>().logout();
    Navigator.of(context).pushAndRemoveUntil<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            const LoginView(),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().usuario;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel da coordenação'),
        actions: [
          IconButton(
            tooltip: 'Sair',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Olá, ${user?.nome ?? 'Coordenação'}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          const Text('Gerencie os acessos de alunos e professores.'),
          const SizedBox(height: 18),
          Card(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                widget.demoMode
                    ? 'Protótipo local: alterações de acesso são fictícias, ficam apenas na memória e não afetam contas reais.'
                    : 'O Contrato API v2 ainda não define endpoints para listar usuários nem ativar/desativar acessos. Esta gestão aguarda a ampliação do contrato e do backend.',
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text('Usuários', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (!widget.demoMode)
            const Card(
              child: ListTile(
                leading: Icon(Icons.pending_actions_outlined),
                title: Text('Integração de gestão pendente'),
                subtitle: Text(
                  'A API v2 documenta apenas o cadastro administrativo de usuário (POST /usuarios). A listagem e alteração de status ainda não estão especificadas.',
                ),
              ),
            )
          else
            Consumer<AdminViewModel>(
              builder: (context, model, _) {
                if (model.isLoading && model.users.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                return Column(
                  children: model.users
                      .map((user) => _AdminUserTile(user: user))
                      .toList(),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _AdminUserTile extends StatelessWidget {
  const _AdminUserTile({required this.user});

  final AdminUserDemoDto user;

  @override
  Widget build(BuildContext context) => Card(
    child: SwitchListTile(
      secondary: CircleAvatar(
        child: Icon(switch (user.perfil) {
          PerfilUsuario.aluno => Icons.school_outlined,
          PerfilUsuario.professor => Icons.co_present_outlined,
          PerfilUsuario.recepcao => Icons.support_agent_outlined,
          _ => Icons.person_outline,
        }),
      ),
      title: Text(user.nome),
      subtitle: Text(
        [
          user.email,
          user.perfil.apiValue,
          if (user.matricula != null) 'Matrícula: ${user.matricula}',
          if (user.observacao != null) user.observacao!,
        ].join('\n'),
      ),
      isThreeLine: true,
      value: user.ativo,
      onChanged: (active) =>
          context.read<AdminViewModel>().setActive(user.id, active),
      activeThumbColor: Theme.of(context).colorScheme.primary,
    ),
  );
}
