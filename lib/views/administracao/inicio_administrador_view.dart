import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/usuario_model.dart';
import '../../services/repositories/autenticacao_repository.dart';
import '../../view_models/autenticacao_view_model.dart';
import '../../widgets/botao_alternar_tema.dart';
import '../../widgets/cabecalho_pagina_aluno.dart';
import '../../widgets/navegacao_inferior_coordenacao.dart';
import '../autenticacao/entrar_view.dart';

class InicioAdministradorView extends StatefulWidget {
  const InicioAdministradorView({super.key});

  @override
  State<InicioAdministradorView> createState() =>
      _InicioAdministradorViewState();
}

class _InicioAdministradorViewState extends State<InicioAdministradorView> {
  PerfilUsuario? _perfilSelecionado;
  List<UsuarioModel> _usuarios = [];
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
          .read<AutenticacaoViewModel>()
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
        _erro = AutenticacaoRepository.userMessageFor(error);
        _carregando = false;
      });
    }
  }

  Future<void> _alterarStatus(UsuarioModel usuario, bool ativo) async {
    setState(() => _usuariosAtualizando.add(usuario.id));
    try {
      final atualizado = await context
          .read<AutenticacaoViewModel>()
          .repository
          .updateUsuarioStatus(usuario.id, ativo: ativo);
      if (!mounted) return;
      _substituirUsuario(atualizado);
    } catch (error) {
      if (!mounted) return;
      setState(() => _usuariosAtualizando.remove(usuario.id));
      _mensagem(AutenticacaoRepository.userMessageFor(error));
    }
  }

  Future<void> _adicionarUsuario() async {
    final repository = context.read<AutenticacaoViewModel>().repository;
    final dados = await _abrirFormulario();
    if (dados == null || !mounted) return;
    try {
      final usuario = await repository.createUsuario(
        nome: dados.nome,
        email: dados.email,
        senha: dados.senha!,
        perfil: dados.perfil,
        matricula: dados.matricula,
      );
      if (!mounted) return;
      setState(() {
        _usuarios = [..._usuarios, usuario];
        _erro = null;
      });
      _mensagem('Usuário cadastrado com sucesso.');
    } catch (error) {
      if (mounted) _mensagem(AutenticacaoRepository.userMessageFor(error));
    }
  }

  Future<void> _editarUsuario(UsuarioModel usuario) async {
    final repository = context.read<AutenticacaoViewModel>().repository;
    final actorId = context.read<AutenticacaoViewModel>().usuario?.id;
    final dados = await _abrirFormulario(
      usuario: usuario,
      podeAlterarPerfil: actorId != usuario.id,
    );
    if (dados == null || !mounted) return;
    try {
      final atualizado = await repository.updateUsuario(
        usuario.id,
        nome: dados.nome,
        email: dados.email,
        perfil: dados.perfil,
        matricula: dados.matricula,
        senha: dados.senha,
      );
      if (!mounted) return;
      _substituirUsuario(atualizado);
      _mensagem('Dados do usuário atualizados.');
    } catch (error) {
      if (mounted) _mensagem(AutenticacaoRepository.userMessageFor(error));
    }
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
    try {
      await context.read<AutenticacaoViewModel>().repository.deleteUsuario(
        usuario.id,
      );
      if (!mounted) return;
      setState(() => _usuarios.removeWhere((item) => item.id == usuario.id));
      _mensagem('Usuário excluído.');
    } catch (error) {
      if (mounted) _mensagem(AutenticacaoRepository.userMessageFor(error));
    }
  }

  void _substituirUsuario(UsuarioModel atualizado) {
    setState(() {
      _usuarios = [
        for (final item in _usuarios)
          if (item.id == atualizado.id) atualizado else item,
      ];
      _usuariosAtualizando.remove(atualizado.id);
    });
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
                              '${_usuarios.length} contas cadastradas',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: _adicionarUsuario,
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
            Expanded(child: _buildUserList()),
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

  List<UsuarioModel> get _listaFiltrada => _usuarios
      .where(
        (usuario) =>
            _perfilSelecionado == null || usuario.perfil == _perfilSelecionado,
      )
      .toList(growable: false);

  Widget _buildUserList() {
    if (_carregando) return const Center(child: CircularProgressIndicator());
    if (_erro != null) {
      return _FeedbackState(
        message: _erro!,
        actionLabel: 'Tentar novamente',
        onAction: _carregarUsuarios,
      );
    }
    if (_listaFiltrada.isEmpty) {
      return const Center(child: Text('Nenhum usuário encontrado.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
      itemCount: _listaFiltrada.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final usuario = _listaFiltrada[index];
        return _UsuarioCard(
          usuario: usuario,
          icone: _iconePerfil(usuario.perfil),
          atualizando: _usuariosAtualizando.contains(usuario.id),
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

class _CabecalhoCoordenacao extends StatelessWidget {
  const _CabecalhoCoordenacao({
    required this.nome,
    required this.onRefresh,
    required this.onLogout,
  });

  final String nome;
  final VoidCallback onRefresh;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final compacto = MediaQuery.sizeOf(context).width < 600;
    final topo = MediaQuery.paddingOf(context).top;
    return SizedBox(
      height: topo + (compacto ? 190 : 220),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/brand_background.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          ColoredBox(
            color: const Color(0xFF05285A).withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? .82
                  : .72,
            ),
          ),
          Positioned(
            left: 18,
            right: 10,
            top: topo + 8,
            child: Row(
              children: [
                const Icon(
                  Icons.admin_panel_settings_outlined,
                  color: Colors.white,
                  size: 26,
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Atualizar usuários',
                  onPressed: onRefresh,
                  color: Colors.white,
                  icon: const Icon(Icons.refresh),
                ),
                const BotaoAlternarTema(color: Colors.white),
                IconButton(
                  tooltip: 'Sair',
                  onPressed: onLogout,
                  color: Colors.white,
                  icon: const Icon(Icons.logout),
                ),
              ],
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 22,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Olá, $nome!',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compacto ? 27 : 34,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Coordenação · Gestão de usuários',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .95),
                    fontSize: compacto ? 15 : 18,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Acompanhe acessos e contas do sistema',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .86),
                    fontSize: compacto ? 13 : 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UsuarioCard extends StatelessWidget {
  const _UsuarioCard({
    required this.usuario,
    required this.icone,
    required this.atualizando,
    required this.onStatusChanged,
    required this.onEdit,
    required this.onDelete,
  });

  final UsuarioModel usuario;
  final IconData icone;
  final bool atualizando;
  final ValueChanged<bool> onStatusChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? AppTheme.darkText : AppTheme.navy;
    final muted = dark ? const Color(0xFFB9C7DD) : const Color(0xFF526987);
    final labelPerfil = switch (usuario.perfil) {
      PerfilUsuario.aluno => 'Aluno',
      PerfilUsuario.professor => 'Professor',
      PerfilUsuario.recepcao => 'Recepção',
      PerfilUsuario.admin => 'Coordenação',
      PerfilUsuario.desconhecido => 'Outro perfil',
    };
    return Card(
      color: dark ? AppTheme.darkSurface : Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 23,
              backgroundColor: dark
                  ? const Color(0xFF1B2A40)
                  : const Color(0xFFE7EDF8),
              foregroundColor: dark ? AppTheme.gold : AppTheme.navy,
              child: Icon(icone),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    usuario.nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: fg,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    usuario.perfil == PerfilUsuario.aluno
                        ? 'Matrícula: ${usuario.matricula ?? 'Não informada'}'
                        : usuario.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: muted, fontSize: 12),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: usuario.ativo
                              ? const Color(0xFF24834A)
                              : const Color(0xFFE34B4B),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        usuario.ativo ? 'Ativo' : 'Inativo',
                        style: TextStyle(
                          color: usuario.ativo
                              ? const Color(0xFF24834A)
                              : const Color(0xFFE34B4B),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        '· $labelPerfil',
                        style: TextStyle(color: muted, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: usuario.ativo,
              onChanged: atualizando ? null : onStatusChanged,
            ),
            PopupMenuButton<String>(
              tooltip: 'Ações do usuário',
              onSelected: (value) => value == 'editar' ? onEdit() : onDelete(),
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'editar',
                  child: ListTile(
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Editar'),
                  ),
                ),
                PopupMenuItem(
                  value: 'excluir',
                  child: ListTile(
                    leading: Icon(Icons.delete_outline, color: Colors.red),
                    title: Text('Excluir'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DadosUsuario {
  const _DadosUsuario({
    required this.nome,
    required this.email,
    required this.perfil,
    this.senha,
    this.matricula,
  });

  final String nome;
  final String email;
  final PerfilUsuario perfil;
  final String? senha;
  final String? matricula;
}

class _UsuarioFormDialog extends StatefulWidget {
  const _UsuarioFormDialog({this.usuario, required this.podeAlterarPerfil});

  final UsuarioModel? usuario;
  final bool podeAlterarPerfil;

  @override
  State<_UsuarioFormDialog> createState() => _UsuarioFormDialogState();
}

class _UsuarioFormDialogState extends State<_UsuarioFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  final _matricula = TextEditingController();
  late PerfilUsuario _perfil;

  @override
  void initState() {
    super.initState();
    final usuario = widget.usuario;
    _perfil = usuario?.perfil ?? PerfilUsuario.aluno;
    _nome.text = usuario?.nome ?? '';
    _email.text = usuario?.email ?? '';
    _matricula.text = usuario?.matricula ?? '';
  }

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _senha.dispose();
    _matricula.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editando = widget.usuario != null;
    return AlertDialog(
      title: Text(editando ? 'Editar usuário' : 'Adicionar usuário'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nome,
                  decoration: const InputDecoration(labelText: 'Nome completo'),
                  textCapitalization: TextCapitalization.words,
                  validator: _obrigatorio,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _email,
                  decoration: const InputDecoration(labelText: 'E-mail'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Informe o e-mail.';
                    }
                    if (!value.contains('@')) {
                      return 'Informe um e-mail válido.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _senha,
                  decoration: InputDecoration(
                    labelText: editando ? 'Nova senha (opcional)' : 'Senha',
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (!editando && (value == null || value.length < 8)) {
                      return 'Use pelo menos 8 caracteres.';
                    }
                    if (editando &&
                        value != null &&
                        value.isNotEmpty &&
                        value.length < 8) {
                      return 'Use pelo menos 8 caracteres.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _matricula,
                  decoration: const InputDecoration(
                    labelText: 'Matrícula (opcional)',
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<PerfilUsuario>(
                  initialValue: _perfil,
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
                      child: Text('Coordenação'),
                    ),
                  ],
                  onChanged: widget.podeAlterarPerfil
                      ? (value) {
                          if (value != null) setState(() => _perfil = value);
                        }
                      : null,
                ),
              ],
            ),
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
          child: Text(editando ? 'Salvar alterações' : 'Cadastrar'),
        ),
      ],
    );
  }

  String? _obrigatorio(String? value) =>
      value == null || value.trim().length < 2
      ? 'Informe pelo menos 2 caracteres.'
      : null;

  void _salvar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _DadosUsuario(
        nome: _nome.text.trim(),
        email: _email.text.trim(),
        perfil: _perfil,
        senha: _senha.text.isEmpty ? null : _senha.text,
        matricula: _matricula.text.trim().isEmpty
            ? null
            : _matricula.text.trim(),
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
