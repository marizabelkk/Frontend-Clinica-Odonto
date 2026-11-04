import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// In-memory API responses used only when the debug demo mode is enabled.
/// Data created here is temporary and disappears when the app restarts.
class DemoApiAdapter implements HttpClientAdapter {
  final List<Map<String, dynamic>> _patients = [
    {
      'paciente_id': 1,
      'prontuario_id': 101,
      'nome_completo': 'Maria Oliveira (demonstração)',
      'cpf': '11122233344',
      'rg': 'DEMO-1001',
      'data_nascimento': '1995-04-12',
      'sexo': 'Feminino',
      'celular': '81999990001',
    },
    {
      'paciente_id': 2,
      'prontuario_id': 102,
      'nome_completo': 'João Santos (demonstração)',
      'cpf': '22233344455',
      'rg': 'DEMO-1002',
      'data_nascimento': '1988-09-23',
      'sexo': 'Masculino',
      'celular': '81999990002',
    },
  ];

  final List<Map<String, dynamic>> _pendingReviews = [
    {
      'id': 701,
      'atendimento_id': 501,
      'status': 'AGUARDANDO_APROVACAO',
      'versao': 1,
      'paciente': {
        'paciente_id': 1,
        'nome_completo': 'Maria Oliveira (demonstração)',
        'cpf': '11122233344',
      },
      'prontuario': {'prontuario_id': 101},
      'aluno_responsavel': {
        'nome': 'Aluno de Demonstração',
        'matricula': 'DEMO2026A',
      },
      'especialidade': 'Semiologia',
      'queixa_principal': 'Sensibilidade dentária (dado fictício)',
      'historia_doenca_atual': 'Paciente relata sensibilidade ao frio há alguns dias. Dado fictício para demonstração.',
      'antecedentes_familiares': 'Sem relato (dado fictício).',
      'observacoes_gerais': 'Ficha de demonstração; não é registro clínico.',
      'diagnostico': 'Em avaliação (dado fictício).',
      'plano_tratamento': 'Avaliação inicial (dado fictício).',
      'encaminhamento': 'Não se aplica (dado fictício).',
    },
  ];

  int _nextPatientId = 3;
  int _nextAttendanceId = 502;
  int _nextFichaId = 702;
  final Map<int, Map<String, dynamic>> _attendances = {};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final method = options.method.toUpperCase();
    final path = options.path.replaceFirst(RegExp(r'^/'), '');
    final response = _route(method, path, options);
    return ResponseBody.fromString(
      jsonEncode(response),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  dynamic _route(String method, String path, RequestOptions options) {
    if (method == 'GET' && path == 'pacientes') {
      final search = options.queryParameters['busca']?.toString().toLowerCase();
      final cpf = options.queryParameters['cpf']?.toString();
      return _patients.where((patient) {
        if (cpf != null && cpf.isNotEmpty) return patient['cpf'] == cpf;
        if (search != null && search.isNotEmpty) {
          return patient['nome_completo'].toString().toLowerCase().contains(
            search,
          );
        }
        return true;
      }).toList();
    }

    if (method == 'POST' && path == 'pacientes') {
      final payload = Map<String, dynamic>.from(options.data as Map);
      final id = _nextPatientId++;
      final patient = {
        ...payload,
        'paciente_id': id,
        'prontuario_id': 100 + id,
      };
      _patients.add(patient);
      return {
        'paciente_id': id,
        'prontuario_id': 100 + id,
        'nome_completo': payload['nome_completo'],
      };
    }

    final patientRoute = RegExp(r'^pacientes/(\d+)$').firstMatch(path);
    if (method == 'GET' && patientRoute != null) {
      return _findPatient(int.parse(patientRoute.group(1)!));
    }

    final recordRoute = RegExp(r'^pacientes/(\d+)/prontuario$')
        .firstMatch(path);
    if (method == 'GET' && recordRoute != null) {
      final patient = _findPatient(int.parse(recordRoute.group(1)!));
      return {
        'prontuario_id': patient['prontuario_id'],
        'atendimentos': [
          {
            'especialidade': 'Semiologia',
            'resumo': 'Resumo fictício para visualização do protótipo.',
            'status': 'RASCUNHO',
          },
        ],
        'observacao_demo':
            'Dados locais de demonstração; não são dados clínicos reais.',
      };
    }

    if (method == 'POST' && path == 'atendimentos') {
      final id = _nextAttendanceId++;
      _attendances[id] = Map<String, dynamic>.from(options.data as Map);
      return {'id': id};
    }
    if (method == 'POST' &&
        RegExp(r'^atendimentos/\d+/sinais-vitais$').hasMatch(path)) {
      return <String, dynamic>{};
    }

    final createFicha = RegExp(r'^atendimentos/(\d+)/fichas/semiologia$')
        .firstMatch(path);
    if (method == 'POST' && createFicha != null) {
      final id = _nextFichaId++;
      final ficha = {
        'id': id,
        'atendimento_id': int.parse(createFicha.group(1)!),
        'status': 'RASCUNHO',
        'versao': 1,
      };
      final attendance = _attendances[ficha['atendimento_id']];
      if (attendance != null) {
        final patient = _patients.firstWhere(
          (item) => item['prontuario_id'] == attendance['prontuario_id'],
          orElse: () => _patients.first,
        );
        ficha['paciente'] = {
          'paciente_id': patient['paciente_id'],
          'nome_completo': patient['nome_completo'],
          'cpf': patient['cpf'],
        };
        ficha['prontuario'] = {'prontuario_id': attendance['prontuario_id']};
        ficha['aluno_responsavel'] = {
          'nome': 'Aluno de Demonstração',
          'matricula': 'DEMO2026A',
        };
      }
      _pendingReviews.add(ficha);
      return ficha;
    }

    final fichaRoute = RegExp(r'^fichas/(\d+)$').firstMatch(path);
    if (method == 'GET' && path == 'fichas') {
      final status = options.queryParameters['status']?.toString();
      return _pendingReviews
          .where((ficha) => status == null || ficha['status'] == status)
          .map((ficha) => Map<String, dynamic>.from(ficha))
          .toList();
    }
    if (fichaRoute != null) {
      final id = int.parse(fichaRoute.group(1)!);
      final index = _pendingReviews.indexWhere((ficha) => ficha['id'] == id);
      if (index < 0) return {'id': id, 'status': 'RASCUNHO', 'versao': 1};
      if (method == 'GET') return _pendingReviews[index];
      if (method == 'PATCH') {
        _pendingReviews[index].addAll(
          Map<String, dynamic>.from(options.data as Map),
        );
        return <String, dynamic>{};
      }
    }

    final submitFicha = RegExp(r'^fichas/(\d+)/submeter$').firstMatch(path);
    if (method == 'PATCH' && submitFicha != null) {
      final id = int.parse(submitFicha.group(1)!);
      final index = _pendingReviews.indexWhere((ficha) => ficha['id'] == id);
      if (index >= 0) _pendingReviews[index]['status'] = 'AGUARDANDO_APROVACAO';
      return {'id': id, 'status': 'AGUARDANDO_APROVACAO'};
    }

    final approveFicha = RegExp(r'^fichas/(\d+)/aprovacoes$').firstMatch(path);
    if (method == 'POST' && approveFicha != null) {
      final id = int.parse(approveFicha.group(1)!);
      final payload = Map<String, dynamic>.from(options.data as Map);
      final index = _pendingReviews.indexWhere((ficha) => ficha['id'] == id);
      if (index >= 0) {
        _pendingReviews[index]
          ..['status'] = payload['decisao']
          ..['observacao_professor'] = payload['observacao'];
        if (payload['decisao'] == 'APROVADA' ||
            payload['decisao'] == 'CORRECAO_SOLICITADA') {
          _pendingReviews.removeAt(index);
        }
      }
      return <String, dynamic>{};
    }

    if (method == 'GET' && path == 'atendimentos/meus') {
      return <Map<String, dynamic>>[];
    }

    return <String, dynamic>{};
  }

  Map<String, dynamic> _findPatient(int id) => _patients.firstWhere(
    (patient) => patient['paciente_id'] == id,
    orElse: () => <String, dynamic>{
      'paciente_id': id,
      'prontuario_id': 100 + id,
      'nome_completo': 'Paciente de demonstração $id',
      'cpf': '00000000000',
    },
  );

  @override
  void close({bool force = false}) {}
}
