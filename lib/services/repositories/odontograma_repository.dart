import '../../core/network/api_client.dart';
import '../../models/odontograma_model.dart';

class OdontogramaRepository {
  const OdontogramaRepository({required this.apiClient});

  final ApiClient apiClient;

  /// Todos os registros do prontuário (inclui atendimentos anteriores).
  Future<List<OdontogramaRegistroModel>> listByProntuario(
    int prontuarioId,
  ) async {
    final response = await apiClient.dio.get<Map<String, dynamic>>(
      'prontuarios/$prontuarioId/odontograma',
    );
    final registros = response.data?['registros'] as List<dynamic>? ?? const [];
    return registros
        .map(
          (item) =>
              OdontogramaRegistroModel.fromJson(item as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  Future<List<CondicaoOdontologicaModel>> listCondicoes() async {
    final response = await apiClient.dio.get<List<dynamic>>(
      'condicoes-odontologicas',
    );
    return (response.data ?? const [])
        .map(
          (item) =>
              CondicaoOdontologicaModel.fromJson(item as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  Future<OdontogramaRegistroModel> create({
    required int atendimentoId,
    required OdontogramaRegistroInput input,
  }) async {
    final response = await apiClient.dio.post<Map<String, dynamic>>(
      'atendimentos/$atendimentoId/odontograma/registros',
      data: input.toJson(),
    );
    return OdontogramaRegistroModel.fromJson(response.data!);
  }

  Future<OdontogramaRegistroModel> update({
    required int atendimentoId,
    required int registroId,
    required OdontogramaRegistroInput input,
  }) async {
    final response = await apiClient.dio.put<Map<String, dynamic>>(
      'atendimentos/$atendimentoId/odontograma/registros/$registroId',
      data: input.toJson(),
    );
    return OdontogramaRegistroModel.fromJson(response.data!);
  }

  Future<void> delete({
    required int atendimentoId,
    required int registroId,
  }) async {
    await apiClient.dio.delete<void>(
      'atendimentos/$atendimentoId/odontograma/registros/$registroId',
    );
  }
}
