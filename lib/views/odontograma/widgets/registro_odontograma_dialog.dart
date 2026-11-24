part of '../odontograma_view.dart';

class _RegistroDialog extends StatefulWidget {
  const _RegistroDialog({
    required this.tooth,
    required this.condicoes,
    this.registro,
  });

  final int tooth;
  final List<CondicaoOdontologicaModel> condicoes;
  final OdontogramaRegistroModel? registro;

  @override
  State<_RegistroDialog> createState() => _RegistroDialogState();
}

class _RegistroDialogState extends State<_RegistroDialog> {
  static const _wholeToothConditionCodes = <String>{
    'EXTRACAO_INDICADA',
    'PROTESE',
    'AUSENTE',
    'NAO_ERUPCIONADO',
    'IMPLANTE',
    'RAIZ_RESIDUAL',
    'COROA',
  };

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _observacao = TextEditingController(
    text: widget.registro?.observacao ?? '',
  );
  late int? _condicaoId = widget.registro?.condicaoId;
  late FaceDente? _face = widget.registro?.face;

  List<FaceDente> get _faceOptions {
    final options = MapaDentes.facesForTooth(widget.tooth);
    if (_face != null && !options.contains(_face)) options.add(_face!);
    return options;
  }

  bool _isWholeToothCondition(int? id) {
    if (id == null) return false;
    return widget.condicoes.any(
      (condition) =>
          condition.id == id &&
          _wholeToothConditionCodes.contains(condition.codigo.toUpperCase()),
    );
  }

  void _onConditionChanged(int? id) {
    setState(() {
      _condicaoId = id;
      if (_isWholeToothCondition(id)) {
        _face = FaceDente.denteInteiro;
      } else if (_face == FaceDente.denteInteiro) {
        _face = widget.tooth % 10 <= 3
            ? FaceDente.incisal
            : FaceDente.oclusal;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    if (_face == null && _isWholeToothCondition(_condicaoId)) {
      _face = FaceDente.denteInteiro;
    }
  }

  @override
  void dispose() {
    _observacao.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      OdontogramaRegistroInput(
        numeroDente: widget.tooth,
        face: _face!,
        condicaoId: _condicaoId!,
        observacao: _observacao.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.registro == null
          ? 'Nova condi\u00e7\u00e3o · dente ${widget.tooth}'
          : 'Editar condi\u00e7\u00e3o · dente ${widget.tooth}',
    ),
    content: SizedBox(
      width: 420,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: _condicaoId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Condi\u00e7\u00e3o odontol\u00f3gica',
                ),
                items: [
                  for (final condicao in widget.condicoes)
                    DropdownMenuItem(
                      value: condicao.id,
                      child: Text(condicao.nome),
                    ),
                ],
                onChanged: _onConditionChanged,
                validator: (value) =>
                    value == null ? 'Selecione a condi\u00e7\u00e3o.' : null,
              ),
              if (_isWholeToothCondition(_condicaoId)) ...[
                const SizedBox(height: 8),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Essa condi\u00e7\u00e3o ser\u00e1 registrada no dente inteiro. Voc\u00ea pode escolher uma face espec\u00edfica se necess\u00e1rio.',
                  ),
                ),
              ],
              const SizedBox(height: 14),
              DropdownButtonFormField<FaceDente>(
                key: ValueKey<FaceDente?>(_face),
                initialValue: _face,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Face do dente'),
                items: [
                  for (final face in _faceOptions)
                    DropdownMenuItem(value: face, child: Text(face.label)),
                ],
                onChanged: (value) => setState(() => _face = value),
                validator: (value) =>
                    value == null ? 'Selecione a face.' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _observacao,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Observação (opcional)',
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancelar'),
      ),
      FilledButton(onPressed: _save, child: const Text('Salvar')),
    ],
  );
}
