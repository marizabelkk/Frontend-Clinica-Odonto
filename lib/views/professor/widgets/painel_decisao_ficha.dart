part of '../revisar_fichas_view.dart';

// Painel de decisão
// ---------------------------------------------------------------------------

class _DecisionPanel extends StatelessWidget {
  const _DecisionPanel({
    required this.p,
    required this.model,
    required this.status,
    required this.controller,
    required this.errorText,
    required this.onApprove,
    required this.onReturn,
    required this.onCancel,
    required this.onChanged,
  });
  final _P p;
  final ProfessorViewModel model;
  final String status;
  final TextEditingController controller;
  final String? errorText;
  final VoidCallback onApprove, onReturn, onCancel, onChanged;

  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).colorScheme.onSurface;
    final busy = model.isSubmittingDecision;
    const amber = Color(0xFFD97706);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: p.card, border: Border.all(color: p.line), borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: Text('Status da ficha', style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 16))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: p.yellowSoft, borderRadius: BorderRadius.circular(8)),
            child: Text(status, style: TextStyle(color: p.dark ? AppTheme.gold : const Color(0xFF8A5A00), fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 10),
        Text('Revise todas as informações e decida se a ficha pode ser aprovada ou se precisa de correções.', style: TextStyle(color: p.muted, fontSize: 13, height: 1.4)),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: p.soft, border: Border.all(color: p.line), borderRadius: BorderRadius.circular(10)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.info_outline, size: 20, color: p.title),
              const SizedBox(width: 8),
              Text('Dicas para revisão', style: TextStyle(color: p.title, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 8),
            for (final tip in const [
              'Verifique se todas as seções foram preenchidas corretamente',
              'Confira a coerência das informações',
              'Avalie o diagnóstico e plano propostos',
              'Deixe observações claras ao solicitar correções',
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('•  ', style: TextStyle(color: p.muted)),
                  Expanded(child: Text(tip, style: TextStyle(color: p.muted, fontSize: 12.5, height: 1.35))),
                ]),
              ),
          ]),
        ),
        const SizedBox(height: 18),
        Text.rich(TextSpan(children: [
          TextSpan(text: 'Observações para o aluno ', style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 13)),
          TextSpan(text: '(obrigatória ao devolver)', style: TextStyle(color: p.muted, fontSize: 12)),
        ])),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          minLines: 3,
          maxLines: 5,
          maxLength: 1000,
          onChanged: (_) => onChanged(),
          decoration: InputDecoration(
            hintText: 'Escreva suas observações e orientações para o aluno...',
            errorText: errorText,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 8),
        Text('Ações', style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 10),
        if (model.errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(model.errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13)),
          ),
        FilledButton.icon(
          onPressed: busy ? null : onApprove,
          icon: const Icon(Icons.check),
          label: const Text('Aprovar ficha'),
          style: FilledButton.styleFrom(backgroundColor: p.green, foregroundColor: Colors.white, minimumSize: const Size(0, 46)),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: busy ? null : onReturn,
          icon: const Icon(Icons.assignment_return_outlined),
          label: const Text('Devolver para correção'),
          style: OutlinedButton.styleFrom(
            foregroundColor: p.dark ? AppTheme.gold : const Color(0xFFB45309),
            backgroundColor: p.dark ? Colors.transparent : const Color(0xFFFFF7E0),
            side: const BorderSide(color: amber),
            minimumSize: const Size(0, 46),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: busy ? null : onCancel,
          style: OutlinedButton.styleFrom(foregroundColor: p.navy, side: BorderSide(color: p.line), minimumSize: const Size(0, 46)),
          child: const Text('Cancelar'),
        ),
        if (busy) const Padding(padding: EdgeInsets.only(top: 16), child: Center(child: CircularProgressIndicator())),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: p.soft, borderRadius: BorderRadius.circular(10)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.info_outline, size: 18, color: p.title),
            const SizedBox(width: 10),
            Expanded(child: Text('Ao aprovar, a ficha será finalizada e ficará disponível no prontuário do paciente.', style: TextStyle(color: p.muted, fontSize: 12.5, height: 1.4))),
          ]),
        ),
      ]),
    );
  }
}
