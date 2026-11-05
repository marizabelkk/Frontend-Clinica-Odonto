import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/usuario_dto.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/viewmodels/auth_view_model.dart';
import '../auth/login_view.dart';

class AdminHomeView extends StatefulWidget {
  const AdminHomeView({super.key});

  @override
  State<AdminHomeView> createState() => _AdminHomeViewState();
}

class _AdminHomeViewState extends State<AdminHomeView> {
  PerfilUsuario? _perfilSelecionado;
  List<UsuarioDto> _usuarios = [];
  final Set<int> _usuariosAtualizando = {};
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarUsuarios();
  }

  Future<void> _carregarUsuarios() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final usuarios = await context
          .read<AuthViewModel>()
          .repository
          .listUsuarios();
      if (!mounted) return;
      setState(() {
        _usuarios = usuarios;
        _carregando = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _erro = AuthRepository.userMessageFor(error);
        _carregando = false;
      });
    }
  }

  Future<void> _alterarStatus(UsuarioDto usuario, bool ativo) async {
    setState(() => _usuariosAtualizando.add(usuario.id));
    try {
      final atualizado = await context
          .read<AuthViewModel>()
          .repository
          .updateUsuarioStatus(usuario.id, ativo: ativo);
      if (!mounted) return;
      setState(() {
        _usuarios = [
          for (final item in _usuarios)
            if (item.id == atualizado.id) atualizado else item,
        ];
        _usuariosAtualizando.remove(usuario.id);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _usuariosAtualizando.remove(usuario.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AuthRepository.userMessageFor(error))),
      );
    }
  }

  Future<void> _adicionarUsuario() async {
    final dados = await showDialog<_NovoUsuarioDados>(
      context: context,
      builder: (_) => const _NovoUsuarioDialog(),
    );
    if (dados == null) return;

    try {
      final usuario = await context
          .read<AuthViewModel>()
          .repository
          .createUsuario(
            nome: dados.nome,
            email: dados.email,
            senha: dados.senha,
            perfil: dados.perfil,
            matricula: dados.matricula,
          );
      if (!mounted) return;
      setState(() {
        _usuarios = [..._usuarios, usuario];
        _erro = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário cadastrado com sucesso.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AuthRepository.userMessageFor(error))),
      );
    }
  }

  void _logout(BuildContext context) {
    context.read<AuthViewModel>().logout();
    Navigator.of(context).pushAndRemoveUntil<void>(
      MaterialPageRoute<void>(builder: (_) => const LoginView()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final userName = context.select<AuthViewModel, String?>(
      (model) => model.usuario?.nome,
    );
    final List<(PerfilUsuario?, String)> perfis = [
      (null, 'Todos'),
      (PerfilUsuario.aluno, 'Alunos'),
      (PerfilUsuario.professor, 'Professores'),
      (PerfilUsuario.recepcao, 'Recepcao'),
      (PerfilUsuario.admin, 'Admin'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel da coordenacao'),
        actions: [
          IconButton(
            tooltip: 'Atualizar usuarios',
            onPressed: _carregarUsuarios,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Sair',
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _adicionarUsuario,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Adicionar usuário'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ola, ${userName ?? 'Coordenacao'}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                const Text('Gerencie os acessos de alunos e professores.'),
                const SizedBox(height: 18),
                Text('Usuarios', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Wrap(
                    spacing: 8,
                    children: [
                      for (final (perfil, label) in perfis)
                        ChoiceChip(
                          label: Text(label),
                          selected: _perfilSelecionado == perfil,
                          onSelected: (_) => setState(
                            () => _perfilSelecionado = perfil,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildUserList()),
        ],
      ),
    );
  }

  List<UsuarioDto> get _listaFiltrada => _usuarios
      .where(
        (usuario) =>
            _perfilSelecionado == null ||
            usuario.perfil == _perfilSelecionado,
      )
      .toList(growable: false);

  Widget _buildUserList() {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_erro != null) {
      return _FeedbackState(
        message: _erro!,
        actionLabel: 'Tentar novamente',
        onAction: _carregarUsuarios,
      );
    }
    if (_listaFiltrada.isEmpty) {
      return const Center(child: Text('Nenhum usuario encontrado.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      itemCount: _listaFiltrada.length,
      itemBuilder: (context, index) {
        final usuario = _listaFiltrada[index];
        final subtitle = usuario.perfil == PerfilUsuario.aluno
            ? 'Matricula: ' + (usuario.matricula ?? 'Nao informada')
            : usuario.email;
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              child: Icon(_iconePerfil(usuario.perfil)),
            ),
            title: Text(usuario.nome),
            subtitle: Text(subtitle),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(usuario.ativo ? 'Ativo' : 'Inativo'),
                Switch.adaptive(
                  value: usuario.ativo,
                  onChanged: _usuariosAtualizando.contains(usuario.id)
                      ? null
                      : (ativo) => _alterarStatus(usuario, ativo),
                ),
              ],
            ),
          ),
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

class _NovoUsuarioDados {
  const _NovoUsuarioDados({
    required this.nome,
    required this.email,
    required this.senha,
    required this.perfil,
    this.matricula,
  });

  final String nome;
  final String email;
  final String senha;
  final String? matricula;
  final PerfilUsuario perfil;
}

class _NovoUsuarioDialog extends StatefulWidget {
  const _NovoUsuarioDialog();

  @override
  State<_NovoUsuarioDialog> createState() => _NovoUsuarioDialogState();
}

class _NovoUsuarioDialogState extends State<_NovoUsuarioDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _matriculaController = TextEditingController();
  PerfilUsuario _perfil = PerfilUsuario.aluno;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _matriculaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Adicionar usuário'),
    content: Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nomeController,
              decoration: const InputDecoration(labelText: 'Nome'),
              textCapitalization: TextCapitalization.words,
              validator: _obrigatorio,
            ),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'E-mail'),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Informe o e-mail.';
                }
                if (!value.contains('@')) return 'Informe um e-mail válido.';
                return null;
              },
            ),
            TextFormField(
              controller: _senhaController,
              decoration: const InputDecoration(labelText: 'Senha'),
              obscureText: true,
              validator: (value) => (value == null || value.length < 8)
                  ? 'Use pelo menos 8 caracteres.'
                  : null,
            ),
            TextFormField(
              controller: _matriculaController,
              decoration: const InputDecoration(
                labelText: 'Matrícula (opcional)',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<PerfilUsuario>(
              value: _perfil,
              decoration: const InputDecoration(labelText: 'Perfil'),
              items: const [
                DropdownMenuItem(
                  value: PerfilUsuario.aluno,
                  child: Text('Aluno'),
                ),
                DropdownMenuItem(
                  value: PerfilUsuario.professor,
                  child: Text('Professor'),
                ),
                DropdownMenuItem(
                  value: PerfilUsuario.recepcao,
                  child: Text('Recepção'),
                ),
                DropdownMenuItem(
                  value: PerfilUsuario.admin,
                  child: Text('Admin'),
                ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _perfil = value);
              },
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: _salvar,
        child: const Text('Cadastrar'),
      ),
    ],
  );

  String? _obrigatorio(String? value) =>
      value == null || value.trim().isEmpty ? 'Campo obrigatório.' : null;

  void _salvar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _NovoUsuarioDados(
        nome: _nomeController.text.trim(),
        email: _emailController.text.trim(),
        senha: _senhaController.text,
        perfil: _perfil,
        matricula: _matriculaController.text.trim().isEmpty
            ? null
            : _matriculaController.text.trim(),
      ),
    );
  }
}

class _FeedbackState extends StatelessWidget {
  const _FeedbackState({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    ),
  );
}
