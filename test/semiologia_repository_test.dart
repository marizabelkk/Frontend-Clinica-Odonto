import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondonto_uninassau/core/constants/api_constants.dart';
import 'package:ondonto_uninassau/core/network/api_client.dart';
import 'package:ondonto_uninassau/models/atendimento_model.dart';
import 'package:ondonto_uninassau/models/ficha_semiologia_model.dart';
import 'package:ondonto_uninassau/services/repositories/atendimento_repository.dart';
import 'package:ondonto_uninassau/services/repositories/semiologia_repository.dart';

void main() {
  test(
    'posts attendance, vitals, draft and submission to contract routes',
    () async {
      final adapter = _WorkflowAdapter();
      final dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl))
        ..httpClientAdapter = adapter;
      final apiClient = ApiClient(dio: dio);
      final attendanceRepository = AtendimentoRepository(apiClient: apiClient);
      final semiologiaRepository = SemiologiaRepository(apiClient: apiClient);

      final attendance = await attendanceRepository.create(
        prontuarioId: 8,
        especialidadeId: 1,
      );
      await attendanceRepository.saveVitalSigns(
        atendimentoId: attendance.id,
        sinaisVitais: const SinaisVitaisModel(
          pressaoSistolica: 120,
          pressaoDiastolica: 80,
          pulso: 72,
          frequenciaRespiratoria: 16,
          temperatura: 36.5,
          peso: 68.5,
          altura: 1.65,
          glicemia: 95,
        ),
      );
      final ficha = await semiologiaRepository.createFicha(attendance.id);
      await semiologiaRepository.saveDraft(
        fichaId: ficha.id,
        draft: const SemiologiaDraftModel(
          queixaPrincipal: 'Dor',
          historiaDoencaAtual: 'Relata dor há cinco dias.',
          antecedentesFamiliares: 'Diabetes na família.',
          medicamentosAlergias: 'Dipirona; alergia a látex.',
          habitosHistoriaOdontologica: 'Escova duas vezes ao dia.',
          observacoesGerais: 'Sem observações adicionais.',
          diagnostico: 'A definir.',
          planoTratamento: 'Avaliação complementar.',
          necessitaEncaminhamento: false,
        ),
      );
      final status = await semiologiaRepository.submit(ficha.id);

      expect(attendance.id, 155);
      expect(ficha.status, StatusFicha.rascunho);
      expect(status, StatusFicha.aguardandoAprovacao);
      expect(
        adapter.requests.map((request) => '${request.method} ${request.path}'),
        [
          'POST atendimentos',
          'POST atendimentos/155/sinais-vitais',
          'POST atendimentos/155/fichas/semiologia',
          'PATCH fichas/201',
          'PATCH fichas/201/submeter',
        ],
      );
      expect(adapter.requests[0].data, {
        'prontuario_id': 8,
        'especialidade_id': 1,
      });
      expect(adapter.requests[1].data, {
        'pressao_sistolica': 120,
        'pressao_diastolica': 80,
        'pulso': 72,
        'frequencia_respiratoria': 16,
        'temperatura': 36.5,
        'peso': 68.5,
        'altura': 1.65,
        'glicemia': 95,
      });
      expect(adapter.requests[3].data, {
        'queixa_principal': 'Dor',
        'historia_doenca_atual': 'Relata dor há cinco dias.',
        'antecedentes_familiares': 'Diabetes na família.',
        'medicamentos_alergias': 'Dipirona; alergia a látex.',
        'habitos_historia_odontologica': 'Escova duas vezes ao dia.',
        'observacoes_gerais': 'Sem observações adicionais.',
        'diagnostico': 'A definir.',
        'plano_tratamento': 'Avaliação complementar.',
        'necessita_encaminhamento': false,
      });
    },
  );
}

class _WorkflowAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final json = switch (options.path) {
      'atendimentos' => '{"id":155}',
      'atendimentos/155/fichas/semiologia' =>
        '{"id":201,"atendimento_id":155,"status":"RASCUNHO","versao":1}',
      'fichas/201/submeter' => '{"id":201,"status":"AGUARDANDO_APROVACAO"}',
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
