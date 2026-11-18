import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/storage/local_prefs.dart';
import '../../data/viewmodels/auth_view_model.dart';
import 'auth_shell.dart';
import 'forgot_password_view.dart';
import 'profile_landing_view.dart';

/// Contas de teste (backend: `flask bootstrap`). Só aparecem em builds de debug.
const _testAccounts = <({String label, String email, String senha})>[
  (label: 'Aluno', email: 'aluno@uninassau.edu.br', senha: 'aluno123'),
  (
    label: 'Professor',
    email: 'professor@uninassau.edu.br',
    senha: 'professor123',
  ),
  (label: 'Recepção', email: 'recepcao@uninassau.edu.br', senha: 'recepcao123'),
  (
    label: 'Coordenadora (Admin)',
    email: 'coordenadora@uninassau.edu.br',
    senha: 'admin123',
  ),
];

const _rememberedEmailKey = 'remembered_email';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadRememberedEmail();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadRememberedEmail() async {
    final email = await LocalPrefs.getString(_rememberedEmailKey);
    if (!mounted || email == null || email.isEmpty) return;
    if (_emailController.text.isEmpty) _emailController.text = email;
    setState(() => _rememberMe = true);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthViewModel>();
    final email = _emailController.text.trim();
    final success = await auth.login(
      email: email,
      senha: _passwordController.text,
    );
    if (!success || !mounted) return;

    if (_rememberMe) {
      await LocalPrefs.setString(_rememberedEmailKey, email);
    } else {
      await LocalPrefs.remove(_rememberedEmailKey);
    }
    if (!mounted) return;

    final usuario = auth.usuario;
    if (usuario == null) return;
    await Navigator.of(context).pushAndRemoveUntil<void>(
      MaterialPageRoute<void>(
        builder: (_) => ProfileLandingView(usuario: usuario),
      ),
      (_) => false,
    );
  }

  void _openForgotPassword() => Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) =>
          ForgotPasswordView(initialEmail: _emailController.text.trim()),
    ),
  );

  void _fillTestAccount(String email, String senha) {
    _emailController.text = email;
    _passwordController.text = senha;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AuthShell(
      adaptLoginCard: true,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthShell.brand(context),
            const SizedBox(height: 20),
            Text(
              'Bem-vindo(a)',
              textAlign: TextAlign.center,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Acesse sua conta institucional para continuar.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.username],
              decoration: AuthShell.decoration(
                context,
                label: 'E-mail institucional',
                hint: 'Digite seu e-mail',
                icon: Icons.person_outline,
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Informe seu e-mail.'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => _submit(),
              decoration: AuthShell.decoration(
                context,
                label: 'Senha',
                hint: 'Digite sua senha',
                icon: Icons.lock_outline,
                suffix: IconButton(
                  tooltip: _obscurePassword ? 'Mostrar senha' : 'Ocultar senha',
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Informe sua senha.' : null,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Checkbox(
                  value: _rememberMe,
                  visualDensity: VisualDensity.compact,
                  onChanged: (value) =>
                      setState(() => _rememberMe = value ?? false),
                ),
                const Flexible(child: Text('Lembrar-me')),
                const Spacer(),
                Flexible(
                  child: TextButton(
                    onPressed: _openForgotPassword,
                    child: const Text('Esqueci minha senha'),
                  ),
                ),
              ],
            ),
            Consumer<AuthViewModel>(
              builder: (context, auth, _) {
                if (auth.errorMessage == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    auth.errorMessage!,
                    key: const Key('login-error'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
            Consumer<AuthViewModel>(
              builder: (context, auth, _) => ElevatedButton(
                style: AuthShell.buttonStyle(context),
                onPressed: auth.isLoading ? null : _submit,
                child: auth.isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Entrar'),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Acesso destinado a alunos e professores da clínica-escola.',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall,
            ),
            if (kDebugMode) ...[
              const Divider(height: 28),
              Text(
                'Contas de teste',
                textAlign: TextAlign.center,
                style: textTheme.labelSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final account in _testAccounts)
                    ActionChip(
                      label: Text(account.label),
                      onPressed: () =>
                          _fillTestAccount(account.email, account.senha),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
