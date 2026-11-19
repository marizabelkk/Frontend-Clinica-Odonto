import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../view_models/autenticacao_view_model.dart';
import 'estrutura_autenticacao.dart';

/// Passo 2 da recuperação: código recebido por e-mail + nova senha.
class RedefinirSenhaView extends StatefulWidget {
  const RedefinirSenhaView({
    required this.email,
    this.codeSent = false,
    super.key,
  });

  final String email;

  /// True quando acabamos de pedir o código (mostra o aviso de envio).
  final bool codeSent;

  @override
  State<RedefinirSenhaView> createState() => _RedefinirSenhaViewState();
}

class _RedefinirSenhaViewState extends State<RedefinirSenhaView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController = TextEditingController(
    text: widget.email,
  );
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;
  bool _isSaving = false;
  bool _isResending = false;
  String? _error;
  String? _info;

  @override
  void initState() {
    super.initState();
    if (widget.codeSent) {
      _info = 'Se o e-mail estiver cadastrado, o código chegará em instantes. Ele vale por poucos minutos.';
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _error = null;
    });
    final error = await context.read<AutenticacaoViewModel>().resetPassword(
      email: _emailController.text.trim(),
      codigo: _codeController.text.trim(),
      novaSenha: _passwordController.text,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).popUntil((route) => route.isFirst);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Senha redefinida com sucesso. Entre com a nova senha.'),
      ),
    );
  }

  Future<void> _resend() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Informe o e-mail para reenviar o código.');
      return;
    }
    setState(() {
      _isResending = true;
      _error = null;
    });
    final error = await context.read<AutenticacaoViewModel>().requestPasswordReset(
      email,
    );
    if (!mounted) return;
    setState(() {
      _isResending = false;
      _error = error;
      _info = error == null
          ? 'Pedido enviado. Se já havia um código recente, aguarde 1 minuto para solicitar outro.'
          : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return EstruturaAutenticacao(
      showBack: true,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.lock_reset, size: 44, color: colors.primary),
            const SizedBox(height: 12),
            Text(
              'Nova senha',
              textAlign: TextAlign.center,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (_info != null) ...[
              const SizedBox(height: 8),
              Text(
                _info!,
                key: const Key('reset-info'),
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 22),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: EstruturaAutenticacao.decoration(
                context,
                label: 'E-mail da conta',
                icon: Icons.mail_outline,
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Informe seu e-mail.'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              decoration: EstruturaAutenticacao.decoration(
                context,
                label: 'Código de 6 dígitos',
                icon: Icons.pin_outlined,
              ),
              validator: (value) => (value ?? '').trim().length == 6
                  ? null
                  : 'Informe os 6 dígitos do código.',
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscure,
              textInputAction: TextInputAction.next,
              decoration: EstruturaAutenticacao.decoration(
                context,
                label: 'Nova senha',
                hint: 'Mínimo de 8 caracteres',
                icon: Icons.lock_outline,
                suffix: IconButton(
                  tooltip: _obscure ? 'Mostrar senha' : 'Ocultar senha',
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) {
                final text = value ?? '';
                if (text.length < 8) return 'Use pelo menos 8 caracteres.';
                if (utf8.encode(text).length > 72) {
                  return 'A senha deve ter no máximo 72 bytes.';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _confirmController,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: EstruturaAutenticacao.decoration(
                context,
                label: 'Confirmar nova senha',
                icon: Icons.lock_outline,
              ),
              validator: (value) => value == _passwordController.text
                  ? null
                  : 'As senhas não coincidem.',
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                key: const Key('reset-error'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 18),
            ElevatedButton(
              style: EstruturaAutenticacao.buttonStyle(context),
              onPressed: _isSaving ? null : _submit,
              child: _isSaving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Redefinir senha'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _isResending || _isSaving ? null : _resend,
              child: Text(_isResending ? 'Enviando...' : 'Reenviar código'),
            ),
          ],
        ),
      ),
    );
  }
}
