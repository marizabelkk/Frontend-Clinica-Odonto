part of '../buscar_paciente_view.dart';

class _PatientCard extends StatelessWidget {
  const _PatientCard({
    required this.paciente,
    required this.dark,
    required this.foreground,
    required this.muted,
    required this.border,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.isDeleting = false,
  });
  final PacienteModel paciente;
  final bool dark;
  final Color foreground;
  final Color muted;
  final Color border;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isDeleting;

  @override
  Widget build(BuildContext context) {
    final initials = (paciente.nomeCompleto ?? '').trim().split(RegExp(r'\s+'));
    final avatar = initials
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return Material(
      color: dark ? const Color(0xFF111F34) : Colors.white,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: border.withValues(alpha: .7)),
            borderRadius: BorderRadius.circular(17),
            boxShadow: dark
                ? null
                : [
                    BoxShadow(
                      color: const Color(0xFF102B53).withValues(alpha: .055),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 27,
                backgroundColor: dark
                    ? const Color(0xFF1C3558)
                    : const Color(0xFFE4EAF8),
                foregroundColor: dark ? const Color(0xFFE0E9F9) : AppTheme.navy,
                child: Text(
                  avatar.isEmpty ? '?' : avatar,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      paciente.nomeCompleto ?? 'Paciente',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'CPF: ${_formatCpf(paciente.cpf)}',
                      style: TextStyle(color: muted, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Nasc.: ${_formatDate(paciente.dataNascimento)}  •  Prontuário: ${paciente.prontuarioId?.toString().padLeft(6, '0') ?? '—'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (onEdit != null || onDelete != null) ...[
                IconButton(
                  tooltip: 'Editar paciente',
                  onPressed: isDeleting ? null : onEdit,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.edit_outlined,
                    color: dark ? AppTheme.gold : AppTheme.navy,
                    size: 21,
                  ),
                ),
                if (onDelete != null)
                  IconButton(
                    tooltip: 'Excluir paciente',
                    onPressed: isDeleting ? null : onDelete,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 21,
                    ),
                  ),
                if (onTap != null)
                  Icon(
                    Icons.chevron_right,
                    color: dark ? AppTheme.gold : AppTheme.navy,
                    size: 27,
                  ),
              ] else if (onTap != null)
                Icon(
                  Icons.chevron_right,
                  color: dark ? AppTheme.gold : AppTheme.navy,
                  size: 27,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatDate(String? value) {
  if (value == null || value.isEmpty) return '—';
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value;
  return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
}

String _formatCpf(String? value) {
  if (value == null || value.trim().isEmpty) return 'Não informado';
  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.length != 11) return value;
  return '${digits.substring(0, 3)}.${digits.substring(3, 6)}.${digits.substring(6, 9)}-${digits.substring(9)}';
}

class _SearchMessage extends StatelessWidget {
  const _SearchMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.foreground,
    required this.muted,
    required this.border,
    this.action,
  });
  final IconData icon;
  final String title;
  final String message;
  final Color foreground;
  final Color muted;
  final Color border;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: CustomPaint(
      painter: _DashedOutline(border),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 44,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.gold
                  : AppTheme.navy,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: foreground,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: muted, fontSize: 14),
            ),
            if (action != null) ...[const SizedBox(height: 10), action!],
          ],
        ),
      ),
    ),
  );
}

class _DashedOutline extends CustomPainter {
  const _DashedOutline(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(rect.deflate(1), const Radius.circular(16)),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + 7).clamp(0, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + 5;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedOutline oldDelegate) =>
      oldDelegate.color != color;
}
