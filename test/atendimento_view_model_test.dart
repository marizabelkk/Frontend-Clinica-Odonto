import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondonto_uninassau/core/constants/api_constants.dart';
import 'package:ondonto_uninassau/core/network/api_client.dart';
import 'package:ondonto_uninassau/services/repositories/atendimento_repository.dart';
import 'package:ondonto_uninassau/services/repositories/semiologia_repository.dart';
import 'package:ondonto_uninassau/view_models/atendimento_view_model.dart';

void main() {
  test('uses the active Semiologia ID returned by the API', () async {
    final adapter = _IntegrationAdapter();
    final apiClient = ApiClient(
      dio: Dio(BaseOptions(baseUrl: ApiConstants.baseUrl))
        ..httpClientAdapter = adapter,
    );
    final viewModel = AtendimentoViewModel(
      atendimentoRepository: AtendimentoRepository(apiClient: apiClient),
      semiologiaRepository: SemiologiaRepository(apiClient: apiClient),
    );

    await viewModel.loadEspecialidades();
    expect(viewModel.semiologiaEspecialidadeId, 37);

    final ficha = await viewModel.startSemiologia(prontuarioId: 8);

    expect(ficha?.id, 21);
    final createRequest = adapter.requests.firstWhere(
      (request) => request.path == 'atendimentos',
    );
    expect(createRequest.data, {
      'prontuario_id': 8,
      'especialidade_id': 37,
    });
    expect(
      adapter.requests.map((request) => '${request.method} ${request.path}'),
      [
        'GET especialidades',
        'POST atendimentos',
        'POST atendimentos/55/fichas/semiologia',
      ],
    );
  });

  test('does not start an attendance without an active Semiologia row', () async {
    final adapter = _IntegrationAdapter(
      specialties: [
        {'id': 37, 'nome': 'Semiologia', 'ativo': false},
      ],
    );
    final apiClient = ApiClient(
      dio: Dio(BaseOptions(baseUrl: ApiConstants.baseUrl))
        ..httpClientAdapter = adapter,
    );
    final viewModel = AtendimentoViewModel(
      atendimentoRepository: AtendimentoRepository(apiClient: apiClient),
      semiologiaRepository: SemiologiaRepository(apiClient: apiClient),
    );

    await viewModel.loadEspecialidades();
    final ficha = await viewModel.startSemiologia(prontuarioId: 8);

    expect(viewModel.semiologiaEspecialidadeId, isNull);
    expect(ficha, isNull);
    expect(adapter.requests.map((request) => request.path), ['especialidades']);
  });
}

class _IntegrationAdapter implements HttpClientAdapter {
  _IntegrationAdapter({
    this.specialties = const [
      {'id': 37, 'nome': 'Semiologia', 'ativo': true},
    ],
  });

  final List<Map<String, dynamic>> specialties;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final body = switch ('${options.method} ${options.path}') {
      'GET especialidades' => specialties,
      'POST atendimentos' => {'id': 55},
      'POST atendimentos/55/fichas/semiologia' => {
        'id': 21,
        'atendimento_id': 55,
        'status': 'RASCUNHO',
        'versao': 1,
      },
      _ => throw StateError('Unexpected request: ${options.method} ${options.path}'),
    };
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
