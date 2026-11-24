import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';

import '../../models/paciente_model.dart';
import '../../view_models/autenticacao_view_model.dart';
import '../autenticacao/entrar_view.dart';
import '../pacientes/cadastrar_paciente_view.dart';
import '../pacientes/buscar_paciente_view.dart';
import '../../widgets/botao_alternar_tema.dart';
import '../recepcao/widgets/navegacao_inferior_recepcao.dart';
import '../../widgets/cabecalho_pagina_aluno.dart';

class InicioRecepcaoView extends StatelessWidget {
  const InicioRecepcaoView({super.key});

  Future<void> _createPatient(BuildContext context) async {
    final created = await Navigator.of(context).push<PacienteModel>(
      MaterialPageRoute<PacienteModel>(
        builder: (_) =>
            const CadastrarPacienteView(showStudentNavigation: false),
      ),
    );
    if (!context.mounted || created == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const BuscarPacienteView(allowOpenRecord: false),
      ),
    );
  }

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
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: EstiloPaginaAluno.background(context),
      body: Theme(
        data: EstiloPaginaAluno.readableTheme(context),
        child: Column(
          children: [
            _ReceptionHeader(
              name: user?.nome ?? 'Recepção',
              onLogout: () => _logout(context),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
                    children: [
                      Text(
                        'Acesso rápido',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      _ReceptionAction(
                        icon: Icons.person_search_outlined,
                        title: 'Buscar pacientes',
                        description:
                            'Localize e atualize cadastros por nome ou CPF.',
                        onPressed: () => Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) => const BuscarPacienteView(
                              allowOpenRecord: false,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ReceptionAction(
                        icon: Icons.person_add_alt_1_outlined,
                        title: 'Cadastrar paciente',
                        description:
                            'Registre os dados cadastrais e crie o prontuário.',
                        onPressed: () => _createPatient(context),
                      ),
                      const SizedBox(height: 18),
                      Card(
                        color: dark ? AppTheme.darkSurface : Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: dark ? AppTheme.gold : AppTheme.navy,
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'A recepção pode manter os dados cadastrais. O acesso às informações clínicas permanece restrito aos perfis autorizados.',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavegacaoInferiorRecepcao(
        currentIndex: 0,
        onDestinationSelected: (index) {
          if (index == 1) {
            Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) =>
                    const BuscarPacienteView(allowOpenRecord: false),
              ),
            );
          }
          if (index == 2) _logout(context);
        },
      ),
    );
  }
}

class _ReceptionHeader extends StatelessWidget {
  const _ReceptionHeader({required this.name, required this.onLogout});

  final String name;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    final top = MediaQuery.paddingOf(context).top;
    return SizedBox(
      height: top + (compact ? 190 : 220),
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
            right: 12,
            top: top + 8,
            child: Row(
              children: [
                const Icon(
                  Icons.people_alt_outlined,
                  color: Colors.white,
                  size: 27,
                ),
                const Spacer(),
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
            bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Olá, ${name.split(' ').first}!',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 27 : 34,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Recepção · Gestão de pacientes',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .94),
                    fontSize: compact ? 15 : 18,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Clínica-escola de Odontologia',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .86),
                    fontSize: compact ? 13 : 16,
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

class _ReceptionAction extends StatelessWidget {
  const _ReceptionAction({
    required this.icon,
    required this.title,
    required this.description,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      color: dark ? AppTheme.darkSurface : Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: CircleAvatar(
          backgroundColor: dark
              ? const Color(0xFF1B2A40)
              : const Color(0xFFFFF5D2),
          foregroundColor: dark ? AppTheme.gold : AppTheme.navy,
          child: Icon(icon),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(description),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: dark ? AppTheme.gold : AppTheme.navy,
        ),
        onTap: onPressed,
      ),
    );
  }
}
