part of '../pendencias_professor_view.dart';

class _Header extends StatelessWidget {
  const _Header({
    required this.dark,
    required this.compact,
    required this.onSearch,
  });
  final bool dark, compact;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).colorScheme.onSurface;
    final muted = dark ? const Color(0xFFB9C7DD) : const Color(0xFF52647E);
    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 8 : 18, 14, compact ? 8 : 18, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pendências de aprovação',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: fg,
                    fontSize: compact ? 20 : 27,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Visualize todas as fichas aguardando sua revisão.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: muted, fontSize: compact ? 11 : 14),
                ),
              ],
            ),
          ),
          if (!compact) const SizedBox(width: 18),
          if (!compact)
            SizedBox(
              width: 300,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: onSearch,
                icon: const Icon(Icons.search),
                label: const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Buscar paciente por nome, CPF ou código...',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: dark
                      ? const Color(0xFFD6E4FA)
                      : AppTheme.navy,
                  side: BorderSide(
                    color: dark
                        ? const Color(0xFF34445C)
                        : const Color(0xFFDCE3ED),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          const BotaoAlternarTema(),
          IconButton(
            tooltip: 'Notificações',
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Abas por tipo de ficha + botão Filtros
// ---------------------------------------------------------------------------

class _Tabs extends StatelessWidget {
  const _Tabs({
    required this.all,
    required this.selected,
    required this.dark,
    required this.line,
    required this.card,
    required this.onSelect,
    required this.onFilters,
  });
  final List<ProfessorFichaModel> all;
  final String selected;
  final bool dark;
  final Color line, card;
  final ValueChanged<String> onSelect;
  final VoidCallback onFilters;

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final f in all) {
      final t = _FichaInfo(f).tipo;
      counts[t] = (counts[t] ?? 0) + 1;
    }
    final tipos = counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
    final fg = dark ? const Color(0xFFD6E4FA) : AppTheme.navy;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _TabChip(
          label: 'Todas',
          count: all.length,
          active: selected == 'Todas',
          dark: dark,
          line: line,
          card: card,
          onTap: () => onSelect('Todas'),
        ),
        for (final t in tipos)
          _TabChip(
            label: t,
            count: counts[t]!,
            active: selected == t,
            dark: dark,
            line: line,
            card: card,
            onTap: () => onSelect(t),
          ),
        OutlinedButton.icon(
          onPressed: onFilters,
          icon: const Icon(Icons.filter_alt_outlined, size: 18),
          label: const Text('Filtros'),
          style: OutlinedButton.styleFrom(
            foregroundColor: fg,
            minimumSize: const Size(0, 46),
            backgroundColor: card,
            side: BorderSide(color: line),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.count,
    required this.active,
    required this.dark,
    required this.line,
    required this.card,
    required this.onTap,
  });
  final String label;
  final int count;
  final bool active, dark;
  final Color line, card;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = active
        ? (dark
              ? AppTheme.gold.withValues(alpha: .18)
              : const Color(0xFFFDEFB8))
        : card;
    final fg = dark ? const Color(0xFFD6E4FA) : AppTheme.navy;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: active ? AppTheme.gold : line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: active
                      ? AppTheme.navy
                      : (dark
                            ? const Color(0xFF14243A)
                            : const Color(0xFFE8EEFB)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.white : fg,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tabela
// ---------------------------------------------------------------------------

class _Footer extends StatelessWidget {
  const _Footer({
    required this.shown,
    required this.total,
    required this.page,
    required this.totalPages,
    required this.perPage,
    required this.dark,
    required this.muted,
    required this.line,
    required this.card,
    required this.onPage,
    required this.onPerPage,
  });
  final int shown, total, page, totalPages, perPage;
  final bool dark;
  final Color muted, line, card;
  final ValueChanged<int> onPage;
  final ValueChanged<int> onPerPage;

  @override
  Widget build(BuildContext context) {
    final fg = dark ? const Color(0xFFD6E4FA) : AppTheme.navy;

    Widget pageButton(int p) {
      final active = p == page;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Material(
          color: active ? AppTheme.navy : card,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: () => onPage(p),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: active ? AppTheme.navy : line),
              ),
              child: Text(
                '${p + 1}',
                style: TextStyle(
                  color: active ? Colors.white : fg,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 12,
      spacing: 16,
      children: [
        Text(
          'Mostrando $shown de $total pendências',
          style: TextStyle(color: muted, fontSize: 13),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Anterior',
              onPressed: page > 0 ? () => onPage(page - 1) : null,
              icon: const Icon(Icons.chevron_left),
            ),
            for (var p = 0; p < totalPages; p++) pageButton(p),
            IconButton(
              tooltip: 'Próxima',
              onPressed: page < totalPages - 1 ? () => onPage(page + 1) : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Itens por página',
              style: TextStyle(color: muted, fontSize: 13),
            ),
            const SizedBox(width: 12),
            Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: card,
                border: Border.all(color: line),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: perPage,
                  dropdownColor: card,
                  style: TextStyle(color: fg, fontSize: 14),
                  items: const [10, 20, 50]
                      .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) onPerPage(v);
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
