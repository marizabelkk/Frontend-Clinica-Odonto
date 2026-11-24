import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/usuario_model.dart';
import '../../view_models/autenticacao_view_model.dart';
import '../../view_models/administracao_usuarios_view_model.dart';
import '../../widgets/botao_alternar_tema.dart';
import '../../widgets/cabecalho_pagina_aluno.dart';
import 'widgets/navegacao_inferior_coordenacao.dart';
import '../autenticacao/entrar_view.dart';

part 'widgets/admin_user_components.dart';
part 'widgets/usuario_form_dialog.dart';

class InicioAdministradorView extends StatefulWidget {
  const InicioAdministradorView({super.key});

  @override
  State<InicioAdministradorView> createState() =>
      _InicioAdministradorViewState();
}

class _InicioAdministradorViewState extends State<InicioAdministradorView> {
  PerfilUsuario? _perfilSelecionado;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _carregarUsuarios();
    });
  }

  Future<void> _carregarUsuarios() =>
      context.read<AdministracaoUsuariosViewModel>().loadUsers();

  Future<void> _alterarStatus(UsuarioModel usuario, bool ativo) async {
    final viewModel = context.read<AdministracaoUsuariosViewModel>();
    await viewModel.updateUserStatus(usuario.id, ativo: ativo);
    if (mounted) _showOperationFeedback(viewModel);
  }

  Future<void> _adicionarUsuario() async {
    final dados = await _abrirFormulario();
    if (dados == null || !mounted) return;
    final viewModel = context.read<AdministracaoUsuariosViewModel>();
    await viewModel.createUser(
      nome: dados.nome,
      email: dados.email,
      senha: dados.senha!,
      perfil: dados.perfil,
      matricula: dados.matricula,
    );
    if (mounted) _showOperationFeedback(viewModel);
  }

  Future<void> _editarUsuario(UsuarioModel usuario) async {
    final actorId = context.read<AutenticacaoViewModel>().usuario?.id;
    final dados = await _abrirFormulario(
      usuario: usuario,
      podeAlterarPerfil: actorId != usuario.id,
    );
    if (dados == null || !mounted) return;
    final viewModel = context.read<AdministracaoUsuariosViewModel>();
    await viewModel.updateUser(
      id: usuario.id,
      nome: dados.nome,
      email: dados.email,
      perfil: dados.perfil,
      matricula: dados.matricula,
      senha: dados.senha,
    );
    if (mounted) _showOperationFeedback(viewModel);
  }

  Future<_DadosUsuario?> _abrirFormulario({
    UsuarioModel? usuario,
    bool podeAlterarPerfil = true,
  }) => showDialog<_DadosUsuario>(
    context: context,
    builder: (_) => _UsuarioFormDialog(
      usuario: usuario,
      podeAlterarPerfil: podeAlterarPerfil,
    ),
  );

  Future<void> _excluirUsuario(UsuarioModel usuario) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir usuário'),
        content: Text(
          'Tem certeza que deseja excluir ${usuario.nome}? Essa ação não pode ser desfeita. Usuários com registros vinculados devem ser inativados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;
    final viewModel = context.read<AdministracaoUsuariosViewModel>();
    await viewModel.deleteUser(usuario.id);
    if (mounted) _showOperationFeedback(viewModel);
  }

  void _showOperationFeedback(AdministracaoUsuariosViewModel viewModel) {
    final message = viewModel.operationErrorMessage ?? viewModel.successMessage;
    if (message != null) _mensagem(message);
    viewModel.clearOperationFeedback();
  }

  void _mensagem(String texto) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(texto)));

  void _logout(BuildContext context) {
    context.read<AutenticacaoViewModel>().logout();
    Navigator.of(context).pushAndRemoveUntil<void>(
      MaterialPageRoute<void>(builder: (_) => const EntrarView()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AutenticacaoViewModel>().usuario;
    final adminViewModel = context.watch<AdministracaoUsuariosViewModel>();
    final nome = user?.nome.split(' ').first ?? 'Coordenação';
    final perfis = <(PerfilUsuario?, String)>[
      (null, 'Todos'),
      (PerfilUsuario.aluno, 'Alunos'),
      (PerfilUsuario.professor, 'Professores'),
      (PerfilUsuario.recepcao, 'Recepção'),
      (PerfilUsuario.admin, 'Coordenação'),
    ];

    return Scaffold(
      backgroundColor: EstiloPaginaAluno.background(context),
      body: Theme(
        data: EstiloPaginaAluno.readableTheme(context),
        child: Column(
          children: [
            _CabecalhoCoordenacao(
              nome: nome,
              onRefresh: _carregarUsuarios,
              onLogout: () => _logout(context),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 17, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Usuários',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${adminViewModel.usuarios.length} contas cadastradas',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: adminViewModel.isSaving
                            ? null
                            : _adicionarUsuario,
                        icon: const Icon(Icons.person_add_alt_1),
                        label: const Text('Adicionar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 13),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final (perfil, label) in perfis) ...[
                          ChoiceChip(
                            label: Text(label),
                            selected: _perfilSelecionado == perfil,
                            onSelected: (_) =>
                                setState(() => _perfilSelecionado = perfil),
                            selectedColor:
                                Theme.of(context).brightness == Brightness.dark
                                ? AppTheme.gold.withValues(alpha: .23)
                                : AppTheme.navy.withValues(alpha: .1),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildUserList(adminViewModel)),
          ],
        ),
      ),
      bottomNavigationBar: NavegacaoInferiorCoordenacao(
        currentIndex: 1,
        onDestinationSelected: (index) {
          if (index == 0) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
          if (index == 2) {
            _logout(context);
          }
        },
      ),
    );
  }

  List<UsuarioModel> _listaFiltrada(List<UsuarioModel> usuarios) => usuarios
      .where(
        (usuario) =>
            _perfilSelecionado == null || usuario.perfil == _perfilSelecionado,
      )
      .toList(growable: false);

  Widget _buildUserList(AdministracaoUsuariosViewModel viewModel) {
    final usuarios = _listaFiltrada(viewModel.usuarios);
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (viewModel.loadErrorMessage != null) {
      return _FeedbackState(
        message: viewModel.loadErrorMessage!,
        actionLabel: 'Tentar novamente',
        onAction: _carregarUsuarios,
      );
    }
    if (usuarios.isEmpty) {
      return const Center(child: Text('Nenhum usuário encontrado.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
      itemCount: usuarios.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final usuario = usuarios[index];
        return _UsuarioCard(
          usuario: usuario,
          icone: _iconePerfil(usuario.perfil),
          atualizando: viewModel.usuariosAtualizando.contains(usuario.id),
          onStatusChanged: (value) => _alterarStatus(usuario, value),
          onEdit: () => _editarUsuario(usuario),
          onDelete: () => _excluirUsuario(usuario),
        );
      },
    );
  }

  IconData _iconePerfil(PerfilUsuario perfil) => switch (perfil) {
    PerfilUsuario.aluno => Icons.school_outlined,
    PerfilUsuario.professor => Icons.person_outline,
    PerfilUsuario.recepcao => Icons.support_agent_outlined,
    PerfilUsuario.admin => Icons.admin_panel_settings_outlined,
    PerfilUsuario.desconhecido => Icons.person_outline,
  };
}
