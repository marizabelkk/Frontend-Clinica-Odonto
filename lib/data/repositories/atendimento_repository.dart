import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../models/atendimento_dto.dart';
import '../models/especialidade_dto.dart';

class AtendimentoRepository {
  const AtendimentoRepository({required this.apiClient});

  final ApiClient apiClient;

  Future<List<EspecialidadeDto>> listEspecialidades() async {
    final response = await apiClient.dio.get<Object?>('especialidades');
    final data = response.data;
    if (data is! List) {
      throw const FormatException(
        'A API não retornou a lista de especialidades no formato esperado.',
      );
    }
    return data
        .map(
          (item) => EspecialidadeDto.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList(growable: false);
  }

  Future<AtendimentoDto> create({
    required int prontuarioId,
    required int especialidadeId,
  }) async {
    final response = await apiClient.dio.post<Map<String, dynamic>>(
      'atendimentos',
      data: {
        'prontuario_id': prontuarioId,
        'especialidade_id': especialidadeId,
      },
    );
    final data = response.data;
    if (data == null) {
      throw const FormatException(
        'A API retornou uma resposta vazia ao iniciar o atendimento.',
      );
    }
    return AtendimentoDto.fromJson(data);
  }

  Future<void> saveVitalSigns({
    required int atendimentoId,
    required SinaisVitaisDto sinaisVitais,
  }) async {
    if (sinaisVitais.toJson().isEmpty) return;
    await apiClient.dio.post<void>(
      'atendimentos/$atendimentoId/sinais-vitais',
      data: sinaisVitais.toJson(),
    );
  }

  static String userMessageFor(Object error) {
    if (error is FormatException) {
      return 'A resposta da API não corresponde ao contrato esperado.';
    }
    if (error is DioException) {
      final code = error.response?.statusCode;
      if (code == 401) return 'Sua sessão expirou. Entre novamente.';
      if (code == 403) {
        return 'Seu perfil não tem permissão para esta operação.';
      }
      if (code == 404) {
        return 'O prontuário, atendimento ou especialidade não foi encontrado.';
      }
      if (code == 422) {
        return 'A API rejeitou os dados enviados. Revise os campos.';
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
    return 'Não foi possível iniciar ou salvar o atendimento.';
  }
}
