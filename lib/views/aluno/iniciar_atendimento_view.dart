import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/paciente_model.dart';
import '../../view_models/atendimento_view_model.dart';
import '../atendimentos/semiologia/formulario_semiologia_view.dart';
import '../../widgets/cabecalho_pagina_aluno.dart';

class IniciarAtendimentoView extends StatefulWidget {
  const IniciarAtendimentoView({
    required this.paciente,
    required this.prontuarioId,
    super.key,
  });

  final PacienteModel paciente;
  final int? prontuarioId;

  @override
  State<IniciarAtendimentoView> createState() => _IniciarAtendimentoViewState();
}

class _IniciarAtendimentoViewState extends State<IniciarAtendimentoView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AtendimentoViewModel>().loadEspecialidades();
    });
  }

  Future<void> _start(BuildContext context) async {
    final prontuario = widget.prontuarioId;
    if (prontuario == null) return;

    final viewModel = context.read<AtendimentoViewModel>();
    final ficha = await viewModel.startSemiologia(prontuarioId: prontuario);
    if (!context.mounted || ficha == null || viewModel.atendimento == null) {
      return;
    }
    final submitted = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => FormularioSemiologiaView(
          paciente: widget.paciente,
          atendimentoId: viewModel.atendimento!.id,
          ficha: ficha,
        ),
      ),
    );
    if (submitted == true && context.mounted) {
      await viewModel.loadMyAttendances();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: EstiloPaginaAluno.background(context),
      body: Theme(
        data: EstiloPaginaAluno.readableTheme(context),
        child: Column(
          children: [
            const CabecalhoPaginaAluno(
              title: 'Novo atendimento',
              subtitle: 'Avaliação inicial de Semiologia',
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    'Avaliação inicial de Semiologia',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'O atendimento será vinculado ao prontuário e ao aluno autenticado.',
                  ),
                  const SizedBox(height: 20),
                  Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: EstiloPaginaAluno.accent(
                          context,
                        ).withValues(alpha: 0.12),
                        foregroundColor: EstiloPaginaAluno.accent(context),
                        child: const Icon(Icons.person_outline),
                      ),
                      title: Text(widget.paciente.nomeCompleto ?? 'Paciente'),
                      subtitle: Text(
                        [
                          if (widget.paciente.cpf != null)
                            'CPF: ${widget.paciente.cpf}',
                          if (widget.prontuarioId != null)
                            'Prontuário: ${widget.prontuarioId}',
                        ].join('\n'),
                      ),
                    ),
                  ),
                  Consumer<AtendimentoViewModel>(
                    builder: (context, model, _) {
                      if (model.isLoadingSpecialties) {
                        return const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (model.specialtyErrorMessage != null) {
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.cloud_off_outlined),
                            title: const Text(
                              'Não foi possível consultar especialidades.',
                            ),
                            subtitle: Text(model.specialtyErrorMessage!),
                            trailing: IconButton(
                              tooltip: 'Tentar novamente',
                              onPressed: model.loadEspecialidades,
                              icon: const Icon(Icons.refresh),
                            ),
                          ),
                        );
                      }
                      if (model.semiologiaEspecialidadeId == null) {
                        return const _SetupNotice();
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  if (widget.prontuarioId == null)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Não é possível iniciar: a API não informou o prontuário deste paciente.',
                        ),
                      ),
                    ),
                  Consumer<AtendimentoViewModel>(
                    builder: (context, model, _) {
                      if (model.errorMessage == null) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          model.errorMessage!,
                          style: TextStyle(color: colors.error),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Consumer<AtendimentoViewModel>(
                    builder: (context, model, _) => ElevatedButton.icon(
                      onPressed:
                          model.isLoading ||
                              model.isLoadingSpecialties ||
                              model.semiologiaEspecialidadeId == null ||
                              widget.prontuarioId == null
                          ? null
                          : () => _start(context),
                      icon: model.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.add),
                      label: const Text('Iniciar avaliação de Semiologia'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetupNotice extends StatelessWidget {
  const _SetupNotice();

  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.surfaceContainerHighest,
    child: const Padding(
      padding: EdgeInsets.all(16),
      child: Text(
        'A API não retornou uma especialidade ativa chamada Semiologia. O atendimento não pode ser iniciado.',
      ),
    ),
  );
}
