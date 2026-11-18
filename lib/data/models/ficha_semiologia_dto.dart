enum StatusFicha {
  rascunho('RASCUNHO'),
  aguardandoAprovacao('AGUARDANDO_APROVACAO'),
  correcaoSolicitada('CORRECAO_SOLICITADA'),
  aprovada('APROVADA');

  const StatusFicha(this.apiValue);

  final String apiValue;

  static StatusFicha fromApi(String value) => StatusFicha.values.firstWhere(
    (status) => status.apiValue == value,
    orElse: () => throw FormatException('Status de ficha desconhecido: $value'),
  );
}

class FichaSemiologiaDto {
  const FichaSemiologiaDto({
    required this.id,
    required this.atendimentoId,
    required this.status,
    required this.versao,
    this.criadaEm,
    this.enviadaEm,
    this.aprovadaEm,
    this.semiologia,
  });

  final int id;
  final int atendimentoId;
  final StatusFicha status;
  final int versao;
  final DateTime? criadaEm;
  final DateTime? enviadaEm;
  final DateTime? aprovadaEm;
  final SemiologiaDraftDto? semiologia;

  factory FichaSemiologiaDto.fromJson(Map<String, dynamic> json) {
    final data = json['semiologia'];
    return FichaSemiologiaDto(
        id: json['id'] as int,
        atendimentoId: json['atendimento_id'] as int,
        status: StatusFicha.fromApi(json['status'] as String),
        versao: json['versao'] as int,
        criadaEm: _dateTime(json['criada_em']),
        enviadaEm: _dateTime(json['enviada_em']),
        aprovadaEm: _dateTime(json['aprovada_em']),
        semiologia: data is Map
            ? SemiologiaDraftDto.fromJson(Map<String, dynamic>.from(data))
            : null,
      );
  }

  static DateTime? _dateTime(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;
}

/// Text fields supported by the semiology draft API.
class SemiologiaDraftDto {
  const SemiologiaDraftDto({
    this.queixaPrincipal,
    this.historiaDoencaAtual,
    this.antecedentesFamiliares,
    this.medicamentosAlergias,
    this.habitosHistoriaOdontologica,
    this.observacoesGerais,
    this.diagnostico,
    this.planoTratamento,
    this.necessitaEncaminhamento = false,
    this.especialidadeEncaminhamentoId,
    this.motivoEncaminhamento,
  });

  final String? queixaPrincipal;
  final String? historiaDoencaAtual;
  final String? antecedentesFamiliares;
  final String? medicamentosAlergias;
  final String? habitosHistoriaOdontologica;
  final String? observacoesGerais;
  final String? diagnostico;
  final String? planoTratamento;
  final bool necessitaEncaminhamento;
  final int? especialidadeEncaminhamentoId;
  final String? motivoEncaminhamento;

  factory SemiologiaDraftDto.fromJson(Map<String, dynamic> json) =>
      SemiologiaDraftDto(
        queixaPrincipal: json['queixa_principal'] as String?,
        historiaDoencaAtual: json['historia_doenca_atual'] as String?,
        antecedentesFamiliares: json['antecedentes_familiares'] as String?,
        medicamentosAlergias: json['medicamentos_alergias'] as String?,
        habitosHistoriaOdontologica: json['habitos_historia_odontologica'] as String?,
        observacoesGerais: json['observacoes_gerais'] as String?,
        diagnostico: json['diagnostico'] as String?,
        planoTratamento: json['plano_tratamento'] as String?,
        necessitaEncaminhamento: json['necessita_encaminhamento'] as bool? ?? false,
        especialidadeEncaminhamentoId: json['especialidade_encaminhamento_id'] as int?,
        motivoEncaminhamento: json['motivo_encaminhamento'] as String?,
      );

  Map<String, dynamic> toJson() => {
    if (queixaPrincipal != null) 'queixa_principal': queixaPrincipal,
    if (historiaDoencaAtual != null)
      'historia_doenca_atual': historiaDoencaAtual,
    if (antecedentesFamiliares != null)
      'antecedentes_familiares': antecedentesFamiliares,
    if (medicamentosAlergias != null)
      'medicamentos_alergias': medicamentosAlergias,
    if (habitosHistoriaOdontologica != null)
      'habitos_historia_odontologica': habitosHistoriaOdontologica,
    if (observacoesGerais != null) 'observacoes_gerais': observacoesGerais,
    if (diagnostico != null) 'diagnostico': diagnostico,
    if (planoTratamento != null) 'plano_tratamento': planoTratamento,
    'necessita_encaminhamento': necessitaEncaminhamento,
    if (especialidadeEncaminhamentoId != null)
      'especialidade_encaminhamento_id': especialidadeEncaminhamentoId,
    if (motivoEncaminhamento != null)
      'motivo_encaminhamento': motivoEncaminhamento,
  };
}
