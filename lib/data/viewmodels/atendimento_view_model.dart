import 'package:flutter/foundation.dart';

import '../../data/models/atendimento_dto.dart';
import '../../data/models/especialidade_dto.dart';
import '../../data/models/ficha_semiologia_dto.dart';
import '../repositories/atendimento_repository.dart';
import '../repositories/semiologia_repository.dart';

class AtendimentoViewModel extends ChangeNotifier {
  AtendimentoViewModel({
    required this.atendimentoRepository,
    required this.semiologiaRepository,
  });

  final AtendimentoRepository atendimentoRepository;
  final SemiologiaRepository semiologiaRepository;

  AtendimentoDto? _atendimento;
  FichaSemiologiaDto? _ficha;
  int? _activeProntuarioId;
  List<EspecialidadeDto> _especialidades = const [];
  String? _specialtyErrorMessage;
  String? _errorMessage;
  bool _isLoading = false;
  bool _isLoadingSpecialties = false;

  AtendimentoDto? get atendimento => _atendimento;
  FichaSemiologiaDto? get ficha => _ficha;
  int? get activeProntuarioId => _activeProntuarioId;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  List<EspecialidadeDto> get especialidades => _especialidades;
  String? get specialtyErrorMessage => _specialtyErrorMessage;
  bool get isLoadingSpecialties => _isLoadingSpecialties;
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

  Future<FichaSemiologiaDto?> startSemiologia({
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

  Future<bool> saveVitalSigns(SinaisVitaisDto sinaisVitais) async {
    final atendimentoId = _atendimento?.id;
    if (atendimentoId == null) {
      _errorMessage = 'Inicie um atendimento antes de salvar sinais vitais.';
      notifyListeners();
      return false;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await atendimentoRepository.saveVitalSigns(
        atendimentoId: atendimentoId,
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
