import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/viewmodels/auth_view_model.dart';
import 'profile_landing_view.dart';

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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthViewModel>();
    final success = await auth.login(
      email: _emailController.text.trim(),
      senha: _passwordController.text,
    );
    if (!success || !mounted) return;

    final usuario = auth.usuario;
    if (usuario == null) return;
    await Navigator.of(context).pushAndRemoveUntil<void>(
      MaterialPageRoute<void>(
        builder: (_) => ProfileLandingView(usuario: usuario),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 700;
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 32 : 24,
                vertical: 32,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 64,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _BrandHeader(colors: colors),
                        const SizedBox(height: 42),
                        Text(
                          'Bem-vindo(a)',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Acesse sua conta institucional para continuar.',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: const Color(0xFF686B8E)),
                        ),
                        const SizedBox(height: 28),
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.username],
                                decoration: const InputDecoration(
                                  labelText: 'E-mail institucional',
                                  hintText: 'Digite seu e-mail',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                    ? 'Informe seu e-mail.'
                                    : null,
                              ),
                              const SizedBox(height: 18),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [AutofillHints.password],
                                onFieldSubmitted: (_) => _submit(),
                                decoration: InputDecoration(
                                  labelText: 'Senha',
                                  hintText: 'Digite sua senha',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    tooltip: _obscurePassword
                                        ? 'Mostrar senha'
                                        : 'Ocultar senha',
                                    onPressed: () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                  ),
                                ),
                                validator: (value) =>
                                    value == null || value.isEmpty
                                    ? 'Informe sua senha.'
                                    : null,
                              ),
                              const SizedBox(height: 18),
                              Consumer<AuthViewModel>(
                                builder: (context, auth, _) {
                                  if (auth.errorMessage == null) {
                                    return const SizedBox.shrink();
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: Text(
                                      auth.errorMessage!,
                                      key: const Key('login-error'),
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
                                  onPressed: auth.isLoading ? null : _submit,
                                  child: auth.isLoading
                                      ? const SizedBox(
                                          height: 22,
                                          width: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text('Entrar'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Acesso destinado a alunos e professores da clínica-escola.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: const Color(0xFF686B8E)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.colors});

  final ColorScheme colors;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      CircleAvatar(
        radius: 34,
        backgroundColor: colors.primary.withValues(alpha: 0.1),
        child: Icon(
          Icons.medical_services_outlined,
          size: 34,
          color: colors.primary,
        ),
      ),
      const SizedBox(height: 12),
      Text(
        'Clínica Odonto',
        style: Theme.of(context).textTheme.headlineSmall
            ?.copyWith(color: colors.primary, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 4),
      Text(
        'Prontuário Odontológico Digital',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    ],
  );
}
