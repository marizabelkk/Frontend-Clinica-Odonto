import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/network/api_client.dart';
import 'core/network/auth_token_store.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/brand_background.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/atendimento_repository.dart';
import 'data/repositories/odontograma_repository.dart';
import 'data/repositories/patient_repository.dart';
import 'data/repositories/semiologia_repository.dart';
import 'data/repositories/professor_repository.dart';
import 'data/viewmodels/atendimento_view_model.dart';
import 'data/viewmodels/auth_view_model.dart';
import 'data/viewmodels/odontograma_view_model.dart';
import 'data/viewmodels/theme_view_model.dart';
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
    this.odontogramaRepository,
    super.key,
  });

  final AuthRepository authRepository;
  final PatientRepository patientRepository;
  final AtendimentoRepository atendimentoRepository;
  final SemiologiaRepository semiologiaRepository;
  final ProfessorRepository professorRepository;

  /// Opcional: por padrão usa o mesmo cliente HTTP do login.
  final OdontogramaRepository? odontogramaRepository;

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeViewModel()..load()),
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
          patientRepository: patientRepository,
        ),
      ),
      ChangeNotifierProvider(
        create: (_) => SemiologiaViewModel(repository: semiologiaRepository),
      ),
      ChangeNotifierProvider(
        create: (_) => ProfessorViewModel(repository: professorRepository),
      ),
      ChangeNotifierProvider(
        create: (_) => OdontogramaViewModel(
          repository:
              odontogramaRepository ??
              OdontogramaRepository(apiClient: authRepository.apiClient),
        ),
      ),
    ],
    child: Consumer<ThemeViewModel>(
      builder: (context, theme, _) => MaterialApp(
        title: 'Prontuário Odontológico',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: theme.mode,
        builder: (context, child) =>
            BrandBackground(child: child ?? const SizedBox.shrink()),
        home: const LoginView(),
      ),
    ),
  );
}
