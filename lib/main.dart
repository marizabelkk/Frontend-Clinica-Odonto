import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/network/api_client.dart';
import 'core/network/auth_token_store.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/brand_background.dart';
import 'services/repositories/autenticacao_repository.dart';
import 'services/repositories/atendimento_repository.dart';
import 'services/repositories/odontograma_repository.dart';
import 'services/repositories/paciente_repository.dart';
import 'services/repositories/semiologia_repository.dart';
import 'services/repositories/professor_repository.dart';
import 'view_models/atendimento_view_model.dart';
import 'view_models/autenticacao_view_model.dart';
import 'view_models/odontograma_view_model.dart';
import 'view_models/tema_view_model.dart';
import 'view_models/paciente_view_model.dart';
import 'view_models/semiologia_view_model.dart';
import 'view_models/professor_view_model.dart';
import 'views/autenticacao/entrar_view.dart';

void main() {
  final tokenStore = AuthTokenStore();
  final apiClient = ApiClient(
    tokenProvider: () async => tokenStore.accessToken,
  );
  final authRepository = AutenticacaoRepository(
    apiClient: apiClient,
    tokenStore: tokenStore,
  );
  final patientRepository = PacienteRepository(apiClient: apiClient);
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

  final AutenticacaoRepository authRepository;
  final PacienteRepository patientRepository;
  final AtendimentoRepository atendimentoRepository;
  final SemiologiaRepository semiologiaRepository;
  final ProfessorRepository professorRepository;

  /// Opcional: por padrão usa o mesmo cliente HTTP do login.
  final OdontogramaRepository? odontogramaRepository;

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => TemaViewModel()..load()),
      ChangeNotifierProvider(
        create: (_) => AutenticacaoViewModel(repository: authRepository),
      ),
      ChangeNotifierProvider(
        create: (_) => PacienteViewModel(repository: patientRepository),
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
    child: Consumer<TemaViewModel>(
      builder: (context, theme, _) => MaterialApp(
        title: 'Prontuário Odontológico',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: theme.mode,
        builder: (context, child) =>
            BrandBackground(child: child ?? const SizedBox.shrink()),
        home: const EntrarView(),
      ),
    ),
  );
}
