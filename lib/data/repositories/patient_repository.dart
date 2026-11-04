import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../models/paciente_dto.dart';
import '../models/prontuario_dto.dart';

class PatientRepository {
  const PatientRepository({required this.apiClient});

  final ApiClient apiClient;

  Future<List<PacienteDto>> searchPatients({String? nome, String? cpf}) async {
    final queryParameters = <String, dynamic>{
      if (nome != null && nome.trim().isNotEmpty) 'busca': nome.trim(),
      if (cpf != null && cpf.trim().isNotEmpty) 'cpf': _digitsOnly(cpf),
    };

    final response = await apiClient.dio.get<Object?>(
      'pacientes',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );
    final data = response.data;
    if (data is! List) {
      throw const FormatException(
        'A API não retornou a lista de pacientes no formato esperado.',
      );
    }
    return data
        .map(
          (item) =>
              PacienteDto.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(growable: false);
  }

  Future<PacienteDto> createPatient(PacienteDto paciente) async {
    final response = await apiClient.dio.post<Map<String, dynamic>>(
      'pacientes',
      data: paciente.toCreateJson(),
    );
    final data = response.data;
    if (data == null) {
      throw const FormatException(
        'A API retornou uma resposta vazia ao cadastrar o paciente.',
      );
    }
    return PacienteDto.fromJson(data);
  }

  Future<PacienteDto> getPatient(int id) async {
    final response = await apiClient.dio.get<Map<String, dynamic>>(
      'pacientes/$id',
    );
    final data = response.data;
    if (data == null) {
      throw const FormatException(
        'A API retornou uma resposta vazia para o paciente.',
      );
    }
    return PacienteDto.fromJson(data);
  }

  Future<ProntuarioDto> getProntuario(int pacienteId) async {
    final response = await apiClient.dio.get<Map<String, dynamic>>(
      'pacientes/$pacienteId/prontuario',
    );
    final data = response.data;
    if (data == null) {
      throw const FormatException(
        'A API retornou uma resposta vazia para o prontuário.',
      );
    }
    return ProntuarioDto.fromJson(data);
  }

  static String userMessageFor(Object error) {
    if (error is FormatException) {
      return 'A resposta da API está fora do formato esperado.';
    }
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 401) return 'Sua sessão expirou. Entre novamente.';
      if (statusCode == 403) {
        return 'Seu perfil não tem permissão para esta operação.';
      }
      if (statusCode == 404) return 'Paciente ou prontuário não encontrado.';
      if (statusCode == 409) {
        return 'Já existe um paciente cadastrado com esse CPF.';
      }
      if (statusCode == 422) {
        return 'A API rejeitou os dados. Revise o cadastro e tente novamente.';
      }
      if (statusCode != null && statusCode >= 500) {
        return 'O serviço está indisponível no momento. Tente novamente mais tarde.';
      }
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return 'Não foi possível conectar à API. Verifique o endereço e tente novamente.';
      }
    }
    return 'Não foi possível concluir a operação. Tente novamente.';
  }

  static String _digitsOnly(String value) =>
      value.replaceAll(RegExp(r'\D'), '');
}
