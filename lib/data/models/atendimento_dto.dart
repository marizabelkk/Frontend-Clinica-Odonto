import 'ficha_semiologia_dto.dart';
import 'paciente_dto.dart';

class AtendimentoDto {
  const AtendimentoDto({
    required this.id,
    this.prontuarioId,
    this.especialidadeId,
    this.iniciadoEm,
    this.finalizadoEm,
    this.fichaId,
    this.status,
    this.especialidadeNome,
    this.observacaoCorrecao,
  });

  final int id;
  final int? prontuarioId;
  final int? especialidadeId;
  final DateTime? iniciadoEm;
  final DateTime? finalizadoEm;
  final int? fichaId;
  final StatusFicha? status;
  final String? especialidadeNome;
  final String? observacaoCorrecao;

  factory AtendimentoDto.fromJson(Map<String, dynamic> json) {
    final rawFicha = json['ficha'];
    final ficha = rawFicha is Map ? Map<String, dynamic>.from(rawFicha) : null;
    final rawStatus = json['status'] ?? ficha?['status'];
    StatusFicha? status;
    if (rawStatus is String) {
      for (final value in StatusFicha.values) {
        if (value.apiValue == rawStatus) status = value;
      }
    }
    return AtendimentoDto(
      id: json['id'] as int,
      prontuarioId: json['prontuario_id'] as int?,
      especialidadeId: json['especialidade_id'] as int?,
      iniciadoEm: _dateTime(json['iniciado_em']),
      finalizadoEm: _dateTime(json['finalizado_em']),
      fichaId: json['ficha_id'] as int? ?? ficha?['id'] as int?,
      status: status,
      especialidadeNome: json['especialidade_nome'] as String?,
      observacaoCorrecao: json['observacao_correcao'] as String?,
    );
  }

  static DateTime? _dateTime(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;
}

class MeuAtendimentoDto {
  const MeuAtendimentoDto({
    required this.atendimento,
    required this.status,
    this.paciente,
  });

  final AtendimentoDto atendimento;
  final StatusFicha? status;
  final PacienteDto? paciente;

  MeuAtendimentoDto copyWithPaciente(PacienteDto? value) => MeuAtendimentoDto(
    atendimento: atendimento,
    status: status,
    paciente: value,
  );
}

class SinaisVitaisDto {
  const SinaisVitaisDto({
    this.pressaoSistolica,
    this.pressaoDiastolica,
    this.pulso,
    this.frequenciaRespiratoria,
    this.temperatura,
    this.peso,
    this.altura,
    this.glicemia,
  });

  final int? pressaoSistolica;
  final int? pressaoDiastolica;
  final int? pulso;
  final int? frequenciaRespiratoria;
  final double? temperatura;
  final double? peso;
  final double? altura;
  final double? glicemia;

  factory SinaisVitaisDto.fromJson(Map<String, dynamic> json) =>
      SinaisVitaisDto(
        pressaoSistolica: (json['pressao_sistolica'] as num?)?.toInt(),
        pressaoDiastolica: (json['pressao_diastolica'] as num?)?.toInt(),
        pulso: (json['pulso'] as num?)?.toInt(),
        frequenciaRespiratoria:
            (json['frequencia_respiratoria'] as num?)?.toInt(),
        temperatura: (json['temperatura'] as num?)?.toDouble(),
        peso: (json['peso'] as num?)?.toDouble(),
        altura: (json['altura'] as num?)?.toDouble(),
        glicemia: (json['glicemia'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
    if (pressaoSistolica != null) 'pressao_sistolica': pressaoSistolica,
    if (pressaoDiastolica != null) 'pressao_diastolica': pressaoDiastolica,
    if (pulso != null) 'pulso': pulso,
    if (frequenciaRespiratoria != null)
      'frequencia_respiratoria': frequenciaRespiratoria,
    if (temperatura != null) 'temperatura': temperatura,
    if (peso != null) 'peso': peso,
    if (altura != null) 'altura': altura,
    if (glicemia != null) 'glicemia': glicemia,
  };
}
