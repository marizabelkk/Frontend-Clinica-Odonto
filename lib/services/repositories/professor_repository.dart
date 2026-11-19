import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../../models/professor_ficha_model.dart';

class ProfessorRepository {
  const ProfessorRepository({required this.apiClient});

  final ApiClient apiClient;

  Future<List<ProfessorFichaModel>> listPending() async {
    final response = await apiClient.dio.get<Object?>(
      'fichas',
      queryParameters: {'status': 'AGUARDANDO_APROVACAO'},
    );
    final data = response.data;
    if (data is! List) {
      throw const FormatException(
        'A API não retornou a lista de fichas no formato esperado.',
      );
    }
    return data
        .map(
          (item) => ProfessorFichaModel.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList(growable: false);
  }

  Future<ProfessorFichaModel> getFicha(int id) async {
    final response = await apiClient.dio.get<Map<String, dynamic>>(
      'fichas/$id',
    );
    final data = response.data;
    if (data == null) {
      throw const FormatException('A API retornou uma ficha vazia.');
    }
    return ProfessorFichaModel.fromJson(data);
  }

  Future<void> registerDecision({
    required int fichaId,
    required DecisaoProfessor decisao,
    String? observacao,
  }) async {
    final normalizedObservation = observacao?.trim();
    if (decisao == DecisaoProfessor.correcaoSolicitada &&
        (normalizedObservation == null || normalizedObservation.isEmpty)) {
      throw ArgumentError('Informe uma observação para solicitar correção.');
    }
    await apiClient.dio.post<void>(
      'fichas/$fichaId/aprovacoes',
      data: {
        'decisao': decisao.apiValue,
        'observacao': decisao == DecisaoProfessor.aprovada
            ? null
            : normalizedObservation,
      },
    );
  }

  static String userMessageFor(Object error) {
    if (error is ArgumentError) {
      return error.message.toString();
    }
    if (error is FormatException) {
      return 'A resposta da API não corresponde ao formato esperado.';
    }
    if (error is DioException) {
      final code = error.response?.statusCode;
      if (code == 401) return 'Sua sessão expirou. Entre novamente.';
      if (code == 403) {
        return 'Seu perfil não tem permissão para revisar fichas.';
      }
      if (code == 404) return 'A ficha não foi encontrada.';
      if (code == 422) return 'A API rejeitou a decisão ou os dados da ficha.';
      if (code != null && code >= 500) {
        return 'O serviço está indisponível no momento. Tente novamente.';
      }
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return 'Não foi possível conectar à API. Verifique o endereço e tente novamente.';
      }
    }
    return 'Não foi possível carregar ou revisar a ficha.';
  }
}
