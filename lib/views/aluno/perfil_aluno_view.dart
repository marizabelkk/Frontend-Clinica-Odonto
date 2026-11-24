import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/usuario_model.dart';
import '../../widgets/cabecalho_pagina_aluno.dart';
import '../../widgets/navegacao_inferior_aluno.dart';
import '../atendimentos/meus_atendimentos_view.dart';
import '../autenticacao/recuperar_senha_view.dart';
import '../pacientes/buscar_paciente_view.dart';

class PerfilAlunoView extends StatelessWidget {
  const PerfilAlunoView({
    required this.usuario,
    required this.onLogout,
    super.key,
  });

  final UsuarioModel usuario;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: EstiloPaginaAluno.background(context),
      body: Theme(
        data: EstiloPaginaAluno.readableTheme(context),
        child: Column(
          children: [
            const CabecalhoPaginaAluno(
              title: 'Meu perfil',
              subtitle: 'Suas informações e configurações no sistema.',
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ProfileCard(usuario: usuario),
                        const SizedBox(height: 14),
                        _ProfileSection(
                          title: 'Dados da conta',
                          icon: Icons.school_outlined,
                          child: Row(
                            children: [
                              Expanded(
                                child: _AccountValue(
                                  label: 'Matrícula',
                                  value: _displayValue(usuario.matricula),
                                ),
                              ),
                              _VerticalDivider(color: colors.outlineVariant),
                              Expanded(
                                child: _AccountValue(
                                  label: 'Perfil',
                                  value: _profileName(usuario.perfil),
                                ),
                              ),
                              _VerticalDivider(color: colors.outlineVariant),
                              Expanded(
                                child: _AccountValue(
                                  label: 'Situação',
                                  value: usuario.ativo ? 'Ativa' : 'Inativa',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        _ProfileSection(
                          title: 'Conta',
                          icon: Icons.person_outline,
                          children: [
                            _ProfileOption(
                              icon: Icons.badge_outlined,
                              title: 'Meus dados',
                              subtitle:
                                  'Visualize suas informações pessoais e acadêmicas.',
                              onTap: () => _showAccountDetails(context),
                            ),
                            _ProfileOption(
                              icon: Icons.lock_reset_outlined,
                              title: 'Alterar senha',
                              subtitle:
                                  'Atualize a senha de acesso à sua conta.',
                              onTap: () => Navigator.of(context).push<void>(
                                MaterialPageRoute<void>(
                                  builder: (_) => RecuperarSenhaView(
                                    initialEmail: usuario.email,
                                  ),
                                ),
                              ),
                            ),
                            _ProfileOption(
                              icon: Icons.notifications_none_outlined,
                              title: 'Notificações',
                              subtitle:
                                  'Consulte como acompanhar avisos do sistema.',
                              onTap: () => _showInfo(
                                context,
                                title: 'Notificações',
                                message:
                                    'Avisos sobre atendimentos e fichas aparecem no próprio sistema.',
                              ),
                              showDivider: false,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _ProfileSection(
                          title: 'Suporte e recursos',
                          icon: Icons.menu_book_outlined,
                          children: [
                            _ProfileOption(
                              icon: Icons.menu_book_outlined,
                              title: 'Materiais e protocolos',
                              subtitle:
                                  'Orientações para usar os fluxos clínicos.',
                              onTap: () => _showInfo(
                                context,
                                title: 'Materiais e protocolos',
                                message:
                                    'Para iniciar um atendimento, busque ou cadastre o paciente, abra o prontuário e selecione novo atendimento.',
                              ),
                            ),
                            _ProfileOption(
                              icon: Icons.support_agent_outlined,
                              title: 'Ajuda e suporte',
                              subtitle:
                                  'Veja orientações para acessar o sistema.',
                              onTap: () => _showInfo(
                                context,
                                title: 'Ajuda e suporte',
                                message:
                                    'Em caso de dúvidas sobre seu acesso, procure a coordenação da clínica.',
                              ),
                            ),
                            _ProfileOption(
                              icon: Icons.info_outline,
                              title: 'Sobre o sistema',
                              subtitle: 'Informações sobre o aplicativo.',
                              onTap: () => _showInfo(
                                context,
                                title: 'Clínica Odonto',
                                message:
                                    'Prontuário Odontológico Digital · Versão 1.0.0',
                              ),
                              showDivider: false,
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _LogoutButton(onPressed: onLogout),
                        const SizedBox(height: 14),
                        Text(
                          'Clínica Odonto  •  Versão 1.0.0',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavegacaoInferiorAluno(
        currentIndex: 3,
        onDestinationSelected: (index) => _navigate(context, index),
      ),
    );
  }

  void _navigate(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.of(context).pop();
      case 1:
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(builder: (_) => const BuscarPacienteView()),
        );
      case 2:
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(builder: (_) => const MeusAtendimentosView()),
        );
      case 3:
        return;
    }
  }

  void _showAccountDetails(BuildContext context) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Meus dados'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailLine(label: 'Nome', value: usuario.nome),
          _DetailLine(label: 'E-mail', value: usuario.email),
          _DetailLine(
            label: 'Matrícula',
            value: _displayValue(usuario.matricula),
          ),
          _DetailLine(label: 'Perfil', value: _profileName(usuario.perfil)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
      ],
    ),
  );

  void _showInfo(
    BuildContext context, {
    required String title,
    required String message,
  }) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Entendi'),
        ),
      ],
    ),
  );
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.usuario});

  final UsuarioModel usuario;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = Theme.of(context).brightness == Brightness.dark
        ? AppTheme.gold
        : AppTheme.navy;

    return _SurfaceCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 38,
            backgroundColor: accent.withValues(alpha: .1),
            foregroundColor: accent,
            child: Text(
              _initials(usuario.nome),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  usuario.nome,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  usuario.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _RoleBadge(color: accent),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.school_outlined, size: 16, color: color),
        const SizedBox(width: 5),
        Text(
          'Aluno',
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.title,
    required this.icon,
    this.child,
    this.children = const [],
  });

  final String title;
  final IconData icon;
  final Widget? child;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = Theme.of(context).brightness == Brightness.dark
        ? AppTheme.gold
        : AppTheme.navy;

    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 23),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (child != null) child!,
          for (final item in children) item,
        ],
      ),
    );
  }
}

class _ProfileOption extends StatelessWidget {
  const _ProfileOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.showDivider = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = Theme.of(context).brightness == Brightness.dark
        ? AppTheme.gold
        : AppTheme.navy;

    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: accent.withValues(alpha: .1),
            foregroundColor: accent,
            child: Icon(icon),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(subtitle),
          trailing: Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
          onTap: onTap,
        ),
        if (showDivider)
          Divider(height: 1, indent: 64, color: colors.outlineVariant),
      ],
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(18),
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? null
            : [
                BoxShadow(
                  color: AppTheme.navy.withValues(alpha: .045),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: child,
    );
  }
}

class _AccountValue extends StatelessWidget {
  const _AccountValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) =>
      Container(height: 42, width: 1, color: color);
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.logout),
        label: const Text('Sair da conta'),
        style: OutlinedButton.styleFrom(
          foregroundColor: error,
          backgroundColor: error.withValues(alpha: .07),
          side: BorderSide(color: error.withValues(alpha: .16)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

String _initials(String name) => name
    .trim()
    .split(RegExp(r'\s+'))
    .where((part) => part.isNotEmpty)
    .take(2)
    .map((part) => part[0].toUpperCase())
    .join();

String _displayValue(String? value) =>
    value == null || value.trim().isEmpty ? 'Não informada' : value;

String _profileName(PerfilUsuario perfil) => switch (perfil) {
  PerfilUsuario.aluno => 'Aluno',
  PerfilUsuario.professor => 'Professor',
  PerfilUsuario.recepcao => 'Recepção',
  PerfilUsuario.admin => 'Administrador',
  PerfilUsuario.desconhecido => 'Não informado',
};
