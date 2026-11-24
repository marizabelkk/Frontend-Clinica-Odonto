part of '../revisar_fichas_view.dart';

// Barra superior
// ---------------------------------------------------------------------------

class _TopBar extends StatelessWidget {
  const _TopBar({required this.p, required this.compact, required this.onSearch});
  final _P p;
  final bool compact;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).colorScheme.onSurface;
    return Row(children: [
      TextButton.icon(
        onPressed: () => Navigator.of(context).maybePop(),
        icon: const Icon(Icons.chevron_left),
        label: const Text('Voltar'),
        style: TextButton.styleFrom(foregroundColor: p.title),
      ),
      Container(width: 1, height: 34, margin: const EdgeInsets.symmetric(horizontal: 12), color: p.line),
      Flexible(
        child: Text('Revisão de ficha', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: fg, fontSize: compact ? 20 : 27, fontWeight: FontWeight.w800, letterSpacing: -.5)),
      ),
      const SizedBox(width: 12),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: p.yellowSoft, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppTheme.gold)),
        child: Text('PENDENTE', style: TextStyle(color: p.dark ? AppTheme.gold : AppTheme.navy, fontSize: 11, fontWeight: FontWeight.w800)),
      ),
      const Spacer(),
      if (!compact)
        SizedBox(
          width: 300,
          height: 44,
          child: OutlinedButton.icon(
            onPressed: onSearch,
            icon: const Icon(Icons.search),
            label: const Align(alignment: Alignment.centerLeft, child: Text('Buscar paciente por nome, CPF ou código...', overflow: TextOverflow.ellipsis)),
            style: OutlinedButton.styleFrom(
              foregroundColor: p.navy,
              side: BorderSide(color: p.line),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      const BotaoAlternarTema(),
      IconButton(tooltip: 'Notificações', onPressed: () {}, icon: const Icon(Icons.notifications_none)),
    ]);
  }
}

// ---------------------------------------------------------------------------
// Cartão do paciente
// ---------------------------------------------------------------------------

class _PatientCard extends StatelessWidget {
  const _PatientCard({required this.p, required this.info, required this.onRecord});
  final _P p;
  final _Info info;
  final VoidCallback onRecord;

  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).colorScheme.onSurface;

    Widget meta(String label, String value, [String? sub]) => Padding(
          padding: const EdgeInsets.only(right: 28),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(color: p.muted, fontSize: 11)),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 14)),
            if (sub != null && sub.isNotEmpty) ...[const SizedBox(height: 4), Text(sub, style: TextStyle(color: p.muted, fontSize: 12))],
          ]),
        );

    final details = [info.nascimentoEIdade, info.sexo].where((e) => e.isNotEmpty).join('  •  ');

    final identity = Row(mainAxisSize: MainAxisSize.min, children: [
      CircleAvatar(
        radius: 34,
        backgroundColor: p.dark ? const Color(0xFF0A356D) : const Color(0xFFE4ECFB),
        foregroundColor: p.dark ? const Color(0xFFD5E5FF) : const Color(0xFF1D4ED8),
        child: Text(info.iniciais, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 24)),
      ),
      const SizedBox(width: 16),
      Flexible(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(info.nome, style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 19)),
          const SizedBox(height: 4),
          Text([info.cpf, details].where((e) => e.isNotEmpty).join('  •  '), style: TextStyle(color: p.muted, fontSize: 12)),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onRecord,
            icon: const Icon(Icons.arrow_forward, size: 16),
            label: const Text('Ver prontuário completo'),
            iconAlignment: IconAlignment.end,
            style: OutlinedButton.styleFrom(foregroundColor: p.title, side: BorderSide(color: p.title.withValues(alpha: .6)), minimumSize: const Size(0, 36)),
          ),
        ]),
      ),
    ]);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: p.card, border: Border.all(color: p.line), borderRadius: BorderRadius.circular(14)),
      child: LayoutBuilder(builder: (context, box) {
        final metas = Wrap(runSpacing: 16, children: [
          meta('Tipo de ficha', info.tipo, info.subtipo),
          meta('Aluno responsável', info.alunoNome, info.alunoMatricula.isEmpty ? null : 'Matrícula: ${info.alunoMatricula}'),
          meta('Enviada em', info.enviadaEm),
          meta('Código do atendimento', info.atendimento),
        ]);
        if (box.maxWidth < 980) {
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [identity, const SizedBox(height: 18), metas]);
        }
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 5, child: identity),
          Container(width: 1, height: 84, margin: const EdgeInsets.symmetric(horizontal: 20), color: p.line),
          Expanded(flex: 6, child: metas),
        ]);
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// Abas
// ---------------------------------------------------------------------------

class _TabsBar extends StatelessWidget {
  const _TabsBar({required this.p, required this.tabs, required this.selected, required this.onSelect});
  final _P p;
  final List<String> tabs;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: p.line))),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (var i = 0; i < tabs.length; i++)
              InkWell(
                onTap: () => onSelect(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: i == selected ? AppTheme.gold : Colors.transparent, width: 3))),
                  child: Text(tabs[i], style: TextStyle(color: i == selected ? p.navy : p.muted, fontWeight: i == selected ? FontWeight.w700 : FontWeight.w500)),
                ),
              ),
          ]),
        ),
      );
}

// ---------------------------------------------------------------------------
// Lista lateral de seções
// ---------------------------------------------------------------------------

class _SectionsList extends StatelessWidget {
  const _SectionsList({required this.p, required this.sections, required this.active, required this.onTap});
  final _P p;
  final List<_Secao> sections;
  final int active;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: p.card, border: Border.all(color: p.line), borderRadius: BorderRadius.circular(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 12),
            child: Text('Seções da ficha', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w800)),
          ),
          for (var i = 0; i < sections.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Material(
                color: i == active ? p.yellowSoft : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: () => onTap(i),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: i == active ? AppTheme.gold : Colors.transparent),
                    ),
                    child: Row(children: [
                      Icon(sections[i].filled ? Icons.check_circle_outline : Icons.radio_button_unchecked, size: 20, color: sections[i].filled ? p.green : p.muted),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text('${i + 1}. ${sections[i].title}', style: TextStyle(color: i == active ? p.navy : p.muted, fontSize: 13, fontWeight: i == active ? FontWeight.w700 : FontWeight.w500)),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
        ]),
      );
}

// ---------------------------------------------------------------------------
// Cartão de seção + campos
// ---------------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.p, required this.index, required this.section, required this.expanded, required this.onToggle});
  final _P p;
  final int index;
  final _Secao section;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final populated = section.fields.entries.where((e) => e.value != null && (e.value is! String || (e.value as String).trim().isNotEmpty)).toList();
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(color: p.card, border: Border.all(color: p.line), borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
            child: Row(children: [
              Expanded(child: Text('$index.  ${section.title}', style: TextStyle(color: p.title, fontWeight: FontWeight.w700, fontSize: 16))),
              Icon(expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: p.title),
            ]),
          ),
        ),
        if (expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: populated.isEmpty
                ? Text('Nenhuma informação registrada nesta seção.', style: TextStyle(color: p.muted))
                : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    for (final e in populated) _Field(p: p, label: e.key, value: e.value),
                  ]),
          ),
      ]),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.p, required this.label, required this.value});
  final _P p;
  final String label;
  final Object? value;

  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 8),
        _valueView(context),
      ]),
    );
  }

  Widget _valueView(BuildContext context) {
    final v = value;
    if (v is Map) {
      return Wrap(spacing: 8, runSpacing: 8, children: [
        for (final e in v.entries) _AnswerChip(p: p, label: _humanize(e.key.toString()), value: e.value),
      ]);
    }
    if (v is bool) return Wrap(children: [_AnswerChip(p: p, label: null, value: v)]);
    final text = v is List ? v.map((i) => i.toString()).join(', ') : v.toString().trim();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: p.field, border: Border.all(color: p.line), borderRadius: BorderRadius.circular(8)),
      child: SelectableText(text, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13.5, height: 1.45)),
    );
  }
}

class _AnswerChip extends StatelessWidget {
  const _AnswerChip({required this.p, required this.label, required this.value});
  final _P p;
  final String? label;
  final Object? value;

  @override
  Widget build(BuildContext context) {
    final yes = value == true;
    final text = value is bool ? (yes ? 'Sim' : 'Não') : (value?.toString() ?? 'Não informado');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: yes ? p.green.withValues(alpha: .12) : p.soft,
        border: Border.all(color: yes ? p.green.withValues(alpha: .5) : p.line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label == null ? text : '$label: $text', style: TextStyle(color: yes ? p.green : p.muted, fontSize: 12, fontWeight: yes ? FontWeight.w700 : FontWeight.w500)),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.p, required this.label});
  final _P p;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(color: p.card, border: Border.all(color: p.line), borderRadius: BorderRadius.circular(14)),
        child: Column(children: [
          Icon(Icons.hourglass_empty, size: 36, color: p.muted),
          const SizedBox(height: 10),
          Text('$label estará disponível nesta área em breve.', textAlign: TextAlign.center, style: TextStyle(color: p.muted)),
        ]),
      );
}

// ---------------------------------------------------------------------------
