import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/auth_dto.dart';
import '../models/usuario_dto.dart';
import 'auth_repository.dart';

/// Local-only accounts for exploring the profile screens without an API.
/// Enable with `--dart-define=ENABLE_DEMO_AUTH=true` in debug builds.
class DemoAuthRepository extends AuthRepository {
  DemoAuthRepository({required super.apiClient, required super.tokenStore});

  static const bool isEnabled =
      kDebugMode && bool.fromEnvironment('ENABLE_DEMO_AUTH');

  static const demoAccounts = <_DemoAccount>[
    _DemoAccount(
      email: 'aluno@uninassau.edu.br',
      password: 'aluno123',
      user: UsuarioDto(
        id: 9001,
        nome: 'Aluno de Demonstração',
        email: 'aluno@uninassau.edu.br',
        matricula: 'DEMO2026A',
        perfil: PerfilUsuario.aluno,
      ),
      token: 'demo-aluno-token',
    ),
    _DemoAccount(
      email: 'professor@uninassau.edu.br',
      password: 'professor123',
      user: UsuarioDto(
        id: 9002,
        nome: 'Professor de Demonstração',
        email: 'professor@uninassau.edu.br',
        matricula: 'DEMO2026P',
        perfil: PerfilUsuario.professor,
      ),
      token: 'demo-professor-token',
    ),
    _DemoAccount(
      email: 'recepcao@uninassau.edu.br',
      password: 'recepcao123',
      user: UsuarioDto(
        id: 9003,
        nome: 'Recepção de Demonstração',
        email: 'recepcao@uninassau.edu.br',
        perfil: PerfilUsuario.recepcao,
      ),
      token: 'demo-recepcao-token',
    ),
    _DemoAccount(
      email: 'coordenadora@uninassau.edu.br',
      password: 'admin123',
      user: UsuarioDto(
        id: 9004,
        nome: 'Coordenadora de Demonstração',
        email: 'coordenadora@uninassau.edu.br',
        perfil: PerfilUsuario.admin,
      ),
      token: 'demo-admin-token',
    ),
  ];

  UsuarioDto? _currentUser;

  @override
  Future<LoginResponseDto> login({
    required String email,
    required String senha,
  }) async {
    final account = demoAccounts.where(
      (item) => item.email == email.trim() && item.password == senha,
    );
    if (account.isEmpty) {
      throw DioException(
        requestOptions: RequestOptions(path: 'auth/login'),
        response: Response<dynamic>(
          requestOptions: RequestOptions(path: 'auth/login'),
          statusCode: 401,
        ),
        type: DioExceptionType.badResponse,
      );
    }
    final selected = account.first;
    _currentUser = selected.user;
    return LoginResponseDto(
      accessToken: selected.token,
      tokenType: 'bearer',
      usuario: selected.user,
    );
  }

  @override
  Future<UsuarioDto> getCurrentUser() async {
    final user = _currentUser;
    if (user == null) {
      throw const FormatException('Nenhum usuário demo autenticado.');
    }
    return user;
  }

  @override
  void clearAccessToken() {
    _currentUser = null;
    super.clearAccessToken();
  }
}

class _DemoAccount {
  const _DemoAccount({
    required this.email,
    required this.password,
    required this.user,
    required this.token,
  });

  final String email;
  final String password;
  final UsuarioDto user;
  final String token;
}
