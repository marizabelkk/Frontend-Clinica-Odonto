import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/viewmodels/auth_view_model.dart';
import 'auth_shell.dart';
import 'reset_password_view.dart';

/// Passo 1 da recuperação: pede o código de 6 dígitos, enviado por e-mail.
class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({this.initialEmail = '', super.key});

  final String initialEmail;

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController = TextEditingController(
    text: widget.initialEmail,
  );
  bool _isSending = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSending = true;
      _error = null;
    });
    final email = _emailController.text.trim();
    final error = await context.read<AuthViewModel>().requestPasswordReset(
      email,
    );
    if (!mounted) return;
    setState(() {
      _isSending = false;
      _error = error;
    });
    if (error == null) _goToReset(email, codeSent: true);
  }

  void _goToReset(String email, {required bool codeSent}) =>
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => ResetPasswordView(email: email, codeSent: codeSent),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AuthShell(
      showBack: true,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.mark_email_read_outlined,
              size: 44,
              color: colors.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'Recuperar senha',
              textAlign: TextAlign.center,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Informe o e-mail da sua conta. Enviaremos um código de 6 dígitos para redefinir a senha.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.email],
              onFieldSubmitted: (_) => _send(),
              decoration: AuthShell.decoration(
                context,
                label: 'E-mail da conta',
                hint: 'Digite seu e-mail',
                icon: Icons.mail_outline,
              ),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) return 'Informe seu e-mail.';
                if (!text.contains('@') || !text.contains('.')) {
                  return 'Informe um e-mail válido.';
                }
                return null;
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                key: const Key('forgot-error'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 18),
            ElevatedButton(
              style: AuthShell.buttonStyle(context),
              onPressed: _isSending ? null : _send,
              child: _isSending
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Enviar código'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _isSending
                  ? null
                  : () => _goToReset(
                      _emailController.text.trim(),
                      codeSent: false,
                    ),
              child: const Text('Já tenho um código'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Voltar ao login'),
            ),
          ],
        ),
      ),
    );
  }
}
