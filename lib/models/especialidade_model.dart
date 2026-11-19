class EspecialidadeModel {
  const EspecialidadeModel({
    required this.id,
    required this.nome,
    required this.ativo,
  });

  final int id;
  final String nome;
  final bool ativo;

  factory EspecialidadeModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final nome = json['nome'];
    final ativo = json['ativo'];
    if (id is! int || nome is! String || ativo is! bool) {
      throw const FormatException(
        'A API retornou uma especialidade em formato inválido.',
      );
    }
    return EspecialidadeModel(id: id, nome: nome, ativo: ativo);
  }
}
