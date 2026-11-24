part of '../formulario_semiologia_view.dart';

// Cabeçalho azul-marinho
// ---------------------------------------------------------------------------

class _CabecalhoFicha extends StatelessWidget {
  const _CabecalhoFicha({
    required this.title,
    required this.subtitle,
    required this.actions,
  });
  final String title;
  final String subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Container(
    color: AppTheme.navy,
    padding: const EdgeInsets.only(bottom: 14),
    child: SafeArea(
      bottom: false,
      child: SizedBox(
        height: 64,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 110),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .92),
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.chevron_left, size: 30),
                  label: const Text(
                    'Voltar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.only(left: 6, right: 8),
                  ),
                ),
                if (actions.isNotEmpty)
                  Row(mainAxisSize: MainAxisSize.min, children: actions),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Indicador de etapas
// ---------------------------------------------------------------------------

class _Stepper extends StatelessWidget {
  const _Stepper({required this.active, required this.onTap});
  final int active;
  final ValueChanged<int> onTap;

  static const _labels = [
    'Queixa e história atual',
    'Histórico médico',
    'Medicamentos e alergias',
    'Hábitos e história odontológica',
    'Exame físico e sinais vitais',
    'Exame extraoral e intraoral',
    'Odontograma',
    'Exames complementares',
    'Diagnóstico e plano',
    'Consentimento e assinatura',
  ];

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final navy = dark ? AppTheme.gold : AppTheme.navy;
    final line = _lineColor(dark);

    return LayoutBuilder(
      builder: (context, box) {
        final slot = math.max(box.maxWidth / _labels.length, 60.0);
        final total = slot * _labels.length;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: total,
            child: Stack(
              children: [
                Positioned(
                  top: 19,
                  left: slot / 2,
                  right: slot / 2,
                  height: 2,
                  child: ColoredBox(color: line),
                ),
                Positioned(
                  top: 19,
                  left: slot / 2,
                  width: (total - slot) * active / (_labels.length - 1),
                  height: 2,
                  child: ColoredBox(color: navy),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < _labels.length; i++)
                      SizedBox(
                        width: slot,
                        child: InkWell(
                          onTap: () => onTap(i),
                          borderRadius: BorderRadius.circular(10),
                          child: Column(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: i == active ? navy : _surface(dark),
                                  border: Border.all(
                                    color: i == active
                                        ? AppTheme.gold
                                        : (i < active ? navy : line),
                                    width: i == active ? 2.5 : 1.5,
                                  ),
                                ),
                                child: Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                    color: i == active
                                        ? (dark ? AppTheme.navy : Colors.white)
                                        : (i < active
                                              ? navy
                                              : _mutedColor(dark)),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 1,
                                ),
                                child: Text(
                                  _labels[i],
                                  textAlign: TextAlign.center,
                                  maxLines: 3,
                                  style: TextStyle(
                                    color: i == active
                                        ? _heading(dark)
                                        : _mutedColor(dark),
                                    fontSize: 10,
                                    height: 1.2,
                                    fontWeight: i == active
                                        ? FontWeight.w800
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Cartões de seção
// ---------------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.number,
    required this.title,
    required this.children,
    this.controller,
    this.onExpanded,
    this.scrollKey,
  });

  final String number;
  final String title;
  final List<Widget> children;
  final ExpansionTileController? controller;
  final VoidCallback? onExpanded;
  final GlobalKey? scrollKey;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return KeyedSubtree(
      key: scrollKey,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: _surface(dark),
          border: Border.all(color: _lineColor(dark)),
          borderRadius: BorderRadius.circular(14),
          boxShadow: dark
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFF102B53).withValues(alpha: .04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: ExpansionTile(
          controller: controller,
          initiallyExpanded: number == '1' || number == '5',
          onExpansionChanged: (open) {
            if (open) onExpanded?.call();
          },
          shape: const Border(),
          collapsedShape: const Border(),
          iconColor: _link(dark),
          collapsedIconColor: _link(dark),
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          leading: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _softFill(dark),
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: TextStyle(
                color: dark ? AppTheme.darkText : AppTheme.navy,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              color: _heading(dark),
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

class _PendingSection extends StatelessWidget {
  const _PendingSection({
    required this.number,
    required this.title,
    this.controller,
    this.onExpanded,
    this.scrollKey,
  });

  final String number;
  final String title;
  final ExpansionTileController? controller;
  final VoidCallback? onExpanded;
  final GlobalKey? scrollKey;

  @override
  Widget build(BuildContext context) => _SectionCard(
    number: number,
    title: title,
    controller: controller,
    onExpanded: onExpanded,
    scrollKey: scrollKey,
    children: const [
      Text(
        'A implementação desta seção depende da definição do payload e dos endpoints correspondentes no contrato da API.',
      ),
    ],
  );
}

// ---------------------------------------------------------------------------
