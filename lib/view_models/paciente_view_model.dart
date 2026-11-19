import 'package:flutter/foundation.dart';

import '../models/paciente_model.dart';
import '../models/prontuario_model.dart';
import '../services/repositories/paciente_repository.dart';

class PacienteViewModel extends ChangeNotifier {
  PacienteViewModel({required this.repository});

  final PacienteRepository repository;

  List<PacienteModel> _pacientes = const [];
  PacienteModel? _pacienteAtual;
  ProntuarioModel? _prontuario;
  String? _errorMessage;
  bool _isLoading = false;
  bool _isCreating = false;
  bool _isDeleting = false;

  List<PacienteModel> get pacientes => _pacientes;
  PacienteModel? get pacienteAtual => _pacienteAtual;
  ProntuarioModel? get prontuario => _prontuario;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isCreating => _isCreating;
  bool get isDeleting => _isDeleting;

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
      _errorMessage = PacienteRepository.userMessageFor(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<PacienteModel?> createPatient(PacienteModel paciente) async {
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
      _errorMessage = PacienteRepository.userMessageFor(error);
      return null;
    } finally {
      _isCreating = false;
      notifyListeners();
    }
  }

  Future<PacienteModel?> updatePatient(PacienteModel paciente) async {
    _isCreating = true;
    _errorMessage = null;
    notifyListeners();
    try {
      return await repository.updatePatient(paciente);
    } catch (error) {
      _errorMessage = PacienteRepository.userMessageFor(error);
      return null;
    } finally {
      _isCreating = false;
      notifyListeners();
    }
  }

  Future<bool> deletePatient(int id) async {
    _isDeleting = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await repository.deletePatient(id);
      _pacientes = _pacientes
          .where((patient) => patient.pacienteId != id)
          .toList();
      return true;
    } catch (error) {
      _errorMessage = PacienteRepository.userMessageFor(error);
      return false;
    } finally {
      _isDeleting = false;
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
      _errorMessage = PacienteRepository.userMessageFor(error);
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
