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
  });

  final int id;
  final int atendimentoId;
  final StatusFicha status;
  final int versao;

  factory FichaSemiologiaDto.fromJson(Map<String, dynamic> json) =>
      FichaSemiologiaDto(
        id: json['id'] as int,
        atendimentoId: json['atendimento_id'] as int,
        status: StatusFicha.fromApi(json['status'] as String),
        versao: json['versao'] as int,
      );
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
