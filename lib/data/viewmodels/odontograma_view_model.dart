import 'package:flutter/foundation.dart';

import '../../core/network/api_errors.dart';
import '../models/odontograma_dto.dart';
import '../repositories/odontograma_repository.dart';

class OdontogramaViewModel extends ChangeNotifier {
  OdontogramaViewModel({required this.repository});

  final OdontogramaRepository repository;

  int? _prontuarioId;
  int? _atendimentoId;
  int? _selectedTooth;
  List<OdontogramaRegistroDto> _registros = const [];
  List<CondicaoOdontologicaDto> _condicoes = const [];
  String? _errorMessage;
  bool _isLoading = false;
  bool _isSaving = false;

  int? get selectedTooth => _selectedTooth;
  List<OdontogramaRegistroDto> get registros => _registros;
  List<CondicaoOdontologicaDto> get condicoes => _condicoes;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;

  /// Registros do dente selecionado, do mais recente para o mais antigo.
  List<OdontogramaRegistroDto> get selectedToothRegistros =>
      registrosDoDente(_selectedTooth);

  List<OdontogramaRegistroDto> registrosDoDente(int? tooth) {
    if (tooth == null) return const [];
    return _registros.where((r) => r.numeroDente == tooth).toList()
      ..sort((a, b) => b.id.compareTo(a.id));
  }

  Map<int, List<OdontogramaRegistroDto>> get registrosPorDente {
    final map = <int, List<OdontogramaRegistroDto>>{};
    for (final registro in _registros) {
      map.putIfAbsent(registro.numeroDente, () => []).add(registro);
    }
    return map;
  }

  String condicaoNome(int condicaoId) {
    for (final condicao in _condicoes) {
      if (condicao.id == condicaoId) return condicao.nome;
    }
    return 'Condição #$condicaoId';
  }

  void selectTooth(int? tooth) {
    _selectedTooth = tooth;
    notifyListeners();
  }

  Future<void> load({required int prontuarioId, int? atendimentoId}) async {
    _prontuarioId = prontuarioId;
    _atendimentoId = atendimentoId;
    _selectedTooth = null;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        repository.listByProntuario(prontuarioId),
        repository.listCondicoes(),
      ]);
      _registros = results[0] as List<OdontogramaRegistroDto>;
      _condicoes = results[1] as List<CondicaoOdontologicaDto>;
    } catch (error) {
      _errorMessage = apiErrorMessage(error, fallback: _loadFailed);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cria (registro == null) ou atualiza um registro. Retorna a mensagem de erro, se houver.
  Future<String?> save(
    OdontogramaRegistroInput input, {
    OdontogramaRegistroDto? registro,
  }) async {
    final atendimentoId = _atendimentoId;
    if (atendimentoId == null) {
      return 'Nenhum atendimento ativo para registrar.';
    }
    return _run(() async {
      if (registro == null) {
        await repository.create(atendimentoId: atendimentoId, input: input);
      } else {
        await repository.update(
          atendimentoId: atendimentoId,
          registroId: registro.id,
          input: input,
        );
      }
    });
  }

  Future<String?> remove(OdontogramaRegistroDto registro) async {
    final atendimentoId = _atendimentoId;
    if (atendimentoId == null) return 'Nenhum atendimento ativo.';
    return _run(
      () => repository.delete(
        atendimentoId: atendimentoId,
        registroId: registro.id,
      ),
    );
  }

  Future<String?> _run(Future<void> Function() action) async {
    _isSaving = true;
    notifyListeners();
    try {
      await action();
      _registros = await repository.listByProntuario(_prontuarioId!);
      return null;
    } catch (error) {
      return apiErrorMessage(error, fallback: _saveFailed);
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  static const _loadFailed = 'Não foi possível carregar o odontograma.';
  static const _saveFailed = 'Não foi possível salvar a alteração.';
}
