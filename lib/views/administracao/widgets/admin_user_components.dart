part of '../inicio_administrador_view.dart';

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
