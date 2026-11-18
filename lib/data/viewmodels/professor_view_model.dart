import 'package:flutter/foundation.dart';

import '../models/professor_ficha_dto.dart';
import '../repositories/professor_repository.dart';

class ProfessorViewModel extends ChangeNotifier {
  ProfessorViewModel({required this.repository});

  final ProfessorRepository repository;
  List<ProfessorFichaDto> _pending = const [];
  ProfessorFichaDto? _selected;
  String? _errorMessage;
  bool _isLoading = false;
  bool _isSubmittingDecision = false;

  List<ProfessorFichaDto> get pending => _pending;
  ProfessorFichaDto? get selected => _selected;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isSubmittingDecision => _isSubmittingDecision;

  Future<void> loadPending() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _pending = await repository.listPending();
    } catch (error) {
      _errorMessage = ProfessorRepository.userMessageFor(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> loadFicha(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _selected = await repository.getFicha(id);
      return true;
    } catch (error) {
      _errorMessage = ProfessorRepository.userMessageFor(error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> decide({
    required DecisaoProfessor decisao,
    String? observacao,
  }) async {
    final ficha = _selected;
    if (ficha == null) return false;
    _isSubmittingDecision = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await repository.registerDecision(
        fichaId: ficha.id,
        decisao: decisao,
        observacao: observacao,
      );
      _selected = null;
      await loadPending();
      return true;
    } catch (error) {
      _errorMessage = ProfessorRepository.userMessageFor(error);
      return false;
    } finally {
      _isSubmittingDecision = false;
      notifyListeners();
    }
  }

  void clearSelection() {
    _selected = null;
    _errorMessage = null;
    notifyListeners();
  }
}
