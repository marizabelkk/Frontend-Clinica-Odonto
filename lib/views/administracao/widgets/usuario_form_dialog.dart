part of '../inicio_administrador_view.dart';

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
