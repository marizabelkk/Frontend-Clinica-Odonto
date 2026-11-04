import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondonto_uninassau/core/network/api_client.dart';
import 'package:ondonto_uninassau/data/models/professor_ficha_dto.dart';
import 'package:ondonto_uninassau/data/repositories/professor_repository.dart';

void main() {
  test(
    'lists pending, loads detail and records the documented decision body',
    () async {
      final adapter = _ProfessorAdapter();
      final api = ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'https://test.invalid/api/v1'))
          ..httpClientAdapter = adapter,
      );
      final repository = ProfessorRepository(apiClient: api);

      final pending = await repository.listPending();
      final detail = await repository.getFicha(201);
      await repository.registerDecision(
        fichaId: 201,
        decisao: DecisaoProfessor.correcaoSolicitada,
        observacao: 'Detalhar a história.',
      );
      await repository.registerDecision(
        fichaId: 202,
        decisao: DecisaoProfessor.aprovada,
      );

      expect(pending.single.id, 201);
      expect(pending.single.data['paciente'], isA<Map>());
      expect(detail.data['aluno_responsavel'], isA<Map>());
      expect(adapter.requests[0].queryParameters, {
        'status': 'AGUARDANDO_APROVACAO',
      });
      expect(adapter.requests[2].data, {
        'decisao': 'CORRECAO_SOLICITADA',
        'observacao': 'Detalhar a história.',
      });
      expect(adapter.requests[3].data, {
        'decisao': 'APROVADA',
        'observacao': null,
      });
    },
  );

  test('requires a note when correction is requested', () async {
    final adapter = _ProfessorAdapter();
    final repository = ProfessorRepository(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'https://test.invalid/api/v1'))
          ..httpClientAdapter = adapter,
      ),
    );

    expect(
      () => repository.registerDecision(
        fichaId: 201,
        decisao: DecisaoProfessor.correcaoSolicitada,
      ),
      throwsArgumentError,
    );
    expect(adapter.requests, isEmpty);
  });
}

class _ProfessorAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final json = switch (options.path) {
      'fichas' => '[{"id":201,"status":"AGUARDANDO_APROVACAO","paciente":{"nome_completo":"Maria"}}]',
      'fichas/201' => '{"id":201,"status":"AGUARDANDO_APROVACAO","paciente":{"nome_completo":"Maria"},"aluno_responsavel":{"nome":"Ana"},"queixa_principal":"Dor"}',
      _ => '{}',
    };
    return ResponseBody.fromString(
      json,
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
