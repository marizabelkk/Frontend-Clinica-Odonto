import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondonto_uninassau/core/network/api_client.dart';
import 'package:ondonto_uninassau/core/network/demo_api_adapter.dart';
import 'package:ondonto_uninassau/data/repositories/patient_repository.dart';
import 'package:ondonto_uninassau/data/repositories/professor_repository.dart';

void main() {
  test(
    'demo adapter serves fictional patients and professor review data',
    () async {
      final apiClient = ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'https://demo.invalid/api/v1'))
          ..httpClientAdapter = DemoApiAdapter(),
      );
      final patients = await PatientRepository(apiClient: apiClient)
          .searchPatients();
      final pending = await ProfessorRepository(apiClient: apiClient)
          .listPending();
      final detail = await ProfessorRepository(apiClient: apiClient)
          .getFicha(pending.first.id);

      expect(patients, hasLength(2));
      expect(patients.first.nomeCompleto, contains('demonstração'));
      expect(pending, hasLength(1));
      expect(detail.data['aluno_responsavel'], isA<Map>());
    },
  );
}
