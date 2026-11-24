part of '../pendencias_professor_view.dart';

// ---------------------------------------------------------------------------

class _FichaInfo {
  _FichaInfo(this.ficha);
  final ProfessorFichaModel ficha;

  Map<dynamic, dynamic>? get _paciente =>
      ficha.data['paciente'] is Map ? ficha.data['paciente'] as Map : null;
  Map<dynamic, dynamic>? get _aluno {
    final a = ficha.data['aluno'] ?? ficha.data['aluno_responsavel'];
    return a is Map ? a : null;
  }

  String get paciente =>
      _paciente?['nome_completo']?.toString() ?? 'Ficha #${ficha.id}';

  String get cpfMascarado {
    final digits = (_paciente?['cpf']?.toString() ?? '').replaceAll(
      RegExp(r'\D'),
      '',
    );
    if (digits.length < 2) return 'Ficha #${ficha.id}';
    return 'CPF: ***.***.***-${digits.substring(digits.length - 2)}';
  }

  String get iniciais => paciente
      .trim()
      .split(RegExp(r'\s+'))
      .take(2)
      .map((s) => s.isEmpty ? '' : s[0].toUpperCase())
      .join();

  String get tipo =>
      (ficha.data['tipo'] ??
              ficha.data['tipo_ficha'] ??
              ficha.data['categoria'] ??
              'Ficha clínica')
          .toString();

  String get subtipo =>
      (ficha.data['subtipo'] ??
              ficha.data['procedimento'] ??
              ficha.data['descricao'] ??
              '')
          .toString();

  String get aluno => _aluno?['nome']?.toString() ?? '—';

  String get turma =>
      (_aluno?['turma'] ?? _aluno?['matricula'] ?? '').toString();

  DateTime? get enviadaEm {
    final raw =
        ficha.data['enviada_em'] ??
        ficha.data['data_envio'] ??
        ficha.data['created_at'];
    return raw == null ? null : DateTime.tryParse(raw.toString())?.toLocal();
  }

  String get enviadaFormatada {
    final d = enviadaEm;
    if (d == null) return '—';
    String p(int n) => n.toString().padLeft(2, '0');
    return '${p(d.day)}/${p(d.month)}/${d.year}, ${p(d.hour)}:${p(d.minute)}';
  }

  Duration? get pendenteHa {
    final d = enviadaEm;
    return d == null ? null : DateTime.now().difference(d);
  }

  String get pendenteTexto {
    final d = pendenteHa;
    if (d == null) return '—';
    if (d.inDays >= 2) return '${d.inDays} dias';
    if (d.inDays == 1) return '1 dia';
    if (d.inHours >= 1) return '${d.inHours} horas';
    return 'Agora há pouco';
  }

  /// 0 = normal, 1 = atenção (1 dia), 2 = urgente (2+ dias)
  int get urgencia {
    final d = pendenteHa;
    if (d == null) return 0;
    if (d.inDays >= 2) return 2;
    if (d.inDays >= 1) return 1;
    return 0;
  }

  Color get corTipo {
    final t = tipo.toLowerCase();
    if (t.contains('cirurg')) return const Color(0xFF16A34A);
    if (t.contains('odontoped')) return const Color(0xFFF59E0B);
    return const Color(0xFF1D4ED8);
  }
}

// ---------------------------------------------------------------------------
// Cabeçalho
// ---------------------------------------------------------------------------

class _TableHeader extends StatelessWidget {
  const _TableHeader({required this.muted, required this.dark});
  final Color muted;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: muted,
      fontWeight: FontWeight.w600,
      fontSize: 13,
    );
    return Container(
      color: dark ? const Color(0xFF14243A) : const Color(0xFFEEF3FC),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(flex: 22, child: Text('Paciente', style: style)),
          Expanded(flex: 22, child: Text('Tipo de ficha', style: style)),
          Expanded(flex: 18, child: Text('Aluno responsável', style: style)),
          Expanded(flex: 17, child: Text('Enviada em', style: style)),
          Expanded(flex: 13, child: Text('Tempo pendente', style: style)),
          const SizedBox(width: 120),
        ],
      ),
    );
  }
}

class _PendingRow extends StatelessWidget {
  const _PendingRow({
    required this.ficha,
    required this.dark,
    required this.foreground,
    required this.muted,
    required this.wide,
    required this.onReview,
  });
  final ProfessorFichaModel ficha;
  final bool dark, wide;
  final Color foreground, muted;
  final VoidCallback onReview;

  Color _urgencyColor(int u) => switch (u) {
    2 => const Color(0xFFD92D20),
    1 => const Color(0xFFD97706),
    _ => muted,
  };

  @override
  Widget build(BuildContext context) {
    final info = _FichaInfo(ficha);
    final urgencyColor = _urgencyColor(info.urgencia);

    final avatar = CircleAvatar(
      radius: 21,
      backgroundColor: dark ? const Color(0xFF0A356D) : const Color(0xFFE4ECFB),
      foregroundColor: dark ? const Color(0xFFD5E5FF) : const Color(0xFF1D4ED8),
      child: Text(
        info.iniciais,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      ),
    );

    final paciente = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          info.paciente,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: foreground,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        Text(info.cpfMascarado, style: TextStyle(color: muted, fontSize: 11)),
      ],
    );

    final tipo = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: info.corTipo,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                info.tipo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              if (info.subtipo.isNotEmpty)
                Text(
                  info.subtipo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: muted, fontSize: 11),
                ),
            ],
          ),
        ),
      ],
    );

    final aluno = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          info.aluno,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: foreground,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        if (info.turma.isNotEmpty)
          Text(info.turma, style: TextStyle(color: muted, fontSize: 11)),
      ],
    );

    final tempo = Row(
      children: [
        Icon(Icons.schedule, size: 18, color: urgencyColor),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            info.pendenteTexto,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: urgencyColor,
              fontWeight: info.urgencia > 0 ? FontWeight.w700 : FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );

    final reviewButton = FilledButton(
      onPressed: onReview,
      style: FilledButton.styleFrom(
        minimumSize: const Size(76, 36),
        padding: const EdgeInsets.symmetric(horizontal: 14),
      ),
      child: const Text('Revisar'),
    );

    final menu = PopupMenuButton<String>(
      tooltip: 'Mais ações',
      icon: Icon(
        Icons.more_vert,
        color: dark ? const Color(0xFFD6E4FA) : AppTheme.navy,
      ),
      onSelected: (v) {
        if (v == 'revisar') onReview();
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'revisar', child: Text('Revisar ficha')),
      ],
    );

    return InkWell(
      onTap: onReview,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: wide
            ? Row(
                children: [
                  Expanded(
                    flex: 22,
                    child: Row(
                      children: [
                        avatar,
                        const SizedBox(width: 12),
                        Expanded(child: paciente),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 22,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: tipo,
                    ),
                  ),
                  Expanded(flex: 18, child: aluno),
                  Expanded(
                    flex: 17,
                    child: Text(
                      info.enviadaFormatada,
                      style: TextStyle(color: muted, fontSize: 12),
                    ),
                  ),
                  Expanded(flex: 13, child: tempo),
                  SizedBox(
                    width: 120,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [reviewButton, menu],
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  avatar,
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        paciente,
                        const SizedBox(height: 6),
                        Text(
                          '${info.tipo}${info.subtipo.isEmpty ? '' : ' · ${info.subtipo}'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: foreground, fontSize: 11),
                        ),
                        const SizedBox(height: 4),
                        tempo,
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  reviewButton,
                ],
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Rodapé: contagem, paginação e itens por página
// ---------------------------------------------------------------------------
