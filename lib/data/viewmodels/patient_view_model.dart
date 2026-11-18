import 'package:flutter/foundation.dart';

import '../models/paciente_dto.dart';
import '../models/prontuario_dto.dart';
import '../repositories/patient_repository.dart';

class PatientViewModel extends ChangeNotifier {
  PatientViewModel({required this.repository});

  final PatientRepository repository;

  List<PacienteDto> _pacientes = const [];
  PacienteDto? _pacienteAtual;
  ProntuarioDto? _prontuario;
  String? _errorMessage;
  bool _isLoading = false;
  bool _isCreating = false;

  List<PacienteDto> get pacientes => _pacientes;
  PacienteDto? get pacienteAtual => _pacienteAtual;
  ProntuarioDto? get prontuario => _prontuario;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isCreating => _isCreating;

  Future<void> loadPatients({String? query}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final normalizedQuery = query?.trim() ?? '';
      if (normalizedQuery.isEmpty) {
        _pacientes = await repository.searchPatients();
      } else if (_looksLikeCpf(normalizedQuery)) {
        _pacientes = await repository.searchPatients(cpf: normalizedQuery);
      } else {
        _pacientes = await repository.searchPatients(nome: normalizedQuery);
      }
    } catch (error) {
      _pacientes = const [];
      _errorMessage = PatientRepository.userMessageFor(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<PacienteDto?> createPatient(PacienteDto paciente) async {
    _isCreating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final created = await repository.createPatient(paciente);
      if (created.pacienteId == null) {
        throw const FormatException(
          'A resposta não contém o identificador paciente_id.',
        );
      }
      return created;
    } catch (error) {
      _errorMessage = PatientRepository.userMessageFor(error);
      return null;
    } finally {
      _isCreating = false;
      notifyListeners();
    }
  }

  Future<void> loadProntuario(int pacienteId) async {
    _isLoading = true;
    _errorMessage = null;
    _prontuario = null;
    notifyListeners();

    try {
      _prontuario = await repository.getProntuario(pacienteId);
      _pacienteAtual = _prontuario!.paciente;
    } catch (error) {
      _pacienteAtual = null;
      _errorMessage = PatientRepository.userMessageFor(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  bool _looksLikeCpf(String value) =>
      value.isNotEmpty && RegExp(r'^[\d.\-/\s]+$').hasMatch(value);
}
