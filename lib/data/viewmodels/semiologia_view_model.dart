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
  bool _isLoadingFicha = false;

  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  StatusFicha? get status => _status;
  bool get isSaving => _isSaving;
  bool get isLoadingFicha => _isLoadingFicha;

  Future<FichaSemiologiaDto?> loadFicha(int fichaId) async {
    _isLoadingFicha = true;
    _errorMessage = null;
    notifyListeners();
    try {
      return await repository.getFicha(fichaId);
    } catch (error) {
      _errorMessage = SemiologiaRepository.userMessageFor(error);
      return null;
    } finally {
      _isLoadingFicha = false;
      notifyListeners();
    }
  }

  Future<bool> deleteDraft({required int fichaId, required StatusFicha status}) async {
    if (status != StatusFicha.rascunho) {
      _errorMessage = 'Somente fichas em rascunho podem ser excluídas.';
      notifyListeners();
      return false;
    }
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await repository.deleteDraft(fichaId);
      _successMessage = 'Rascunho excluído.';
      return true;
    } catch (error) {
      _errorMessage = SemiologiaRepository.userMessageFor(error);
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

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
