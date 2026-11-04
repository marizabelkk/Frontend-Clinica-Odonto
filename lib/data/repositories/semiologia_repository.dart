import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../models/ficha_semiologia_dto.dart';

class SemiologiaRepository {
  const SemiologiaRepository({required this.apiClient});

  final ApiClient apiClient;

  Future<FichaSemiologiaDto> createFicha(int atendimentoId) async {
    final response = await apiClient.dio.post<Map<String, dynamic>>(
      'atendimentos/$atendimentoId/fichas/semiologia',
    );
    final data = response.data;
    if (data == null) {
      throw const FormatException(
        'A API retornou uma resposta vazia ao criar a ficha.',
      );
    }
    return FichaSemiologiaDto.fromJson(data);
  }

  Future<void> saveDraft({
    required int fichaId,
    required SemiologiaDraftDto draft,
  }) async {
    await apiClient.dio.patch<void>('fichas/$fichaId', data: draft.toJson());
  }

  Future<StatusFicha> submit(int fichaId) async {
    final response = await apiClient.dio.patch<Map<String, dynamic>>(
      'fichas/$fichaId/submeter',
    );
    final status = response.data?['status'];
    if (status is! String) {
      throw const FormatException(
        'A API não retornou o status após a submissão da ficha.',
      );
    }
    return StatusFicha.fromApi(status);
  }

  static String userMessageFor(Object error) {
    if (error is FormatException) {
      return 'A resposta da API não corresponde ao contrato esperado.';
    }
    if (error is DioException) {
      final code = error.response?.statusCode;
      if (code == 401) return 'Sua sessão expirou. Entre novamente.';
      if (code == 403) return 'Você não tem permissão para alterar esta ficha.';
      if (code == 404) return 'A ficha não foi encontrada.';
      if (code == 422) {
        return 'A API rejeitou os dados enviados. Revise a ficha.';
      }
      if (code == 409) {
        return 'A ficha não pode ser alterada no estado atual.';
      }
      if (code != null && code >= 500) {
        return 'O serviço está indisponível no momento. Tente novamente mais tarde.';
      }
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return 'Não foi possível conectar à API. Verifique o endereço e tente novamente.';
      }
    }
    return 'Não foi possível salvar ou enviar a ficha.';
  }
}
