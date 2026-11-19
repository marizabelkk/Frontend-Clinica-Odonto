import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ondonto_uninassau/core/network/api_client.dart';
import 'package:ondonto_uninassau/core/network/auth_token_store.dart';
import 'package:ondonto_uninassau/services/repositories/atendimento_repository.dart';
import 'package:ondonto_uninassau/services/repositories/autenticacao_repository.dart';
import 'package:ondonto_uninassau/services/repositories/paciente_repository.dart';
import 'package:ondonto_uninassau/services/repositories/semiologia_repository.dart';
import 'package:ondonto_uninassau/services/repositories/professor_repository.dart';
import 'package:ondonto_uninassau/main.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('shows the institutional login form', (tester) async {
    await tester.pumpWidget(_app('ALUNO'));
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.debugShowCheckedModeBanner, isFalse);
    expect(find.text('Bem-vindo(a)'), findsOneWidget);
    expect(find.text('E-mail institucional'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Contas de teste'), findsOneWidget);
    expect(find.textContaining('debug'), findsNothing);
  });

  testWidgets('the dark mode toggle switches the whole app theme', (
    tester,
  ) async {
    await tester.pumpWidget(_app('ALUNO'));
    MaterialApp app() => tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app().themeMode, ThemeMode.light);

    await tester.tap(find.byKey(const Key('theme-toggle')));
    await tester.pumpAndSettle();
    expect(app().themeMode, ThemeMode.dark);

    await tester.tap(find.byKey(const Key('theme-toggle')));
    await tester.pumpAndSettle();
    expect(app().themeMode, ThemeMode.light);
  });

  testWidgets('password recovery asks for the code and then the new password', (
    tester,
  ) async {
    await tester.pumpWidget(_app('ALUNO'));
    await tester.ensureVisible(find.text('Esqueci minha senha'));
    await tester.tap(find.text('Esqueci minha senha'));
    await tester.pumpAndSettle();
    expect(find.text('Recuperar senha'), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).first,
      'aluno@uninassau.edu.br',
    );
    await tester.tap(find.text('Enviar código'));
    await tester.pumpAndSettle();

    expect(find.text('Nova senha'), findsNWidgets(2));
    expect(find.text('Código de 6 dígitos'), findsOneWidget);
    expect(find.text('Redefinir senha'), findsOneWidget);
  });

  testWidgets('routes a professor to the professor area', (tester) async {
    await _loginAs(tester, 'PROFESSOR');
    expect(find.textContaining('Acompanhe as atividades'), findsOneWidget);
  });

  testWidgets('professor sidebar can collapse and expand repeatedly', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1910, 935);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _loginAs(tester, 'PROFESSOR');

    Future<void> toggle(String tooltip) async {
      await tester.tap(find.byTooltip(tooltip));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    expect(find.text('Pendências de aprovação'), findsOneWidget);
    expect(find.byTooltip('Recolher menu'), findsOneWidget);
    expect(find.text('Configurações'), findsOneWidget);

    await toggle('Recolher menu');
    expect(find.text('Pendências de aprovação'), findsOneWidget);
    expect(find.byTooltip('Expandir menu'), findsOneWidget);
    expect(find.text('Configurações'), findsNothing);

    await toggle('Expandir menu');
    expect(find.text('Pendências de aprovação'), findsOneWidget);
    expect(find.byTooltip('Recolher menu'), findsOneWidget);
    expect(find.text('Configurações'), findsOneWidget);

    for (var i = 0; i < 3; i++) {
      await toggle('Recolher menu');
      expect(find.text('Pendências de aprovação'), findsOneWidget);
      await toggle('Expandir menu');
      expect(find.text('Pendências de aprovação'), findsOneWidget);
    }

    await tester.tap(find.text('Pacientes'));
    await tester.pumpAndSettle();
    expect(find.text('Resultados da busca'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Pendências de aprovação'), findsOneWidget);

    await toggle('Recolher menu');
    await tester.tap(find.byTooltip('Pacientes'));
    await tester.pumpAndSettle();
    expect(find.text('Resultados da busca'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Pendências de aprovação'), findsOneWidget);
  });

  testWidgets('routes an aluno to the student area', (tester) async {
    await _loginAs(tester, 'ALUNO');
    expect(find.text('Área do aluno'), findsOneWidget);
  });

  testWidgets('routes reception to patient management', (tester) async {
    await _loginAs(tester, 'RECEPCAO');
    expect(find.text('Recepção · Pacientes'), findsOneWidget);
    expect(find.text('Cadastrar paciente'), findsOneWidget);
    expect(find.text('Buscar pacientes'), findsOneWidget);
  });

  testWidgets('reception search does not expose clinical records', (
    tester,
  ) async {
    await _loginAs(tester, 'RECEPCAO');
    await tester.tap(find.text('Buscar pacientes'));
    await tester.pumpAndSettle();

    expect(find.text('Resultados da busca'), findsOneWidget);
    expect(
      find.text(
        'A recepção pode buscar e cadastrar pacientes. O prontuário clínico não é exibido nesta área.',
      ),
      findsOneWidget,
    );
    expect(find.text('Nenhum paciente encontrado'), findsOneWidget);
  });

  testWidgets('routes admin to the coordinator user panel', (tester) async {
    await _loginAs(tester, 'ADMIN');
    expect(find.text('Painel da coordenação'), findsOneWidget);
    expect(find.text('Adicionar usuário'), findsOneWidget);
    expect(
      find.text('Gerencie os acessos de alunos e professores.'),
      findsOneWidget,
    );
  });

  testWidgets('the student can open patient search and registration', (
    tester,
  ) async {
    await _loginAs(tester, 'ALUNO');
    await tester.tap(find.text('Buscar pacientes'));
    await tester.pumpAndSettle();
    expect(find.text('Resultados da busca'), findsOneWidget);
    expect(find.text('Nenhum paciente encontrado'), findsOneWidget);

    await tester.tap(find.text('Cadastrar novo paciente'));
    await tester.pumpAndSettle();
    expect(find.text('Dados pessoais'), findsOneWidget);
    expect(find.text('Nome completo *'), findsOneWidget);
    expect(find.text('Data de nascimento *'), findsOneWidget);
  });
}

Future<void> _loginAs(WidgetTester tester, String perfil) async {
  await tester.pumpWidget(_app(perfil));
  await tester.enterText(
    find.byType(TextFormField).at(0),
    'usuario@uninassau.edu.br',
  );
  await tester.enterText(find.byType(TextFormField).at(1), 'senha');
  final submitButton = find.byType(ElevatedButton);
  await tester.ensureVisible(submitButton);
  await tester.tap(submitButton);
  await tester.pumpAndSettle();
}

Widget _app(String perfil) {
  final tokenStore = AuthTokenStore();
  final dio = Dio(BaseOptions(baseUrl: 'https://test.invalid/api/v1'))
    ..httpClientAdapter = _LoginAdapter(perfil);
  final repository = AutenticacaoRepository(
    apiClient: ApiClient(
      dio: dio,
      tokenProvider: () async => tokenStore.accessToken,
    ),
    tokenStore: tokenStore,
  );
  return MyApp(
    authRepository: repository,
    patientRepository: PacienteRepository(apiClient: repository.apiClient),
    atendimentoRepository: AtendimentoRepository(
      apiClient: repository.apiClient,
    ),
    semiologiaRepository: SemiologiaRepository(apiClient: repository.apiClient),
    professorRepository: ProfessorRepository(apiClient: repository.apiClient),
  );
}

class _LoginAdapter implements HttpClientAdapter {
  _LoginAdapter(this.perfil);

  final String perfil;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final json = switch ((options.method, options.path)) {
      ('POST', 'auth/login') =>
        '{"access_token":"jwt-token","token_type":"bearer","usuario":{"id":4,"nome":"Joana Silva","email":"usuario@uninassau.edu.br","matricula":"OD2026A","perfil":"$perfil"}}',
      ('GET', 'pacientes') => '[]',
      ('GET', 'fichas') => '[]',
      _ =>
        '{"id":4,"nome":"Joana Silva","email":"usuario@uninassau.edu.br","matricula":"OD2026A","perfil":"$perfil"}',
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
