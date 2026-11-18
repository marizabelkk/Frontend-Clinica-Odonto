/// Review data is kept as received because API v2 does not define its schema.
class ProfessorFichaDto {
  const ProfessorFichaDto({required this.id, required this.data});

  final int id;
  final Map<String, dynamic> data;

  factory ProfessorFichaDto.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! int) {
      throw const FormatException('Ficha sem identificador inteiro.');
    }
    return ProfessorFichaDto(id: id, data: Map.unmodifiable(json));
  }

  String get status => data['status']?.toString() ?? 'STATUS NÃO INFORMADO';
}

enum DecisaoProfessor {
  aprovada('APROVADA'),
  correcaoSolicitada('CORRECAO_SOLICITADA');

  const DecisaoProfessor(this.apiValue);
  final String apiValue;
}
