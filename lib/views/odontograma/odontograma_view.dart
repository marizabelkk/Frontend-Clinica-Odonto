import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/odontograma_model.dart';
import '../../view_models/odontograma_view_model.dart';
import '../../widgets/cabecalho_pagina_aluno.dart';
import '../../widgets/navegacao_inferior_aluno.dart';
import '../atendimentos/meus_atendimentos_view.dart';
import '../pacientes/buscar_paciente_view.dart';
import 'widgets/grafico_odontograma.dart';
import 'widgets/mapa_dentes.dart';

part 'widgets/odontograma_detalhes_widgets.dart';
part 'widgets/registro_odontograma_dialog.dart';

/// Tela do odontograma: toque no dente, consulte as condi\u00e7\u00f5es registradas abaixo e
/// (quando `canEdit`) adicione, edite ou exclua condi\u00e7\u00f5es do atendimento atual.

class OdontogramaView extends StatefulWidget {
  const OdontogramaView({
    required this.prontuarioId,
    this.atendimentoId,
    this.canEdit = false,
    this.canManageExisting = false,
    this.currentUserId,
    this.pacienteNome,
    this.showStudentNavigation = false,
    super.key,
  });

  final int prontuarioId;

  /// Atendimento em andamento (necessário para registrar/editar/excluir).
  final int? atendimentoId;
  final bool canEdit;
  final bool canManageExisting;
  final int? currentUserId;
  final String? pacienteNome;
  final bool showStudentNavigation;

  @override
  State<OdontogramaView> createState() => _OdontogramaViewState();
}

class _OdontogramaViewState extends State<OdontogramaView> {
  bool get _canAdd => widget.canEdit && widget.atendimentoId != null;
  bool get _canManageExisting =>
      widget.atendimentoId != null && (widget.canManageExisting || _canAdd);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() => context.read<OdontogramaViewModel>().load(
    prontuarioId: widget.prontuarioId,
    atendimentoId: widget.atendimentoId,
  );

  void _snack(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

  Future<void> _addOrEdit({OdontogramaRegistroModel? registro}) async {
    final model = context.read<OdontogramaViewModel>();
    final tooth = registro?.numeroDente ?? model.selectedTooth;
    if (tooth == null) return;
    final input = await showDialog<OdontogramaRegistroInput>(
      context: context,
      builder: (_) => _RegistroDialog(
        tooth: tooth,
        condicoes: model.condicoes,
        registro: registro,
      ),
    );
    if (input == null || !mounted) return;
    final error = await model.save(input, registro: registro);
    if (!mounted) return;
    _snack(
      error ??
          (registro == null ? 'Condi\u00e7\u00e3o registrada.' : 'Condi\u00e7\u00e3o atualizada.'),
    );
  }

  Future<void> _delete(OdontogramaRegistroModel registro) async {
    final model = context.read<OdontogramaViewModel>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir condi\u00e7\u00e3o?'),
        content: Text(
          '${model.condicaoNome(registro.condicaoId)} · face ${registro.face.label.toLowerCase()} do dente ${registro.numeroDente}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final error = await model.remove(registro);
    if (!mounted) return;
    _snack(error ?? 'Condi\u00e7\u00e3o exclu\u00edda.');
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final foreground = dark ? AppTheme.darkText : AppTheme.lightText;
    final muted = dark
        ? const Color(0xFFB9C7DD)
        : const Color(0xFF52647E);
    final surface = dark ? AppTheme.darkSurface : Colors.white;
    final accent = dark ? AppTheme.gold : AppTheme.navy;
    final onAccent = dark ? AppTheme.navy : Colors.white;
    final baseTheme = EstiloPaginaAluno.readableTheme(context);
    final cardBorder = dark
        ? const Color(0xFF263A56)
        : const Color(0xFFE3E8F0);
    final pageTheme = baseTheme.copyWith(
      colorScheme: baseTheme.colorScheme.copyWith(
        primary: accent,
        onPrimary: onAccent,
        secondary: AppTheme.gold,
        onSecondary: AppTheme.navy,
        surface: surface,
        onSurface: foreground,
      ),
      textTheme: baseTheme.textTheme.apply(
        bodyColor: foreground,
        displayColor: foreground,
      ),
      listTileTheme: ListTileThemeData(
        textColor: foreground,
        subtitleTextStyle: TextStyle(color: muted),
      ),
      cardTheme: baseTheme.cardTheme.copyWith(
        color: surface,
        elevation: dark ? 0 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: cardBorder),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: onAccent,
          minimumSize: const Size(48, 46),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
      ),
      inputDecorationTheme: baseTheme.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: surface,
      ),
      iconTheme: IconThemeData(color: accent),
    );

    return Scaffold(
      backgroundColor: EstiloPaginaAluno.background(context),
      body: Theme(
        data: pageTheme,
        child: Column(
          children: [
            CabecalhoPaginaAluno(
              title: 'Odontograma',
              subtitle: widget.pacienteNome == null
                  ? 'Mapa e hist\u00f3rico odontol\u00f3gico do paciente.'
                  : 'Mapa e hist\u00f3rico odontol\u00f3gico de ${widget.pacienteNome}.',
              actions: [
                IconButton(
                  tooltip: 'Recarregar odontograma',
                  onPressed: _load,
                  color: Colors.white,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            Expanded(
              child: Consumer<OdontogramaViewModel>(
                builder: (context, model, _) {
                  if (model.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (model.errorMessage != null) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.cloud_off_outlined,
                              size: 42,
                              color: EstiloPaginaAluno.accent(context),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              model.errorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: foreground),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _load,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Tentar novamente'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final chart = Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          GraficoOdontograma(
                            registrosPorDente: model.registrosPorDente,
                            selectedTooth: model.selectedTooth,
                            conditionCodes: {
                              for (final condicao in model.condicoes)
                                condicao.id: condicao.codigo,
                            },
                            onToothTap: model.selectTooth,
                          ),
                          const SizedBox(height: 12),
                          _Legend(model: model),
                        ],
                      ),
                    ),
                  );
                  final panel = _ToothPanel(
                    model: model,
                    canAdd: _canAdd,
                    canManageExisting: _canManageExisting,
                    currentUserId: widget.currentUserId,
                    atendimentoId: widget.atendimentoId,
                    onAdd: () => _addOrEdit(),
                    onEdit: (registro) => _addOrEdit(registro: registro),
                    onDelete: _delete,
                  );
                  final header = _Header(
                    pacienteNome: widget.pacienteNome,
                    canAdd: _canAdd,
                    canManageExisting: _canManageExisting,
                  );

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth >= 900) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 5,
                              child: ListView(
                                padding: const EdgeInsets.fromLTRB(18, 16, 8, 16),
                                children: [header, chart],
                              ),
                            ),
                            Expanded(
                              flex: 4,
                              child: ListView(
                                padding: const EdgeInsets.fromLTRB(8, 16, 18, 16),
                                children: [panel],
                              ),
                            ),
                          ],
                        );
                      }
                      return ListView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                        children: [header, chart, panel],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: widget.showStudentNavigation
          ? NavegacaoInferiorAluno(
              currentIndex: 1,
              onDestinationSelected: (index) {
                if (index == 0) navegarParaInicioAluno(context);
                if (index == 1) {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => const BuscarPacienteView(),
                    ),
                  );
                }
                if (index == 2) {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => const MeusAtendimentosView(),
                    ),
                  );
                }
                if (index == 3) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Acesse o perfil pelo menu da p\u00e1gina inicial.'),
                    ),
                  );
                }
              },
            )
          : null,
    );
  }
}
