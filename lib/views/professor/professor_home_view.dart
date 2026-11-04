import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/professor_ficha_dto.dart';
import '../../data/repositories/demo_auth_repository.dart';
import '../../data/viewmodels/auth_view_model.dart';
import '../../data/viewmodels/professor_view_model.dart';
import '../auth/login_view.dart';
import 'professor_review_view.dart';

class ProfessorHomeView extends StatefulWidget {
  const ProfessorHomeView({super.key});

  @override
  State<ProfessorHomeView> createState() => _ProfessorHomeViewState();
}

class _ProfessorHomeViewState extends State<ProfessorHomeView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ProfessorViewModel>().loadPending();
    });
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthViewModel>().usuario;
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Área do professor'),
        actions: [
          IconButton(
            tooltip: 'Sair',
            onPressed: () {
              context.read<AuthViewModel>().logout();
              Navigator.of(context).pushAndRemoveUntil<void>(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      LoginView(demoAuthEnabled: DemoAuthRepository.isEnabled),
                ),
                (_) => false,
              );
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: context.read<ProfessorViewModel>().loadPending,
        child: LayoutBuilder(
          builder: (context, constraints) => ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Olá, ${usuario?.nome ?? 'Professor(a)'}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              const Text('Fichas submetidas para sua revisão.'),
              const SizedBox(height: 20),
              Consumer<ProfessorViewModel>(
                builder: (context, model, _) {
                  if (model.isLoading && model.pending.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (model.errorMessage != null && model.pending.isEmpty) {
                    return _MessagePanel(
                      message: model.errorMessage!,
                      onRetry: model.loadPending,
                    );
                  }
                  if (model.pending.isEmpty) {
                    return const _MessagePanel(
                      message: 'Não há fichas aguardando aprovação.',
                    );
                  }
                  final wide = constraints.maxWidth >= 760;
                  final cards = model.pending
                      .map(
                        (ficha) => _PendingCard(
                          ficha: ficha,
                          onTap: () async {
                            final loaded = await context
                                .read<ProfessorViewModel>()
                                .loadFicha(ficha.id);
                            if (!context.mounted || !loaded) return;
                            await Navigator.of(context).push<void>(
                              MaterialPageRoute<void>(
                                builder: (_) => const ProfessorReviewView(),
                              ),
                            );
                          },
                        ),
                      )
                      .toList();
                  if (!wide) return Column(children: cards);
                  return GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 3.8,
                    children: cards,
                  );
                },
              ),
              const SizedBox(height: 24),
              Card(
                color: colors.surfaceContainerHighest,
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Consulte apenas prontuários sob sua responsabilidade acadêmica.',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  const _PendingCard({required this.ficha, required this.onTap});

  final ProfessorFichaDto ficha;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final patient = ficha.data['paciente'];
    final student = ficha.data['aluno'] ?? ficha.data['aluno_responsavel'];
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.assignment_outlined)),
        title: Text(
          patient is Map
              ? (patient['nome_completo']?.toString() ?? 'Ficha #${ficha.id}')
              : 'Ficha #${ficha.id}',
        ),
        subtitle: Text(
          [
            ficha.status,
            if (student is Map) 'Aluno: ${student['nome'] ?? ''}',
          ].join(' • '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _MessagePanel extends StatelessWidget {
  const _MessagePanel({required this.message, this.onRetry});

  final String message;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(message, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ],
      ),
    ),
  );
}
