part of '../odontograma_view.dart';

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
