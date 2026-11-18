import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondonto_uninassau/core/constants/api_constants.dart';
import 'package:ondonto_uninassau/core/network/api_client.dart';
import 'package:ondonto_uninassau/core/network/auth_token_store.dart';
import 'package:ondonto_uninassau/data/models/paciente_dto.dart';
import 'package:ondonto_uninassau/data/models/usuario_dto.dart';
import 'package:ondonto_uninassau/data/repositories/auth_repository.dart';
import 'package:ondonto_uninassau/data/viewmodels/auth_view_model.dart';

void main() {
  test('API profile parser recognizes reception', () {
    final user = UsuarioDto.fromJson({
      'id': 5,
      'nome': 'Usuária da recepção',
      'email': 'recepcao@uninassau.edu.br',
      'perfil': 'RECEPCAO',
    });

    expect(user.perfil, PerfilUsuario.recepcao);
  });

  test('login loads the current user and stores the Bearer token', () async {
    final adapter = _AuthAdapter();
    final tokenStore = AuthTokenStore();
    final apiClient = ApiClient(
      dio: Dio(BaseOptions(baseUrl: ApiConstants.baseUrl))
        ..httpClientAdapter = adapter,
      tokenProvider: () async => tokenStore.accessToken,
    );
    final viewModel = AuthViewModel(
      repository: AuthRepository(apiClient: apiClient, tokenStore: tokenStore),
    );

    final success = await viewModel.login(
      email: 'professor@uninassau.edu.br',
      senha: 'senha',
    );

    expect(success, isTrue, reason: viewModel.errorMessage);
    expect(viewModel.isAuthenticated, isTrue);
    expect(viewModel.perfil, PerfilUsuario.professor);
    expect(viewModel.accessToken, 'jwt-token');
    expect(tokenStore.accessToken, 'jwt-token');
    expect(adapter.requests, hasLength(2));
    expect(adapter.requests.first.path, 'auth/login');
    expect(adapter.requests.first.data, {
      'email': 'professor@uninassau.edu.br',
      'senha': 'senha',
    });
    expect(adapter.requests.last.path, 'usuarios/me');
    expect(adapter.requests.last.headers['Authorization'], 'Bearer jwt-token');
  });

  test('patient DTO uses the contract snake_case fields', () {
    const patient = PacienteDto(
      nomeCompleto: 'Maria Oliveira',
      cpf: '12345678901',
      rg: 'MG123456',
      dataNascimento: '1995-04-12',
      sexo: 'Feminino',
      celular: '31999998888',
    );

    expect(patient.toCreateJson(), {
      'nome_completo': 'Maria Oliveira',
      'cpf': '12345678901',
      'rg': 'MG123456',
      'data_nascimento': '1995-04-12',
      'sexo': 'Feminino',
      'celular': '31999998888',
    });
    expect(
      PacienteDto.fromJson({
        'paciente_id': 10,
        'prontuario_id': 8,
        'nome_completo': 'Maria Oliveira',
      }).pacienteId,
      10,
    );
  });
}

class _AuthAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final response = options.path.endsWith('auth/login')
        ? '{"access_token":"jwt-token","token_type":"bearer","usuario":{"id":12,"nome":"Ana Oliveira","email":"professor@uninassau.edu.br","matricula":null,"perfil":"PROFESSOR"}}'
        : '{"id":12,"nome":"Ana Oliveira","email":"professor@uninassau.edu.br","matricula":null,"perfil":"PROFESSOR"}';
    return ResponseBody.fromString(
      response,
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
