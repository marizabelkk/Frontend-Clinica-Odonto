import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ondonto_uninassau/core/network/api_client.dart';
import 'package:ondonto_uninassau/core/network/auth_token_store.dart';
import 'package:ondonto_uninassau/models/professor_ficha_model.dart';
import 'package:ondonto_uninassau/services/repositories/autenticacao_repository.dart';
import 'package:ondonto_uninassau/services/repositories/professor_repository.dart';
import 'package:ondonto_uninassau/view_models/autenticacao_view_model.dart';
import 'package:ondonto_uninassau/view_models/tema_view_model.dart';
import 'package:ondonto_uninassau/view_models/professor_view_model.dart';
import 'package:ondonto_uninassau/views/professor/revisar_fichas_view.dart';

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

  testWidgets('review screen submits a professor correction decision', (
    tester,
  ) async {
    final adapter = _ProfessorAdapter();
    final api = ApiClient(
      dio: Dio(BaseOptions(baseUrl: 'https://test.invalid/api/v1'))
        ..httpClientAdapter = adapter,
    );
    final model = ProfessorViewModel(
      repository: ProfessorRepository(apiClient: api),
    );
    await tester.runAsync(() => model.loadFicha(201));
    final auth = AutenticacaoViewModel(
      repository: AutenticacaoRepository(
        apiClient: api,
        tokenStore: AuthTokenStore(),
      ),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: model,
        child: ChangeNotifierProvider.value(
          value: auth,
          child: ChangeNotifierProvider(
            create: (_) => TemaViewModel(),
            child: MaterialApp(
              home: Builder(
                builder: (context) => Scaffold(
                  body: Center(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => const RevisarFichasView(),
                        ),
                      ),
                      child: const Text('Abrir revisão'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir revisão'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Detalhar o diagnóstico.');
    await tester.ensureVisible(find.text('Devolver para correção'));
    await tester.tap(find.text('Devolver para correção'));
    await tester.pumpAndSettle();

    final decision = adapter.requests.singleWhere(
      (request) => request.path == 'fichas/201/aprovacoes',
    );
    expect(decision.data, {
      'decisao': 'CORRECAO_SOLICITADA',
      'observacao': 'Detalhar o diagnóstico.',
    });
    expect(find.text('Abrir revisão'), findsOneWidget);
  });

  testWidgets('presents semiology as readable clinical sections', (
    tester,
  ) async {
    final repository = ProfessorRepository(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'https://test.invalid/api/v1'))
          ..httpClientAdapter = _ProfessorAdapter(),
      ),
    );
    final model = ProfessorViewModel(repository: repository);
    await tester.runAsync(() => model.loadFicha(201));

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: model,
        child: ChangeNotifierProvider.value(
          value: AutenticacaoViewModel(
            repository: AutenticacaoRepository(
              apiClient: ApiClient(
                dio: Dio(BaseOptions(baseUrl: 'https://test.invalid/api/v1'))
                  ..httpClientAdapter = _ProfessorAdapter(),
              ),
              tokenStore: AuthTokenStore(),
            ),
          ),
          child: ChangeNotifierProvider(
            create: (_) => TemaViewModel(),
            child: const MaterialApp(home: RevisarFichasView()),
          ),
        ),
      ),
    );

    expect(find.text('Revisão de ficha'), findsOneWidget);
    expect(find.textContaining('Queixa e'), findsOneWidget);
    expect(find.text('Medicamentos e alergias'), findsOneWidget);
    expect(find.textContaining('odontol'), findsOneWidget);
    expect(find.text('Dipirona; alergia a látex.'), findsOneWidget);
    expect(find.text('Escova duas vezes ao dia.'), findsOneWidget);
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
      'fichas' =>
        '[{"id":201,"status":"AGUARDANDO_APROVACAO","paciente":{"nome_completo":"Maria"}}]',
      'fichas/201' =>
        '{"id":201,"atendimento_id":155,"tipo":"SEMIOLOGIA","status":"AGUARDANDO_APROVACAO","versao":1,"aluno_responsavel":{"nome":"Ana"},"semiologia":{"queixa_principal":"Dor","medicamentos_alergias":"Dipirona; alergia a látex.","habitos_historia_odontologica":"Escova duas vezes ao dia."}}',
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
