part of '../prontuario_view.dart';

class _RecordTabs extends StatelessWidget {
  const _RecordTabs({required this.selected, required this.dark, required this.onSelected});
  final int selected;
  final bool dark;
  final ValueChanged<int> onSelected;

  static const tabs = [
    (Icons.view_agenda_outlined, 'Resumo'),
    (Icons.assignment_outlined, 'Avaliação inicial'),
    (Icons.content_paste_search, 'Atendimentos'),
    (Icons.medical_services_outlined, 'Odontogramas'),
    (Icons.biotech_outlined, 'Exames'),
    (Icons.description_outlined, 'Documentos'),
  ];

  @override
  Widget build(BuildContext context) {
    final line = dark ? const Color(0xFF263A56) : const Color(0xFFE3E9F3);
    final idle = dark ? const Color(0xFF9DAFCC) : const Color(0xFF1E3A8A);
    final on = dark ? AppTheme.gold : AppTheme.navy;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF0C1A2D) : Colors.white,
        border: Border.all(color: line),
        borderRadius: BorderRadius.circular(16),
        boxShadow: dark ? null : [BoxShadow(color: const Color(0xFF102B53).withValues(alpha: .05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: LayoutBuilder(builder: (context, box) {
        final itemWidth = (box.maxWidth / tabs.length) < 88 ? 88.0 : box.maxWidth / tabs.length;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (var i = 0; i < tabs.length; i++) ...[
              if (i > 0) Container(width: 1, height: 46, color: line),
              InkWell(
                onTap: () => onSelected(i),
                child: Container(
                  width: itemWidth - (i > 0 ? 1 : 0),
                  height: 82,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: selected == i ? AppTheme.gold : Colors.transparent, width: 3))),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    selected == i
                        ? Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(color: on, borderRadius: BorderRadius.circular(9)),
                            child: Icon(tabs[i].$1, color: dark ? AppTheme.navy : Colors.white, size: 20),
                          )
                        : SizedBox(width: 34, height: 34, child: Icon(tabs[i].$1, color: idle, size: 26)),
                    const SizedBox(height: 5),
                    Text(
                      tabs[i].$2,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: selected == i ? on : idle, fontSize: 11.5, height: 1.15, fontWeight: selected == i ? FontWeight.w800 : FontWeight.w500),
                    ),
                  ]),
                ),
              ),
            ],
          ]),
        );
      }),
    );
  }
}
