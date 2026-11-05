import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/network/api_client.dart';
import 'core/network/auth_token_store.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/atendimento_repository.dart';
import 'data/repositories/patient_repository.dart';
import 'data/repositories/semiologia_repository.dart';
import 'data/repositories/professor_repository.dart';
import 'data/viewmodels/atendimento_view_model.dart';
import 'data/viewmodels/auth_view_model.dart';
import 'data/viewmodels/patient_view_model.dart';
import 'data/viewmodels/semiologia_view_model.dart';
import 'data/viewmodels/professor_view_model.dart';
import 'views/auth/login_view.dart';

void main() {
  final tokenStore = AuthTokenStore();
  final apiClient = ApiClient(
    tokenProvider: () async => tokenStore.accessToken,
  );
  final authRepository = AuthRepository(
    apiClient: apiClient,
    tokenStore: tokenStore,
  );
  final patientRepository = PatientRepository(apiClient: apiClient);
  final atendimentoRepository = AtendimentoRepository(apiClient: apiClient);
  final semiologiaRepository = SemiologiaRepository(apiClient: apiClient);
  final professorRepository = ProfessorRepository(apiClient: apiClient);

  runApp(
    MyApp(
      authRepository: authRepository,
      patientRepository: patientRepository,
      atendimentoRepository: atendimentoRepository,
      semiologiaRepository: semiologiaRepository,
      professorRepository: professorRepository,
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    required this.authRepository,
    required this.patientRepository,
    required this.atendimentoRepository,
    required this.semiologiaRepository,
    required this.professorRepository,
    super.key,
  });

  final AuthRepository authRepository;
  final PatientRepository patientRepository;
  final AtendimentoRepository atendimentoRepository;
  final SemiologiaRepository semiologiaRepository;
  final ProfessorRepository professorRepository;

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (_) => AuthViewModel(repository: authRepository),
      ),
      ChangeNotifierProvider(
        create: (_) => PatientViewModel(repository: patientRepository),
      ),
      ChangeNotifierProvider(
        create: (_) => AtendimentoViewModel(
          atendimentoRepository: atendimentoRepository,
          semiologiaRepository: semiologiaRepository,
        ),
      ),
      ChangeNotifierProvider(
        create: (_) => SemiologiaViewModel(repository: semiologiaRepository),
      ),
      ChangeNotifierProvider(
        create: (_) => ProfessorViewModel(repository: professorRepository),
      ),
    ],
    child: MaterialApp(
      title: 'Prontuário Odontológico',
      theme: AppTheme.lightTheme,
      home: const LoginView(),
    ),
  );
}
