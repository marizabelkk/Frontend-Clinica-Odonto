import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondonto_uninassau/core/constants/api_constants.dart';
import 'package:ondonto_uninassau/core/network/api_client.dart';
import 'package:ondonto_uninassau/core/network/auth_token_store.dart';
import 'package:ondonto_uninassau/data/models/paciente_dto.dart';
import 'package:ondonto_uninassau/data/repositories/patient_repository.dart';

void main() {
  test('uses the documented patient endpoints and query names', () async {
    final adapter = _PatientAdapter();
    final tokenStore = AuthTokenStore()..save('patient-token');
    final apiClient = ApiClient(
      dio: Dio(BaseOptions(baseUrl: ApiConstants.baseUrl))
        ..httpClientAdapter = adapter,
      tokenProvider: () async => tokenStore.accessToken,
    );
    final repository = PatientRepository(apiClient: apiClient);

    final byName = await repository.searchPatients(nome: 'Maria');
    final byCpf = await repository.searchPatients(cpf: '123.456.789-01');
    final created = await repository.createPatient(
      const PacienteDto(nomeCompleto: 'Maria Oliveira', cpf: '12345678901'),
    );
    final patient = await repository.getPatient(10);
    final prontuario = await repository.getProntuario(10);

    expect(byName.single.nomeCompleto, 'Maria Oliveira');
    expect(byCpf.single.cpf, '12345678901');
    expect(adapter.requests[0].queryParameters, {'busca': 'Maria'});
    expect(adapter.requests[1].queryParameters, {'cpf': '12345678901'});
    expect(adapter.requests[2].path, 'pacientes');
    expect(adapter.requests[2].data, {
      'nome_completo': 'Maria Oliveira',
      'cpf': '12345678901',
    });
    expect(created.pacienteId, 10);
    expect(patient.nomeCompleto, 'Maria Oliveira');
    expect(patient.pacienteId, 10);
    expect(patient.prontuarioId, 8);
    expect(prontuario.id, 8);
    expect(prontuario.paciente.pacienteId, 10);
    expect(prontuario.atendimentos, isEmpty);
    expect(
      adapter.requests.last.uri.path,
      '/api/v1/pacientes/10/prontuario',
    );
    expect(adapter.requests.map((request) => request.path), [
      'pacientes',
      'pacientes',
      'pacientes',
      'pacientes/10',
      'pacientes/10/prontuario',
    ]);
  });
}

class _PatientAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final json = switch (options.method) {
      'POST' =>
        '{"paciente_id":10,"prontuario_id":8,"nome_completo":"Maria Oliveira"}',
      _ when options.path == 'pacientes/10/prontuario' =>
        '{"id":8,"paciente_id":10,"criado_em":"2026-11-03T10:00:00","paciente":{"id":10,"prontuario_id":8,"nome_completo":"Maria Oliveira","cpf":"12345678901"},"condicoes_medicas":[],"alergias":[],"medicamentos":[],"atendimentos":[]}',
      _ when options.path == 'pacientes/10' =>
        '{"id":10,"prontuario_id":8,"nome_completo":"Maria Oliveira","cpf":"12345678901"}',
      _ =>
        '[{"id":10,"prontuario_id":8,"nome_completo":"Maria Oliveira","cpf":"12345678901"}]',
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
