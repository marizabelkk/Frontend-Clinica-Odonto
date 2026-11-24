part of '../prontuario_view.dart';

class _CabecalhoProntuario extends StatelessWidget {
  const _CabecalhoProntuario({required this.title, required this.actions});
  final String title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Container(
        color: AppTheme.navy,
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: 62,
            child: Row(children: [
              SizedBox(
                width: 104,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.chevron_left, size: 30),
                    label: const Text('Voltar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    style: TextButton.styleFrom(foregroundColor: Colors.white, padding: const EdgeInsets.only(left: 6, right: 8)),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800),
                ),
              ),
              SizedBox(
                width: 104,
                child: Align(alignment: Alignment.centerRight, child: Row(mainAxisSize: MainAxisSize.min, children: actions)),
              ),
            ]),
          ),
        ),
      );
}
