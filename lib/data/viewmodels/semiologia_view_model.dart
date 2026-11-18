import 'package:flutter/foundation.dart';

import '../../data/models/ficha_semiologia_dto.dart';
import '../repositories/semiologia_repository.dart';

class SemiologiaViewModel extends ChangeNotifier {
  SemiologiaViewModel({required this.repository});

  final SemiologiaRepository repository;

  String? _errorMessage;
  String? _successMessage;
  StatusFicha? _status;
  bool _isSaving = false;

  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  StatusFicha? get status => _status;
  bool get isSaving => _isSaving;

  Future<bool> saveDraft({
    required int fichaId,
    required SemiologiaDraftDto draft,
    required StatusFicha currentStatus,
  }) async {
    if (currentStatus != StatusFicha.rascunho &&
        currentStatus != StatusFicha.correcaoSolicitada) {
      _errorMessage = 'A ficha não está em um estado editável pelo aluno.';
      notifyListeners();
      return false;
    }
    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
    try {
      await repository.saveDraft(fichaId: fichaId, draft: draft);
      _status = currentStatus;
      _successMessage = 'Rascunho salvo.';
      return true;
    } catch (error) {
      _errorMessage = SemiologiaRepository.userMessageFor(error);
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> submit({
    required int fichaId,
    required StatusFicha currentStatus,
  }) async {
    if (currentStatus != StatusFicha.rascunho &&
        currentStatus != StatusFicha.correcaoSolicitada) {
      _errorMessage = 'A ficha não pode ser enviada no estado atual.';
      notifyListeners();
      return false;
    }
    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
    try {
      _status = await repository.submit(fichaId);
      _successMessage = 'Ficha enviada para aprovação.';
      return _status == StatusFicha.aguardandoAprovacao;
    } catch (error) {
      _errorMessage = SemiologiaRepository.userMessageFor(error);
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}
