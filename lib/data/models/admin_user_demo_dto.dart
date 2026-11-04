import 'usuario_dto.dart';

/// UI-only user data for the Admin prototype until the API adds user management.
class AdminUserDemoDto {
  const AdminUserDemoDto({
    required this.id,
    required this.nome,
    required this.email,
    required this.perfil,
    required this.ativo,
    this.matricula,
    this.observacao,
  });

  final int id;
  final String nome;
  final String email;
  final PerfilUsuario perfil;
  final bool ativo;
  final String? matricula;
  final String? observacao;

  AdminUserDemoDto copyWith({bool? ativo}) => AdminUserDemoDto(
    id: id,
    nome: nome,
    email: email,
    perfil: perfil,
    ativo: ativo ?? this.ativo,
    matricula: matricula,
    observacao: observacao,
  );
}
