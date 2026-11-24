import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/paciente_model.dart';
import '../../widgets/cabecalho_pagina_aluno.dart';

class RevisaoFichaSecao {
  const RevisaoFichaSecao({
    required this.title,
    required this.summary,
    this.completed = true,
  });

  final String title;
  final String summary;
  final bool completed;
}

class RevisaoFichaAlunoView extends StatefulWidget {
  const RevisaoFichaAlunoView({
    required this.paciente,
    required this.fichaId,
    required this.atendimentoId,
    required this.fichaDescricao,
    required this.statusLabel,
    required this.sections,
    required this.onSubmit,
    super.key,
  });

  final PacienteModel paciente;
  final int fichaId;
  final int atendimentoId;
  final String fichaDescricao;
  final String statusLabel;
  final List<RevisaoFichaSecao> sections;
  final Future<String?> Function() onSubmit;

  @override
  State<RevisaoFichaAlunoView> createState() => _RevisaoFichaAlunoViewState();
}

class _RevisaoFichaAlunoViewState extends State<RevisaoFichaAlunoView> {
  bool _isSubmitting = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    final error = await widget.onSubmit();
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _isSubmitting = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = EstiloPaginaAluno.accent(context);
    final foreground = dark ? AppTheme.darkText : AppTheme.navy;
    final muted = dark ? const Color(0xFFB9C7DD) : const Color(0xFF52647E);
    final surface = dark ? AppTheme.darkSurface : Colors.white;
    final border = dark ? const Color(0xFF34445C) : const Color(0xFFDCE3ED);

    return Scaffold(
      backgroundColor: EstiloPaginaAluno.background(context),
      body: Column(
        children: [
          const CabecalhoPaginaAluno(
            title: 'Revisar avaliação',
            subtitle: 'Confira o resumo antes de enviar para aprovação.',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              children: [
                _patientCard(
                  context,
                  foreground,
                  muted,
                  surface,
                  border,
                  accent,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: surface,
                    border: Border.all(color: border),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.assignment_outlined, color: accent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.fichaDescricao,
                              style: TextStyle(
                                color: foreground,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Atendimento ${widget.atendimentoId} · Ficha ${widget.fichaId} · ${widget.statusLabel}',
                              style: TextStyle(color: muted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Resumo da ficha',
                  style: TextStyle(
                    color: foreground,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Revise as informações abaixo antes de enviar.',
                  style: TextStyle(color: muted, fontSize: 13),
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < widget.sections.length; i++) ...[
                  _sectionCard(
                    widget.sections[i],
                    i + 1,
                    foreground,
                    muted,
                    surface,
                    border,
                    dark,
                  ),
                  const SizedBox(height: 9),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
          _actions(context, accent, dark),
        ],
      ),
    );
  }

  Widget _patientCard(
    BuildContext context,
    Color foreground,
    Color muted,
    Color surface,
    Color border,
    Color accent,
  ) {
    final name = widget.paciente.nomeCompleto?.trim().isNotEmpty == true
        ? widget.paciente.nomeCompleto!.trim()
        : 'Paciente';
    final initials = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    final details = <String>[
      if (widget.paciente.cpf?.isNotEmpty == true)
        'CPF: ${_formatCpf(widget.paciente.cpf!)}',
      if (widget.paciente.dataNascimento?.isNotEmpty == true)
        'Nasc.: ${_formatDate(widget.paciente.dataNascimento!)}',
      if (widget.paciente.sexo?.isNotEmpty == true) widget.paciente.sexo!,
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 27,
            backgroundColor: accent.withValues(alpha: .10),
            child: Text(
              initials.isEmpty ? 'P' : initials,
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    details.join('  •  '),
                    style: TextStyle(color: muted, fontSize: 11.5),
                  ),
                ],
                if (widget.paciente.prontuarioId != null)
                  Text(
                    'Prontuário: ${widget.paciente.prontuarioId.toString().padLeft(6, '0')}',
                    style: TextStyle(color: muted, fontSize: 11.5),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(
    RevisaoFichaSecao section,
    int number,
    Color foreground,
    Color muted,
    Color surface,
    Color border,
    bool dark,
  ) {
    final color = section.completed
        ? (dark ? const Color(0xFF79D6A5) : const Color(0xFF16834B))
        : muted;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: surface,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 29,
            height: 29,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: section.completed
                  ? color.withValues(alpha: .12)
                  : muted.withValues(alpha: .10),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: TextStyle(
                color: section.completed ? color : muted,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.title,
                  style: TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  section.summary,
                  style: TextStyle(color: muted, fontSize: 12, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          Icon(
            section.completed ? Icons.check_circle_outline : Icons.info_outline,
            color: color,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _actions(BuildContext context, Color accent, bool dark) => Container(
    decoration: BoxDecoration(
      color: dark ? AppTheme.darkSurface : Colors.white,
      border: Border(
        top: BorderSide(
          color: dark ? const Color(0xFF34445C) : const Color(0xFFDCE3ED),
        ),
      ),
    ),
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
    child: SafeArea(
      top: false,
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _isSubmitting
                  ? null
                  : () => Navigator.of(context).pop(),
              icon: const Icon(Icons.edit_outlined),
              label: const Text(
                'Voltar e editar',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: accent,
                minimumSize: const Size.fromHeight(50),
                side: BorderSide(color: accent),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_outlined),
              label: const Text(
                'Enviar para aprovação',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: dark ? AppTheme.gold : AppTheme.navy,
                foregroundColor: dark ? AppTheme.navy : Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  String _formatCpf(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 11) return value;
    return '${digits.substring(0, 3)}.${digits.substring(3, 6)}.${digits.substring(6, 9)}-${digits.substring(9)}';
  }

  String _formatDate(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
  }
}
