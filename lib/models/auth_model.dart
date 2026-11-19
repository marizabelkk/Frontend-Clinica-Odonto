import 'usuario_model.dart';

class LoginRequestModel {
  const LoginRequestModel({required this.email, required this.senha});

  final String email;
  final String senha;

  Map<String, dynamic> toJson() => {'email': email, 'senha': senha};
}

class LoginResponseModel {
  const LoginResponseModel({
    required this.accessToken,
    required this.tokenType,
    required this.usuario,
  });

  final String accessToken;
  final String tokenType;
  final UsuarioModel usuario;

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) =>
      LoginResponseModel(
        accessToken: json['access_token'] as String,
        tokenType: json['token_type'] as String,
        usuario: UsuarioModel.fromJson(
          Map<String, dynamic>.from(json['usuario'] as Map),
        ),
      );
}
