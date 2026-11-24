part of '../prontuario_view.dart';

class _AttendanceRow extends StatelessWidget {
  const _AttendanceRow({required this.item, required this.dark, required this.foreground, required this.muted, required this.canManage, required this.canView, this.onView, required this.onEdit, required this.onDelete, this.highlight = false});
  final Map<String, dynamic> item;
  final bool dark;
  final Color foreground;
  final Color muted;
  final bool canManage;
  final bool canView;
  final VoidCallback? onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final rawTitle = _firstValue(item, ['especialidade_nome', 'especialidade', 'tipo', 'titulo', 'nome']) ?? 'Atendimento';
    final detail = _firstValue(item, ['descricao', 'queixa_principal', 'procedimento', 'observacao']) ?? 'Avaliação clínica';
    final date = _firstValue(item, ['data_atendimento', 'iniciado_em', 'criado_em', 'data', 'created_at']) ?? 'Data não informada';
    final nestedFicha = item['ficha'];
    final statusRaw = _firstValue(item, ['status', 'status_ficha', 'situacao']) ??
        (nestedFicha is Map ? nestedFicha['status']?.toString() : null);
    final status = statusRaw == null ? null : _statusLabel(statusRaw);
    final color = statusRaw == null ? null : _statusColor(statusRaw);
    final normalizedStatus = statusRaw?.toUpperCase() ?? '';
    final isDraft = normalizedStatus.contains('RASCUN');
    final isCorrection = normalizedStatus.contains('CORRE');
    final hasFicha = item['ficha_id'] != null ||
        (nestedFicha is Map && nestedFicha['id'] != null);
    final canEdit = hasFicha && (isDraft || isCorrection);
    final correctionNote = item['observacao_correcao']?.toString();
    final student = item['aluno_responsavel'];
    final studentName = student is Map ? student['nome']?.toString() : item['aluno']?.toString();
    final reviewer = _firstValue(item, ['professor', 'professor_responsavel', 'revisor', 'aprovado_por']);

    final title = highlight ? 'Realizada em $date' : rawTitle;
    final accent = dark ? AppTheme.gold : AppTheme.navy;
    final showView = canView && hasFicha;

    final viewAction = !showView
        ? null
        : highlight
            ? _PillButton(dark: dark, label: 'Visualizar', onPressed: onView)
            : IconButton(
                tooltip: 'Visualizar ficha',
                onPressed: onView,
                icon: Icon(Icons.chevron_right, color: dark ? AppTheme.darkText : AppTheme.navy, size: 26),
                constraints: const BoxConstraints.tightFor(width: 34, height: 34),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: dark ? const Color(0xFF172A45) : const Color(0xFFEDF2FB),
          foregroundColor: accent,
          child: Icon(highlight ? Icons.assignment_outlined : Icons.medical_services_outlined, size: 26),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: _heading(dark), fontSize: 15.5, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(
            highlight ? (studentName == null ? detail : 'Aluno: $studentName') : detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: foreground, fontSize: 13),
          ),
          if (!highlight)
            Text('$date${studentName == null ? '' : '  •  Aluno: $studentName'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: muted, fontSize: 12)),
          if (highlight && status != null && color != null) ...[
            const SizedBox(height: 5),
            _StatusChip(label: status, color: color, dark: dark),
          ],
          if (correctionNote?.trim().isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                'Observação do professor: $correctionNote',
                style: const TextStyle(color: Color(0xFFD92332), fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
        ])),
        const SizedBox(width: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 140),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!highlight && status != null && color != null) _StatusChip(label: status, color: color, dark: dark),
              if (reviewer != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('Por: $reviewer', textAlign: TextAlign.right, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: muted, fontSize: 11.5)),
                ),
              Row(mainAxisSize: MainAxisSize.min, children: [
                if (canManage && canEdit)
                  IconButton(
                    tooltip: 'Editar ficha',
                    onPressed: onEdit,
                    icon: Icon(Icons.edit_outlined, color: accent, size: 20),
                    constraints: const BoxConstraints.tightFor(width: 34, height: 34),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                if (canManage && (isDraft || !hasFicha))
                  IconButton(
                    tooltip: isDraft ? 'Excluir rascunho' : 'Excluir atendimento',
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, color: Color(0xFFD92332), size: 20),
                    constraints: const BoxConstraints.tightFor(width: 34, height: 34),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                if (viewAction != null) viewAction,
              ]),
            ],
          ),
        ),
      ]),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color, required this.dark});
  final String label;
  final Color color;
  final bool dark;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: color.withValues(alpha: dark ? .22 : .14), borderRadius: BorderRadius.circular(20)),
        child: Text(label, maxLines: 2, textAlign: TextAlign.center, style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w800)),
      );
}

String _itemLabel(Map<String, dynamic> item) {
  final known = _firstValue(item, ['especialidade_nome', 'nome', 'descricao', 'condicao', 'medicamento', 'alergia', 'principio_ativo', 'nome_comercial']);
  if (known != null) return known;
  for (final entry in item.entries) {
    if (['id', 'paciente_id', 'prontuario_id'].contains(entry.key)) continue;
    if (entry.value is String && (entry.value as String).trim().isNotEmpty) {
      return entry.value as String;
    }
  }
  return 'Informação registrada';
}

String? _firstValue(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value is String && value.trim().isNotEmpty) return value;
    if (value is Map && value['nome'] is String) return value['nome'] as String;
  }
  return null;
}

String _statusLabel(String status) {
  final normalized = status.toUpperCase();
  if (normalized.contains('CORRE')) return 'Correção solicitada';
  if (normalized.contains('AGUARD') || normalized.contains('PEND')) return 'Aguardando aprovação';
  if (normalized.contains('APROV')) return 'Aprovado';
  if (normalized.contains('RASCUN')) return 'Rascunho';
  return status;
}

Color _statusColor(String status) {
  final normalized = status.toUpperCase();
  if (normalized.contains('RASCUN')) return const Color(0xFF64748B);
  if (normalized.contains('CORRE')) return const Color(0xFFD92332);
  if (normalized.contains('AGUARD') || normalized.contains('PEND')) return const Color(0xFF1D4ED8);
  if (normalized.contains('APROV')) return const Color(0xFF16813A);
  return const Color(0xFFE59A00);
}
