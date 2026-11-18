class AtendimentoDto {
  const AtendimentoDto({required this.id});

  final int id;

  factory AtendimentoDto.fromJson(Map<String, dynamic> json) =>
      AtendimentoDto(id: json['id'] as int);
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
