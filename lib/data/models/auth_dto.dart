import 'usuario_dto.dart';

class LoginRequestDto {
  const LoginRequestDto({required this.email, required this.senha});

  final String email;
  final String senha;

  Map<String, dynamic> toJson() => {'email': email, 'senha': senha};
}

class LoginResponseDto {
  const LoginResponseDto({
    required this.accessToken,
    required this.tokenType,
    required this.usuario,
  });

  final String accessToken;
  final String tokenType;
  final UsuarioDto usuario;

  factory LoginResponseDto.fromJson(Map<String, dynamic> json) =>
      LoginResponseDto(
        accessToken: json['access_token'] as String,
        tokenType: json['token_type'] as String,
        usuario: UsuarioDto.fromJson(
          Map<String, dynamic>.from(json['usuario'] as Map),
        ),
      );
}
