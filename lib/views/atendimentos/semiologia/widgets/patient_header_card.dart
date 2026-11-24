part of '../formulario_semiologia_view.dart';

class _PatientHeaderCard extends StatelessWidget {
  const _PatientHeaderCard({
    required this.paciente,
    required this.atendimentoId,
    required this.fichaId,
  });

  final PacienteModel paciente;
  final int atendimentoId;
  final int fichaId;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final p = paciente;
    final info = [
      if (p.cpf != null) 'CPF: ${_maskCpf(p.cpf)}',
      if (p.dataNascimento != null) _formatBirth(p.dataNascimento),
      if (p.sexo != null) p.sexo!,
    ].join('   •   ');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface(dark),
        border: Border.all(color: _lineColor(dark)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: dark ? null : [BoxShadow(color: const Color(0xFF102B53).withValues(alpha: .05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: dark ? const Color(0xFF0A356D) : const Color(0xFFE4ECFB),
          foregroundColor: dark ? const Color(0xFFE3ECFC) : AppTheme.navy,
          child: Text(_initials(p.nomeCompleto), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.nomeCompleto ?? 'Paciente', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: _heading(dark), fontSize: 19, fontWeight: FontWeight.w800)),
            if (info.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(info, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: _mutedColor(dark), fontSize: 12.5)),
            ],
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.assignment_outlined, size: 18, color: _link(dark)),
              const SizedBox(width: 6),
              Flexible(
                child: Text('Atendimento: $atendimentoId · Ficha: $fichaId', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: _link(dark), fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }
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
  final now = DateTime.now();
  final age = now.year - date.year - ((now.month < date.month || (now.month == date.month && now.day < date.day)) ? 1 : 0);
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ($age anos)';
}
