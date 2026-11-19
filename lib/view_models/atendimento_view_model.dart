import 'package:flutter/foundation.dart';

import '../models/atendimento_model.dart';
import '../models/especialidade_model.dart';
import '../models/ficha_semiologia_model.dart';
import '../models/paciente_model.dart';
import '../services/repositories/atendimento_repository.dart';
import '../services/repositories/paciente_repository.dart';
import '../services/repositories/semiologia_repository.dart';

class AtendimentoViewModel extends ChangeNotifier {
  AtendimentoViewModel({
    required this.atendimentoRepository,
    required this.semiologiaRepository,
    this.patientRepository,
  });

  final AtendimentoRepository atendimentoRepository;
  final SemiologiaRepository semiologiaRepository;
  final PacienteRepository? patientRepository;

  AtendimentoModel? _atendimento;
  FichaSemiologiaModel? _ficha;
  int? _activeProntuarioId;
  List<EspecialidadeModel> _especialidades = const [];
  String? _specialtyErrorMessage;
  String? _errorMessage;
  bool _isLoading = false;
  bool _isLoadingSpecialties = false;
  List<MeuAtendimentoModel> _myAttendances = const [];
  String? _myAttendancesError;
  bool _isLoadingMine = false;

  AtendimentoModel? get atendimento => _atendimento;
  FichaSemiologiaModel? get ficha => _ficha;
  int? get activeProntuarioId => _activeProntuarioId;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  List<EspecialidadeModel> get especialidades => _especialidades;
  String? get specialtyErrorMessage => _specialtyErrorMessage;
  bool get isLoadingSpecialties => _isLoadingSpecialties;
  List<MeuAtendimentoModel> get myAttendances => _myAttendances;
  String? get myAttendancesError => _myAttendancesError;
  bool get isLoadingMine => _isLoadingMine;

  int countForStatus(StatusFicha status) =>
      _myAttendances.where((item) => item.status == status).length;

  int countThisMonth(StatusFicha status) {
    final now = DateTime.now();
    return _myAttendances.where((item) {
      final started = item.atendimento.iniciadoEm?.toLocal();
      return item.status == status &&
          started != null &&
          started.year == now.year &&
          started.month == now.month;
    }).length;
  }

  Future<void> loadMyAttendances() async {
    _isLoadingMine = true;
    _myAttendancesError = null;
    notifyListeners();
    try {
      final all = await atendimentoRepository.listMine();

      Map<int, PacienteModel> patientsByRecord = {};
      try {
        final patients = patientRepository == null
            ? const <PacienteModel>[]
            : await patientRepository!.searchPatients();
        patientsByRecord = {
          for (final patient in patients)
            if (patient.prontuarioId != null) patient.prontuarioId!: patient,
        };
      } catch (_) {
        // A lista de atendimentos continua útil mesmo quando os dados de paciente falham.
      }

      _myAttendances = all.map((attendance) {
        return MeuAtendimentoModel(
          atendimento: attendance,
          status: attendance.status,
          paciente: attendance.prontuarioId == null
              ? null
              : patientsByRecord[attendance.prontuarioId],
        );
      }).toList(growable: false);
    } catch (error) {
      _myAttendancesError = AtendimentoRepository.userMessageFor(error);
    } finally {
      _isLoadingMine = false;
      notifyListeners();
    }
  }

  Future<String?> deleteAttendance(int attendanceId) async {
    try {
      await atendimentoRepository.deleteAttendance(attendanceId);
      await loadMyAttendances();
      return null;
    } catch (error) {
      return AtendimentoRepository.userMessageFor(error);
    }
  }

  Future<List<SinaisVitaisModel>> listVitalSigns(int attendanceId) =>
      atendimentoRepository.listVitalSigns(attendanceId);
  int? get semiologiaEspecialidadeId {
    final matches = _especialidades.where(
      (item) => item.ativo && item.nome.trim().toLowerCase() == 'semiologia',
    );
    return matches.length == 1 ? matches.single.id : null;
  }

  Future<void> loadEspecialidades() async {
    _isLoadingSpecialties = true;
    _specialtyErrorMessage = null;
    notifyListeners();
    try {
      _especialidades = await atendimentoRepository.listEspecialidades();
    } catch (error) {
      _especialidades = const [];
      _specialtyErrorMessage = AtendimentoRepository.userMessageFor(error);
    } finally {
      _isLoadingSpecialties = false;
      notifyListeners();
    }
  }

  Future<FichaSemiologiaModel?> startSemiologia({
    required int prontuarioId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final especialidadeId = semiologiaEspecialidadeId;
      if (especialidadeId == null) {
        throw const FormatException(
          'A API não retornou uma especialidade Semiologia ativa e única.',
        );
      }
      if (_atendimento == null ||
          _activeProntuarioId != prontuarioId ||
          _ficha != null) {
        _atendimento = await atendimentoRepository.create(
          prontuarioId: prontuarioId,
          especialidadeId: especialidadeId,
        );
        _activeProntuarioId = prontuarioId;
        _ficha = null;
      }
      _ficha = await semiologiaRepository.createFicha(_atendimento!.id);
      return _ficha;
    } catch (error) {
      _errorMessage = error is FormatException
          ? AtendimentoRepository.userMessageFor(error)
          : SemiologiaRepository.userMessageFor(error);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveVitalSigns(
    SinaisVitaisModel sinaisVitais, {
    int? atendimentoId,
  }) async {
    final targetId = atendimentoId ?? _atendimento?.id;
    if (targetId == null) {
      _errorMessage = 'Inicie um atendimento antes de salvar sinais vitais.';
      notifyListeners();
      return false;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await atendimentoRepository.saveVitalSigns(
        atendimentoId: targetId,
        sinaisVitais: sinaisVitais,
      );
      return true;
    } catch (error) {
      _errorMessage = AtendimentoRepository.userMessageFor(error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
