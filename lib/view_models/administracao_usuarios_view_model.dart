import 'package:flutter/foundation.dart';

import '../models/usuario_model.dart';
import '../services/repositories/autenticacao_repository.dart';

class AdministracaoUsuariosViewModel extends ChangeNotifier {
  AdministracaoUsuariosViewModel({
    required AutenticacaoRepository authRepository,
  }) : _repository = authRepository;

  final AutenticacaoRepository _repository;

  List<UsuarioModel> _usuarios = [];
  final Set<int> _usuariosAtualizando = {};
  bool _isLoading = true;
  int _savingOperations = 0;
  String? _loadErrorMessage;
  String? _operationErrorMessage;
  String? _successMessage;

  List<UsuarioModel> get usuarios => List.unmodifiable(_usuarios);
  Set<int> get usuariosAtualizando => Set.unmodifiable(_usuariosAtualizando);
  bool get isLoading => _isLoading;
  bool get isSaving => _savingOperations > 0;
  String? get loadErrorMessage => _loadErrorMessage;
  String? get operationErrorMessage => _operationErrorMessage;
  String? get successMessage => _successMessage;

  Future<void> loadUsers() async {
    _isLoading = true;
    _loadErrorMessage = null;
    notifyListeners();

    try {
      _usuarios = await _repository.listUsuarios();
    } catch (error) {
      _loadErrorMessage = AutenticacaoRepository.userMessageFor(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createUser({
    required String nome,
    required String email,
    required String senha,
    required PerfilUsuario perfil,
    String? matricula,
  }) async {
    _beginSaving();
    try {
      final usuario = await _repository.createUsuario(
        nome: nome,
        email: email,
        senha: senha,
        perfil: perfil,
        matricula: matricula,
      );
      _usuarios = [..._usuarios, usuario];
      _loadErrorMessage = null;
      _successMessage = 'Usuário cadastrado com sucesso.';
    } catch (error) {
      _operationErrorMessage = AutenticacaoRepository.userMessageFor(error);
    } finally {
      _finishSaving();
    }
  }

  Future<void> updateUser({
    required int id,
    required String nome,
    required String email,
    required PerfilUsuario perfil,
    String? matricula,
    String? senha,
  }) async {
    _beginSaving();
    try {
      final usuario = await _repository.updateUsuario(
        id,
        nome: nome,
        email: email,
        perfil: perfil,
        matricula: matricula,
        senha: senha,
      );
      _replaceUser(usuario);
      _successMessage = 'Dados do usuário atualizados.';
    } catch (error) {
      _operationErrorMessage = AutenticacaoRepository.userMessageFor(error);
    } finally {
      _finishSaving();
    }
  }

  Future<void> updateUserStatus(int id, {required bool ativo}) async {
    _beginOperation();
    _usuariosAtualizando.add(id);
    notifyListeners();
    try {
      final usuario = await _repository.updateUsuarioStatus(id, ativo: ativo);
      _replaceUser(usuario);
    } catch (error) {
      _operationErrorMessage = AutenticacaoRepository.userMessageFor(error);
    } finally {
      _usuariosAtualizando.remove(id);
      notifyListeners();
    }
  }

  Future<void> deleteUser(int id) async {
    _beginSaving();
    try {
      await _repository.deleteUsuario(id);
      _usuarios = _usuarios.where((usuario) => usuario.id != id).toList();
      _successMessage = 'Usuário excluído.';
    } catch (error) {
      _operationErrorMessage = AutenticacaoRepository.userMessageFor(error);
    } finally {
      _finishSaving();
    }
  }

  void clearOperationFeedback() {
    _operationErrorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void _beginSaving() {
    _beginOperation();
    _savingOperations++;
    notifyListeners();
  }

  void _beginOperation() {
    _operationErrorMessage = null;
    _successMessage = null;
  }

  void _finishSaving() {
    _savingOperations--;
    notifyListeners();
  }

  void _replaceUser(UsuarioModel updated) {
    _usuarios = [
      for (final usuario in _usuarios)
        if (usuario.id == updated.id) updated else usuario,
    ];
  }
}
