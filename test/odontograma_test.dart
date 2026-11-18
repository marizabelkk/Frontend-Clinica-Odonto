import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondonto_uninassau/core/constants/api_constants.dart';
import 'package:ondonto_uninassau/core/network/api_client.dart';
import 'package:ondonto_uninassau/data/models/odontograma_dto.dart';
import 'package:ondonto_uninassau/data/repositories/odontograma_repository.dart';
import 'package:ondonto_uninassau/data/viewmodels/odontograma_view_model.dart';
import 'package:ondonto_uninassau/views/odontograma/tooth_map.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads the supplied FDI odontogram asset', () async {
    final image = await rootBundle.load('assets/images/odontograma.jpg');
    expect(image.lengthInBytes, greaterThan(0));
  });

  group('ToothMap', () {
    test('cobre os 52 dentes da numeração FDI (permanentes e decíduos)', () {
      expect(ToothMap.shapes.length, 52);
      expect(
        ToothMap.shapes.keys,
        containsAll([11, 28, 31, 48, 51, 65, 71, 85]),
      );
    });

    test('resolve o dente tocado a partir da posição na imagem', () {
      expect(ToothMap.toothAt(342, 76), 11);
      expect(ToothMap.toothAt(155, 348), 18);
      expect(ToothMap.toothAt(368, 666), 71);
      expect(ToothMap.toothAt(5, 5), isNull);
    });

    test('descreve dente decíduo e permanente', () {
      expect(ToothMap.describe(16), 'Dente 16 · permanente');
      expect(ToothMap.describe(55), 'Dente 55 · decíduo');
    });
  });

  group('OdontogramaViewModel', () {
    late _Adapter adapter;
    late OdontogramaViewModel model;

    setUp(() {
      adapter = _Adapter();
      final dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl))
        ..httpClientAdapter = adapter;
      model = OdontogramaViewModel(
        repository: OdontogramaRepository(apiClient: ApiClient(dio: dio)),
      );
    });

    test('carrega registros e catálogo e agrupa por dente', () async {
      await model.load(prontuarioId: 8, atendimentoId: 3);

      expect(model.errorMessage, isNull);
      expect(model.condicoes.single.nome, 'Cárie');
      expect(model.registrosPorDente.keys, [16]);
      model.selectTooth(16);
      expect(model.selectedToothRegistros.single.face, FaceDente.oclusal);
      expect(model.condicaoNome(1), 'Cárie');
    });

    test('cria, edita e exclui registros nas rotas do contrato', () async {
      await model.load(prontuarioId: 8, atendimentoId: 3);
      const input = OdontogramaRegistroInput(
        numeroDente: 16,
        face: FaceDente.mesial,
        condicaoId: 1,
        observacao: 'Profunda',
      );

      expect(await model.save(input), isNull);
      final post = adapter.requests.firstWhere((r) => r.method == 'POST');
      expect(post.path, 'atendimentos/3/odontograma/registros');
      expect(post.data, {
        'numero_dente': 16,
        'face': 'MESIAL',
        'condicao_id': 1,
        'observacao': 'Profunda',
      });

      final existing = model.registros.first;
      expect(await model.save(input, registro: existing), isNull);
      final put = adapter.requests.firstWhere((r) => r.method == 'PUT');
      expect(put.path, 'atendimentos/3/odontograma/registros/${existing.id}');

      expect(await model.remove(existing), isNull);
      final delete = adapter.requests.firstWhere((r) => r.method == 'DELETE');
      expect(
        delete.path,
        'atendimentos/3/odontograma/registros/${existing.id}',
      );
    });

    test('sem atendimento ativo não permite alterar', () async {
      await model.load(prontuarioId: 8);
      expect(
        await model.save(
          const OdontogramaRegistroInput(
            numeroDente: 11,
            face: FaceDente.incisal,
            condicaoId: 1,
          ),
        ),
        isNotNull,
      );
      expect(adapter.requests.where((r) => r.method == 'POST'), isEmpty);
    });
  });
}

class _Adapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  static const _registro =
      '{"id":7,"odontograma_id":1,"atendimento_id":3,"numero_dente":16,'
      '"face":"OCLUSAL","condicao_id":1,"observacao":"Cavidade",'
      '"registrado_por":4,"registrado_em":"2026-11-14T10:00:00"}';

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (options.method == 'DELETE') {
      return ResponseBody.fromString('', 204);
    }
    final body = switch ((options.method, options.path)) {
      ('GET', 'prontuarios/8/odontograma') => jsonEncode({
        'id': 1,
        'prontuario_id': 8,
        'registros': [jsonDecode(_registro)],
      }),
      ('GET', 'condicoes-odontologicas') =>
        '[{"id":1,"codigo":"CARIE","nome":"Cárie","ativo":true}]',
      _ => _registro,
    };
    return ResponseBody.fromString(
      body,
      options.method == 'POST' ? 201 : 200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
