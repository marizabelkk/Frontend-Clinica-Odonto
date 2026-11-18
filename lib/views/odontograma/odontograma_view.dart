import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/odontograma_dto.dart';
import '../../data/viewmodels/odontograma_view_model.dart';
import '../widgets/theme_toggle_button.dart';
import 'odontograma_chart.dart';
import 'tooth_map.dart';

/// Tela do odontograma: toque no dente, veja os defeitos registrados abaixo e
/// (quando `canEdit`) adicione, edite ou exclua defeitos do atendimento atual.
class OdontogramaView extends StatefulWidget {
  const OdontogramaView({
    required this.prontuarioId,
    this.atendimentoId,
    this.canEdit = false,
    this.pacienteNome,
    super.key,
  });

  final int prontuarioId;

  /// Atendimento em andamento (necessário para registrar/editar/excluir).
  final int? atendimentoId;
  final bool canEdit;
  final String? pacienteNome;

  @override
  State<OdontogramaView> createState() => _OdontogramaViewState();
}

class _OdontogramaViewState extends State<OdontogramaView> {
  bool get _canEdit => widget.canEdit && widget.atendimentoId != null;

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

  Future<void> _addOrEdit({OdontogramaRegistroDto? registro}) async {
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
          (registro == null ? 'Defeito registrado.' : 'Defeito atualizado.'),
    );
  }

  Future<void> _delete(OdontogramaRegistroDto registro) async {
    final model = context.read<OdontogramaViewModel>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir defeito?'),
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
    _snack(error ?? 'Defeito excluído.');
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Odontograma'),
        backgroundColor: dark ? AppTheme.darkSurface : colors.primary,
        foregroundColor: dark ? AppTheme.gold : Colors.white,
        actions: [
          IconButton(
            tooltip: 'Recarregar',
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
          const ThemeToggleButton(),
        ],
      ),
      body: Consumer<OdontogramaViewModel>(
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
                    const Icon(Icons.cloud_off_outlined, size: 42),
                    const SizedBox(height: 12),
                    Text(model.errorMessage!, textAlign: TextAlign.center),
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

          final chart = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OdontogramaChart(
                registrosPorDente: model.registrosPorDente,
                selectedTooth: model.selectedTooth,
                onToothTap: model.selectTooth,
              ),
              const SizedBox(height: 10),
              _Legend(model: model),
            ],
          );
          final panel = _ToothPanel(
            model: model,
            canEdit: _canEdit,
            atendimentoId: widget.atendimentoId,
            onAdd: () => _addOrEdit(),
            onEdit: (registro) => _addOrEdit(registro: registro),
            onDelete: _delete,
          );

          return LayoutBuilder(
            builder: (context, constraints) {
              final header = _Header(
                pacienteNome: widget.pacienteNome,
                canEdit: _canEdit,
              );
              if (constraints.maxWidth >= 900) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: SingleChildScrollView(child: chart),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 4,
                        child: ListView(children: [header, panel]),
                      ),
                    ],
                  ),
                );
              }
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [header, chart, const SizedBox(height: 12), panel],
              );
            },
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.pacienteNome, required this.canEdit});

  final String? pacienteNome;
  final bool canEdit;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      [
        ?pacienteNome,
        canEdit
            ? 'Toque em um dente para ver e registrar defeitos.'
            : 'Consulta: toque em um dente para ver os defeitos registrados.',
      ].join(' · '),
      style: Theme.of(context).textTheme.bodyMedium,
    ),
  );
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
              _Dot(color: OdontogramaChart.colorForCondicao(id)),
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
    required this.canEdit,
    required this.atendimentoId,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final OdontogramaViewModel model;
  final bool canEdit;
  final int? atendimentoId;
  final VoidCallback onAdd;
  final ValueChanged<OdontogramaRegistroDto> onEdit;
  final ValueChanged<OdontogramaRegistroDto> onDelete;

  @override
  Widget build(BuildContext context) {
    final tooth = model.selectedTooth;
    final registros = model.selectedToothRegistros;
    final withDefects = model.registrosPorDente.keys.toList()..sort();
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Defeitos do dente', style: textTheme.titleMedium),
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              key: ValueKey<int?>(tooth),
              initialValue: tooth,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Dente (numeração FDI)',
              ),
              items: [
                for (final number in ToothMap.shapes.keys.toList()..sort())
                  DropdownMenuItem(
                    value: number,
                    child: Text(ToothMap.describe(number)),
                  ),
              ],
              onChanged: model.selectTooth,
            ),
            const SizedBox(height: 14),
            if (tooth == null)
              const Text(
                'Toque em um dente do odontograma (ou escolha na lista acima) para ver os defeitos registrados.',
              )
            else ...[
              Text(ToothMap.describe(tooth), style: textTheme.titleSmall),
              const SizedBox(height: 6),
              if (registros.isEmpty)
                const Text('Nenhum defeito registrado neste dente.')
              else
                for (final registro in registros)
                  _RegistroTile(
                    registro: registro,
                    condicaoNome: model.condicaoNome(registro.condicaoId),
                    canModify:
                        canEdit && registro.atendimentoId == atendimentoId,
                    busy: model.isSaving,
                    onEdit: () => onEdit(registro),
                    onDelete: () => onDelete(registro),
                  ),
              if (canEdit) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  key: const Key('odontograma-add'),
                  onPressed: model.isSaving ? null : onAdd,
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar defeito'),
                ),
              ],
            ],
            if (withDefects.isNotEmpty) ...[
              const Divider(height: 28),
              Text(
                'Dentes com defeitos registrados',
                style: textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final number in withDefects)
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
    required this.canModify,
    required this.busy,
    required this.onEdit,
    required this.onDelete,
  });

  final OdontogramaRegistroDto registro;
  final String condicaoNome;
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
        color: OdontogramaChart.colorForCondicao(registro.condicaoId),
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
  final List<CondicaoOdontologicaDto> condicoes;
  final OdontogramaRegistroDto? registro;

  @override
  State<_RegistroDialog> createState() => _RegistroDialogState();
}

class _RegistroDialogState extends State<_RegistroDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _observacao = TextEditingController(
    text: widget.registro?.observacao ?? '',
  );
  late int? _condicaoId = widget.registro?.condicaoId;
  late FaceDente? _face = widget.registro?.face;

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
          ? 'Novo defeito · dente ${widget.tooth}'
          : 'Editar defeito · dente ${widget.tooth}',
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
                  labelText: 'Defeito / condição',
                ),
                items: [
                  for (final condicao in widget.condicoes)
                    DropdownMenuItem(
                      value: condicao.id,
                      child: Text(condicao.nome),
                    ),
                ],
                onChanged: (value) => setState(() => _condicaoId = value),
                validator: (value) =>
                    value == null ? 'Selecione o defeito.' : null,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<FaceDente>(
                initialValue: _face,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Face do dente'),
                items: [
                  for (final face in FaceDente.values)
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
