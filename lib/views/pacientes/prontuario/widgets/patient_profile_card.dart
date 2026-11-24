part of '../prontuario_view.dart';

class _PatientProfileCard extends StatelessWidget {
  const _PatientProfileCard({required this.paciente, required this.prontuarioId, required this.expanded, required this.onToggle, required this.onEdit, required this.foreground, required this.muted, required this.dark});
  final PacienteModel paciente;
  final int prontuarioId;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final Color foreground;
  final Color muted;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final border = dark ? const Color(0xFF263A56) : const Color(0xFFE6EBF4);
    final initials = _initials(paciente.nomeCompleto);
    final iconColor = dark ? AppTheme.gold : AppTheme.navy;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? AppTheme.darkSurface : Colors.white,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(24),
        boxShadow: dark ? null : [BoxShadow(color: const Color(0xFF102B53).withValues(alpha: .07), blurRadius: 16, offset: const Offset(0, 5))],
      ),
      child: Column(children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CircleAvatar(
            radius: 38,
            backgroundColor: dark ? const Color(0xFF0A356D) : const Color(0xFFE4ECFB),
            foregroundColor: dark ? const Color(0xFFE3ECFC) : AppTheme.navy,
            child: Text(initials, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(paciente.nomeCompleto ?? 'Paciente', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: _heading(dark), fontSize: 23, fontWeight: FontWeight.w800, letterSpacing: -.4)),
            const SizedBox(height: 6),
            Text('CPF: ${_maskCpf(paciente.cpf)}   •   ${_formatBirth(paciente.dataNascimento)}   •   ${paciente.sexo ?? 'Sexo não informado'}', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: foreground, fontSize: 12.5)),
            if (paciente.celular != null || paciente.rg != null) ...[
              const SizedBox(height: 10),
              Wrap(spacing: 16, runSpacing: 6, children: [
                if (paciente.celular != null)
                  Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.call_outlined, size: 18, color: iconColor), const SizedBox(width: 6), Text(_formatPhone(paciente.celular), style: TextStyle(color: foreground, fontSize: 13))]),
                if (paciente.rg != null)
                  Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.badge_outlined, size: 18, color: iconColor), const SizedBox(width: 6), Text('RG: ${_formatRg(paciente.rg)}', style: TextStyle(color: foreground, fontSize: 13))]),
              ]),
            ],
          ])),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: dark ? const Color(0xFF40350E) : const Color(0xFFFFF1C2), border: Border.all(color: AppTheme.gold), borderRadius: BorderRadius.circular(18)),
            child: Text('Código: ${prontuarioId.toString().padLeft(6, '0')}', style: TextStyle(color: dark ? AppTheme.darkText : AppTheme.navy, fontSize: 12.5, fontWeight: FontWeight.w700)),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Editar paciente',
            onPressed: onEdit,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(width: 38, height: 38),
            padding: EdgeInsets.zero,
            icon: Icon(Icons.edit_outlined, color: dark ? AppTheme.gold : AppTheme.navy, size: 21),
          ),
          TextButton.icon(
            onPressed: onToggle,
            icon: Icon(expanded ? Icons.expand_less : Icons.expand_more, size: 20),
            label: Text(expanded ? 'Ver menos' : 'Ver mais'),
            style: TextButton.styleFrom(foregroundColor: dark ? AppTheme.darkText : AppTheme.navy, textStyle: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ]),
        if (expanded) ...[
          Divider(color: border),
          _DetailLine(label: 'Nascimento', value: _formatBirth(paciente.dataNascimento), foreground: foreground, muted: muted),
          _DetailLine(label: 'Sexo/gênero', value: paciente.sexo ?? 'Não informado', foreground: foreground, muted: muted),
          _DetailLine(label: 'Celular', value: _formatPhone(paciente.celular), foreground: foreground, muted: muted),
          _DetailLine(label: 'RG', value: _formatRg(paciente.rg), foreground: foreground, muted: muted),
        ],
      ]),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value, required this.foreground, required this.muted});
  final String label;
  final String value;
  final Color foreground;
  final Color muted;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(children: [SizedBox(width: 130, child: Text(label, style: TextStyle(color: muted, fontWeight: FontWeight.w600))), Expanded(child: Text(value, style: TextStyle(color: foreground)))]));
}

String _initials(String? name) {
  final parts = (name ?? '').trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  return parts.take(2).map((part) => part[0].toUpperCase()).join();
}

String _maskCpf(String? cpf) {
  if (cpf == null || cpf.isEmpty) return 'Não informado';
  final digits = cpf.replaceAll(RegExp(r'\D'), '');
  if (digits.length != 11) return cpf;
  return '***.***.***-${digits.substring(9)}';
}

String _formatPhone(String? phone) {
  if (phone == null || phone.trim().isEmpty) return 'Não informado';
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 11) {
    return '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-${digits.substring(7)}';
  }
  if (digits.length == 10) {
    return '(${digits.substring(0, 2)}) ${digits.substring(2, 6)}-${digits.substring(6)}';
  }
  return phone;
}

String _formatRg(String? rg) {
  if (rg == null || rg.trim().isEmpty) return 'Não informado';
  final digits = rg.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 9) {
    return '${digits.substring(0, 2)}.${digits.substring(2, 5)}.${digits.substring(5, 8)}-${digits.substring(8)}';
  }
  if (digits.length == 8) {
    return '${digits.substring(0, 1)}.${digits.substring(1, 4)}.${digits.substring(4, 7)}-${digits.substring(7)}';
  }
  return rg;
}

String _formatBirth(String? value) {
  if (value == null || value.isEmpty) return 'Nascimento não informado';
  final raw = value.trim();
  final americanDate = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(raw);
  final date = americanDate == null
      ? DateTime.tryParse(raw)
      : DateTime(
          int.parse(americanDate.group(3)!),
          int.parse(americanDate.group(1)!),
          int.parse(americanDate.group(2)!),
        );
  if (date == null) return value;
  final age = DateTime.now().year - date.year - ((DateTime.now().month < date.month || (DateTime.now().month == date.month && DateTime.now().day < date.day)) ? 1 : 0);
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ($age anos)';
}
