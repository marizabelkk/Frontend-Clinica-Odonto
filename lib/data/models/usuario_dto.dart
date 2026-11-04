enum PerfilUsuario {
  aluno('ALUNO'),
  professor('PROFESSOR'),
  recepcao('RECEPCAO'),
  admin('ADMIN'),
  desconhecido('');

  const PerfilUsuario(this.apiValue);

  final String apiValue;

  static PerfilUsuario fromApi(String value) => switch (value) {
    'ALUNO' => aluno,
    'PROFESSOR' => professor,
    'RECEPCAO' => recepcao,
    'ADMIN' => admin,
    _ => desconhecido,
  };
}

class UsuarioDto {
  const UsuarioDto({
    required this.id,
    required this.nome,
    required this.email,
    required this.perfil,
    this.matricula,
  });

  final int id;
  final String nome;
  final String email;
  final String? matricula;
  final PerfilUsuario perfil;

  factory UsuarioDto.fromJson(Map<String, dynamic> json) => UsuarioDto(
    id: json['id'] as int,
    nome: json['nome'] as String,
    email: json['email'] as String,
    matricula: json['matricula'] as String?,
    perfil: PerfilUsuario.fromApi(json['perfil'] as String? ?? ''),
  );
}
