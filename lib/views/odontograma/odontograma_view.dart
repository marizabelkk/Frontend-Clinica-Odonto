import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/odontograma_model.dart';
import '../../view_models/odontograma_view_model.dart';
import '../../widgets/cabecalho_pagina_aluno.dart';
import '../../widgets/navegacao_inferior_aluno.dart';
import '../atendimentos/meus_atendimentos_view.dart';
import '../pacientes/buscar_paciente_view.dart';
import '../../widgets/odontograma/grafico_odontograma.dart';
import '../../widgets/odontograma/mapa_dentes.dart';

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

class _Header extends StatelessWidget {
  const _Header({
    required this.pacienteNome,
    required this.canAdd,
    required this.canManageExisting,
  });

  final String? pacienteNome;
  final bool canAdd;
  final bool canManageExisting;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = EstiloPaginaAluno.accent(context);
    final instruction = canAdd
        ? 'Selecione um dente para consultar ou registrar condi\u00e7\u00f5es.'
        : canManageExisting
            ? 'Selecione um dente para consultar, editar ou excluir condi\u00e7\u00f5es.'
            : 'Selecione um dente para consultar as condi\u00e7\u00f5es registradas.';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: accent.withValues(alpha: dark ? .16 : .10),
          foregroundColor: accent,
          child: const Icon(Icons.info_outline_rounded),
        ),
        title: Text(pacienteNome ?? 'Mapa odontol\u00f3gico'),
        subtitle: Text(instruction),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.model});

  final OdontogramaViewModel model;

  @override
  Widget build(BuildContext context) {
    final ids = {for (final r in model.registros) r.condicaoId}.toList()
      ..sort();
    if (ids.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        for (final id in ids)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Dot(
                color: GraficoOdontograma.colorForCondicao(
                  id,
                  codigo: model.condicaoCodigo(id),
                ),
              ),
              const SizedBox(width: 6),
              Text(model.condicaoNome(id)),
            ],
          ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 12,
    height: 12,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _ToothPanel extends StatelessWidget {
  const _ToothPanel({
    required this.model,
    required this.canAdd,
    required this.canManageExisting,
    required this.currentUserId,
    required this.atendimentoId,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final OdontogramaViewModel model;
  final bool canAdd;
  final bool canManageExisting;
  final int? currentUserId;
  final int? atendimentoId;
  final VoidCallback onAdd;
  final ValueChanged<OdontogramaRegistroModel> onEdit;
  final ValueChanged<OdontogramaRegistroModel> onDelete;

  @override
  Widget build(BuildContext context) {
    final tooth = model.selectedTooth;
    final registros = model.selectedToothRegistros;
    final teethWithConditions = model.registrosPorDente.keys.toList()..sort();
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Condi\u00e7\u00f5es do dente', style: textTheme.titleMedium),
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              key: ValueKey<int?>(tooth),
              initialValue: tooth,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Dente (numeração FDI)',
              ),
              items: [
                for (final number in MapaDentes.shapes.keys.toList()..sort())
                  DropdownMenuItem(
                    value: number,
                    child: Text(MapaDentes.describe(number)),
                  ),
              ],
              onChanged: model.selectTooth,
            ),
            const SizedBox(height: 14),
            if (tooth == null)
              const Text(
                'Toque em um dente do odontograma (ou escolha na lista acima) para consultar as condi\u00e7\u00f5es registradas.',
              )
            else ...[
              Text(MapaDentes.describe(tooth), style: textTheme.titleSmall),
              const SizedBox(height: 6),
              if (registros.isEmpty)
                const Text('Nenhuma condi\u00e7\u00e3o registrada neste dente.')
              else
                for (final registro in registros)
                  _RegistroTile(
                    registro: registro,
                    condicaoNome: model.condicaoNome(registro.condicaoId),
                    condicaoCodigo:
                        model.condicaoCodigo(registro.condicaoId),
                    canModify: canManageExisting &&
                        (currentUserId == null ||
                            registro.registradoPor == currentUserId) &&
                        (!canAdd || registro.atendimentoId == atendimentoId),
                    busy: model.isSaving,
                    onEdit: () => onEdit(registro),
                    onDelete: () => onDelete(registro),
                  ),
              if (canAdd) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  key: const Key('odontograma-add'),
                  onPressed: model.isSaving ? null : onAdd,
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar condi\u00e7\u00e3o'),
                ),
              ],
            ],
            if (teethWithConditions.isNotEmpty) ...[
              const Divider(height: 28),
              Text(
                'Dentes com condi\u00e7\u00f5es registradas',
                style: textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final number in teethWithConditions)
                    ActionChip(
                      label: Text(
                        '$number (${model.registrosPorDente[number]!.length})',
                      ),
                      onPressed: () => model.selectTooth(number),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RegistroTile extends StatelessWidget {
  const _RegistroTile({
    required this.registro,
    required this.condicaoNome,
    required this.condicaoCodigo,
    required this.canModify,
    required this.busy,
    required this.onEdit,
    required this.onDelete,
  });

  final OdontogramaRegistroModel registro;
  final String condicaoNome;
  final String? condicaoCodigo;
  final bool canModify;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  static String _date(DateTime? value) {
    if (value == null) return '';
    final d = value.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final observacao = registro.observacao;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: _Dot(
        color: GraficoOdontograma.colorForCondicao(
          registro.condicaoId,
          codigo: condicaoCodigo,
        ),
      ),
      title: Text(
        condicaoNome,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        [
          'Face: ${registro.face.label}',
          if (observacao != null && observacao.isNotEmpty) observacao,
          [
            if (registro.registradoEm != null) _date(registro.registradoEm),
            'atendimento #${registro.atendimentoId}',
          ].join(' · '),
        ].join('\n'),
      ),
      isThreeLine: true,
      trailing: canModify
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Editar',
                  onPressed: busy ? null : onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Excluir',
                  onPressed: busy ? null : onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            )
          : null,
    );
  }
}

class _RegistroDialog extends StatefulWidget {
  const _RegistroDialog({
    required this.tooth,
    required this.condicoes,
    this.registro,
  });

  final int tooth;
  final List<CondicaoOdontologicaModel> condicoes;
  final OdontogramaRegistroModel? registro;

  @override
  State<_RegistroDialog> createState() => _RegistroDialogState();
}

class _RegistroDialogState extends State<_RegistroDialog> {
  static const _wholeToothConditionCodes = <String>{
    'EXTRACAO_INDICADA',
    'PROTESE',
    'AUSENTE',
    'NAO_ERUPCIONADO',
    'IMPLANTE',
    'RAIZ_RESIDUAL',
    'COROA',
  };

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _observacao = TextEditingController(
    text: widget.registro?.observacao ?? '',
  );
  late int? _condicaoId = widget.registro?.condicaoId;
  late FaceDente? _face = widget.registro?.face;

  List<FaceDente> get _faceOptions {
    final options = MapaDentes.facesForTooth(widget.tooth);
    if (_face != null && !options.contains(_face)) options.add(_face!);
    return options;
  }

  bool _isWholeToothCondition(int? id) {
    if (id == null) return false;
    return widget.condicoes.any(
      (condition) =>
          condition.id == id &&
          _wholeToothConditionCodes.contains(condition.codigo.toUpperCase()),
    );
  }

  void _onConditionChanged(int? id) {
    setState(() {
      _condicaoId = id;
      if (_isWholeToothCondition(id)) {
        _face = FaceDente.denteInteiro;
      } else if (_face == FaceDente.denteInteiro) {
        _face = widget.tooth % 10 <= 3
            ? FaceDente.incisal
            : FaceDente.oclusal;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    if (_face == null && _isWholeToothCondition(_condicaoId)) {
      _face = FaceDente.denteInteiro;
    }
  }

  @override
  void dispose() {
    _observacao.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      OdontogramaRegistroInput(
        numeroDente: widget.tooth,
        face: _face!,
        condicaoId: _condicaoId!,
        observacao: _observacao.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.registro == null
          ? 'Nova condi\u00e7\u00e3o · dente ${widget.tooth}'
          : 'Editar condi\u00e7\u00e3o · dente ${widget.tooth}',
    ),
    content: SizedBox(
      width: 420,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: _condicaoId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Condi\u00e7\u00e3o odontol\u00f3gica',
                ),
                items: [
                  for (final condicao in widget.condicoes)
                    DropdownMenuItem(
                      value: condicao.id,
                      child: Text(condicao.nome),
                    ),
                ],
                onChanged: _onConditionChanged,
                validator: (value) =>
                    value == null ? 'Selecione a condi\u00e7\u00e3o.' : null,
              ),
              if (_isWholeToothCondition(_condicaoId)) ...[
                const SizedBox(height: 8),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Essa condi\u00e7\u00e3o ser\u00e1 registrada no dente inteiro. Voc\u00ea pode escolher uma face espec\u00edfica se necess\u00e1rio.',
                  ),
                ),
              ],
              const SizedBox(height: 14),
              DropdownButtonFormField<FaceDente>(
                key: ValueKey<FaceDente?>(_face),
                initialValue: _face,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Face do dente'),
                items: [
                  for (final face in _faceOptions)
                    DropdownMenuItem(value: face, child: Text(face.label)),
                ],
                onChanged: (value) => setState(() => _face = value),
                validator: (value) =>
                    value == null ? 'Selecione a face.' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _observacao,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Observação (opcional)',
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancelar'),
      ),
      FilledButton(onPressed: _save, child: const Text('Salvar')),
    ],
  );
}
