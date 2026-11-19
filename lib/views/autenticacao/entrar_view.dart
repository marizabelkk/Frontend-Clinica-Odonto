import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/storage/local_prefs.dart';
import '../../core/theme/app_theme.dart';
import '../../view_models/autenticacao_view_model.dart';
import '../../widgets/botao_alternar_tema.dart';
import 'direcionador_perfil_view.dart';
import 'estrutura_autenticacao.dart';
import 'recuperar_senha_view.dart';

/// Contas de teste (backend: `flask bootstrap`). Só aparecem em builds de debug.
const _testAccounts = <({String label, String email, String senha})>[
  (label: 'Aluno', email: 'aluno@uninassau.edu.br', senha: 'aluno123'),
  (label: 'Professor', email: 'professor@uninassau.edu.br', senha: 'professor123'),
  (label: 'Recepção', email: 'recepcao@uninassau.edu.br', senha: 'recepcao123'),
  (label: 'Coordenadora (Admin)', email: 'coordenadora@uninassau.edu.br', senha: 'admin123'),
];

const _rememberedEmailKey = 'remembered_email';
const _appVersion = 'Versão 1.0.0';

class EntrarView extends StatefulWidget {
  const EntrarView({super.key});

  @override
  State<EntrarView> createState() => _LoginViewState();
}

class _LoginViewState extends State<EntrarView> {
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

    final auth = context.read<AutenticacaoViewModel>();
    final email = _emailController.text.trim();
    final success = await auth.login(email: email, senha: _passwordController.text);
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
      MaterialPageRoute<void>(builder: (_) => DirecionadorPerfilView(usuario: usuario)),
      (_) => false,
    );
  }

  void _openForgotPassword() => Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (_) => RecuperarSenhaView(initialEmail: _emailController.text.trim())),
      );

  void _openHelp() => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entre em contato com o suporte da clínica para obter ajuda.')),
      );

  void _fillTestAccount(String email, String senha) {
    _emailController.text = email;
    _passwordController.text = senha;
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final p = _AuthPalette.of(context);
    return Scaffold(
      backgroundColor: p.page,
      body: LayoutBuilder(
        builder: (context, box) => box.maxWidth >= 900 ? _desktop(p) : _mobile(p),
      ),
    );
  }

  // ---------------------------- DESKTOP -----------------------------------

  Widget _desktop(_AuthPalette p) {
    return Row(children: [
      const Expanded(flex: 9, child: _BrandPanel()),
      Expanded(
        flex: 11,
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 28, 0),
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(onPressed: _openHelp, style: TextButton.styleFrom(foregroundColor: p.accent), child: const Text('Precisa de ajuda?')),
                Icon(Icons.help_outline, color: p.muted, size: 22),
                const SizedBox(width: 8),
                const BotaoAlternarTema(),
              ]),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(44, 40, 44, 36),
                      decoration: BoxDecoration(
                        color: p.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: p.line),
                        boxShadow: [BoxShadow(color: AppTheme.navy.withValues(alpha: .08), blurRadius: 40, offset: const Offset(0, 16))],
                      ),
                      child: _form(p, wide: true),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 28),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.school_outlined, color: p.accent, size: 34),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Clínica Odontológica Universitária', style: TextStyle(color: p.muted, fontWeight: FontWeight.w600, fontSize: 13)),
                  Text('Ensino, saúde e sociedade.', style: TextStyle(color: p.muted, fontSize: 12)),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    ]);
  }

  // ----------------------------- MOBILE -----------------------------------

  Widget _mobile(_AuthPalette p) {
    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        ClipPath(
          clipper: _CurveClipper(),
          child: Container(
            decoration: const BoxDecoration(gradient: _navyGradient),
            padding: const EdgeInsets.only(bottom: 56),
            child: Stack(children: [
              Positioned(top: -60, right: -50, child: _Bubble(size: 200, alpha: .06)),
              Positioned(top: 90, left: -70, child: _Bubble(size: 160, alpha: .05)),
              SafeArea(
                bottom: false,
                child: Column(children: [
                  const Align(alignment: Alignment.centerRight, child: Padding(padding: EdgeInsets.only(right: 6), child: BotaoAlternarTema())),
                  EstruturaAutenticacao.logo(size: 84),
                  const SizedBox(height: 16),
                  const Text('Clínica Odonto', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -.5)),
                  const SizedBox(height: 6),
                  Text('Prontuário Odontológico Digital', style: TextStyle(color: Colors.white.withValues(alpha: .92), fontSize: 15)),
                  const SizedBox(height: 10),
                  Container(width: 44, height: 4, decoration: BoxDecoration(color: AppTheme.gold, borderRadius: BorderRadius.circular(4))),
                ]),
              ),
            ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(children: [
                _form(p, wide: false),
                const SizedBox(height: 18),
                TextButton.icon(
                  onPressed: _openHelp,
                  icon: const Icon(Icons.headset_mic_outlined, size: 20),
                  label: const Text('Precisa de ajuda? Fale com o suporte'),
                  style: TextButton.styleFrom(foregroundColor: p.accent),
                ),
                const SizedBox(height: 10),
                Text(_appVersion, style: TextStyle(color: p.muted, fontSize: 13)),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  // ------------------------------ FORM ------------------------------------

  Widget _form(_AuthPalette p, {required bool wide}) {
    final textTheme = Theme.of(context).textTheme;
    final fg = Theme.of(context).colorScheme.onSurface;

    return Form(
      key: _formKey,
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(
          wide ? 'Bem-vindo(a)!' : 'Bem-vindo(a) de volta!',
          style: TextStyle(color: fg, fontSize: wide ? 32 : 26, fontWeight: FontWeight.w800, letterSpacing: -.5),
        ),
        const SizedBox(height: 6),
        Text('Acesse sua conta para continuar.', style: textTheme.bodyMedium?.copyWith(color: p.muted, fontSize: 15)),
        SizedBox(height: wide ? 28 : 26),
        _field(
          p,
          above: wide,
          label: 'E-mail institucional',
          hint: 'Digite seu e-mail',
          icon: wide ? Icons.mail_outline : Icons.person_outline,
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.username],
          validator: (v) => v == null || v.trim().isEmpty ? 'Informe seu e-mail.' : null,
        ),
        const SizedBox(height: 18),
        _field(
          p,
          above: wide,
          label: 'Senha',
          hint: 'Digite sua senha',
          icon: Icons.lock_outline,
          controller: _passwordController,
          obscure: _obscurePassword,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          onSubmitted: (_) => _submit(),
          suffix: IconButton(
            tooltip: _obscurePassword ? 'Mostrar senha' : 'Ocultar senha',
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: p.muted),
          ),
          validator: (v) => v == null || v.isEmpty ? 'Informe sua senha.' : null,
        ),
        const SizedBox(height: 8),
        Row(children: [
          Checkbox(
            value: _rememberMe,
            visualDensity: VisualDensity.compact,
            activeColor: p.dark ? AppTheme.gold : AppTheme.navy,
            checkColor: p.dark ? AppTheme.navy : Colors.white,
            onChanged: (v) => setState(() => _rememberMe = v ?? false),
          ),
          Flexible(child: Text(wide ? 'Lembrar de mim' : 'Lembrar-me', style: TextStyle(color: fg, fontSize: 14))),
          const Spacer(),
          Flexible(
            child: TextButton(
              onPressed: _openForgotPassword,
              style: TextButton.styleFrom(foregroundColor: p.accent, padding: const EdgeInsets.symmetric(horizontal: 4)),
              child: Text(wide ? 'Esqueceu sua senha?' : 'Esqueci minha senha', style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
        Consumer<AutenticacaoViewModel>(builder: (context, auth, _) {
          if (auth.errorMessage == null) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Text(
              auth.errorMessage!,
              key: const Key('login-error'),
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.w500),
            ),
          );
        }),
        const SizedBox(height: 8),
        Consumer<AutenticacaoViewModel>(
          builder: (context, auth, _) => ElevatedButton(
            onPressed: auth.isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: p.dark ? AppTheme.gold : AppTheme.navy,
              foregroundColor: p.dark ? AppTheme.navy : Colors.white,
              minimumSize: const Size.fromHeight(54),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            child: auth.isLoading
                ? SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: p.dark ? AppTheme.navy : Colors.white))
                : const Text('Entrar'),
          ),
        ),
        const SizedBox(height: 22),
        _OrDivider(p: p),
        const SizedBox(height: 20),
        _InfoBox(
          p: p,
          title: wide ? 'Acesso exclusivo para professores da clínica escola.' : 'Acesso restrito',
          text: wide
              ? 'Alunos devem utilizar o aplicativo mobile.'
              : 'Este sistema é exclusivo para alunos, professores e funcionários da clínica. Use suas credenciais institucionais para acessar.',
        ),
        if (kDebugMode) ...[
          const Divider(height: 32),
          Text('Contas de teste', textAlign: TextAlign.center, style: textTheme.labelSmall),
          const SizedBox(height: 8),
          Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 4, children: [
            for (final account in _testAccounts)
              ActionChip(label: Text(account.label), onPressed: () => _fillTestAccount(account.email, account.senha)),
          ]),
        ],
      ]),
    );
  }

  Widget _field(
    _AuthPalette p, {
    required bool above,
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    Iterable<String>? autofillHints,
    bool obscure = false,
    Widget? suffix,
    ValueChanged<String>? onSubmitted,
    FormFieldValidator<String>? validator,
  }) {
    OutlineInputBorder border(Color c, [double w = 1]) =>
        OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: c, width: w));

    final field = TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      decoration: InputDecoration(
        labelText: above ? null : label,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        floatingLabelStyle: TextStyle(color: p.accent, fontWeight: FontWeight.w600),
        hintText: hint,
        hintStyle: TextStyle(color: p.muted.withValues(alpha: .85)),
        prefixIcon: Icon(icon, color: p.accent),
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        enabledBorder: border(p.line),
        focusedBorder: border(p.accent, 1.6),
        errorBorder: border(Theme.of(context).colorScheme.error),
        focusedErrorBorder: border(Theme.of(context).colorScheme.error, 1.6),
      ),
    );

    if (!above) return field;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w700, fontSize: 13)),
      const SizedBox(height: 8),
      field,
    ]);
  }
}

// ---------------------------------------------------------------------------
// Paleta
// ---------------------------------------------------------------------------

const _navyGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [AppTheme.navy, AppTheme.royalBlue],
);

class _AuthPalette {
  _AuthPalette(this.dark, this.colors);
  final bool dark;
  final ColorScheme colors;

  static _AuthPalette of(BuildContext context) {
    final theme = Theme.of(context);
    return _AuthPalette(theme.brightness == Brightness.dark, theme.colorScheme);
  }

  Color get page => dark ? AppTheme.darkBackground : const Color(0xFFF7F8FA);
  Color get card => dark ? AppTheme.darkSurface : colors.surface;
  Color get line => dark ? const Color(0xFF34445C) : colors.outlineVariant;
  Color get muted => dark ? const Color(0xFFB9C7DD) : const Color(0xFF52647E);
  Color get soft => dark ? const Color(0xFF14243A) : const Color(0xFFEEF3FC);
  Color get accent => colors.primary;
}

// ---------------------------------------------------------------------------
// Painel de marca (desktop)
// ---------------------------------------------------------------------------

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    const features = [
      (Icons.assignment_outlined, 'Acompanhamento dos atendimentos'),
      (Icons.people_outline, 'Revisão e aprovação das fichas'),
      (Icons.description_outlined, 'Histórico completo dos pacientes'),
      (Icons.bar_chart_outlined, 'Mais organização para a clínica escola'),
    ];
    return Container(
      decoration: const BoxDecoration(gradient: _navyGradient),
      child: Stack(children: [
        Positioned(top: -120, right: -100, child: _Bubble(size: 420, alpha: .06)),
        Positioned(bottom: -140, left: -90, child: _Bubble(size: 360, alpha: .05)),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(64, 40, 56, 48),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                EstruturaAutenticacao.logo(size: 56),
                const SizedBox(width: 16),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Clínica Odonto', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
                  Text('Prontuário Digital', style: TextStyle(color: Colors.white.withValues(alpha: .9), fontSize: 15)),
                ]),
              ]),
              const Spacer(flex: 2),
              Text.rich(
                TextSpan(children: [
                  const TextSpan(text: 'Ensino que\ntransforma\n'),
                  TextSpan(text: 'sorrisos', style: TextStyle(color: AppTheme.gold)),
                ]),
                style: const TextStyle(color: Colors.white, fontSize: 48, height: 1.1, fontWeight: FontWeight.w800, letterSpacing: -1),
              ),
              const SizedBox(height: 20),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Text(
                  'Um sistema pensado para apoiar a formação acadêmica, integrando alunos, professores e pacientes em um só lugar.',
                  style: TextStyle(color: Colors.white.withValues(alpha: .92), fontSize: 17, height: 1.5),
                ),
              ),
              const SizedBox(height: 32),
              for (final f in features)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: .1), borderRadius: BorderRadius.circular(10)),
                      child: Icon(f.$1, color: AppTheme.gold, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Flexible(child: Text(f.$2, style: const TextStyle(color: Colors.white, fontSize: 15))),
                  ]),
                ),
              const Spacer(flex: 3),
              Container(width: 44, height: 3, decoration: BoxDecoration(color: AppTheme.gold, borderRadius: BorderRadius.circular(3))),
              const SizedBox(height: 14),
              Text('Cuidando de hoje,\nformando o amanhã.', style: TextStyle(color: Colors.white.withValues(alpha: .95), fontSize: 16, height: 1.4)),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Componentes visuais
// ---------------------------------------------------------------------------

class _Bubble extends StatelessWidget {
  const _Bubble({required this.size, required this.alpha});
  final double size, alpha;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: alpha))),
      );
}

class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.p});
  final _AuthPalette p;

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(child: Divider(color: p.line)),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: Text('ou', style: TextStyle(color: p.muted))),
        Expanded(child: Divider(color: p.line)),
      ]);
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.p, required this.title, required this.text});
  final _AuthPalette p;
  final String title, text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: p.soft,
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: AppTheme.gold, width: 4)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.info_outline, color: p.accent, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(color: p.accent, fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 4),
              Text(text, style: TextStyle(color: p.muted, fontSize: 13.5, height: 1.4)),
            ]),
          ),
        ]),
      );
}

class _CurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..lineTo(0, size.height - 40)
      ..quadraticBezierTo(size.width / 2, size.height + 30, size.width, size.height - 40)
      ..lineTo(size.width, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
