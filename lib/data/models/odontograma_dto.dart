/// Faces do dente aceitas pela API (`FaceDente`).
enum FaceDente {
  vestibular('VESTIBULAR', 'Vestibular'),
  lingual('LINGUAL', 'Lingual'),
  palatina('PALATINA', 'Palatina'),
  mesial('MESIAL', 'Mesial'),
  distal('DISTAL', 'Distal'),
  oclusal('OCLUSAL', 'Oclusal'),
  incisal('INCISAL', 'Incisal'),
  denteInteiro('DENTE_INTEIRO', 'Dente inteiro');

  const FaceDente(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static FaceDente fromApi(String value) => FaceDente.values.firstWhere(
    (face) => face.apiValue == value,
    orElse: () => throw FormatException('Face de dente desconhecida: $value'),
  );
}

/// Defeito/condição do catálogo (`GET condicoes-odontologicas`).
class CondicaoOdontologicaDto {
  const CondicaoOdontologicaDto({
    required this.id,
    required this.codigo,
    required this.nome,
  });

  final int id;
  final String codigo;
  final String nome;

  factory CondicaoOdontologicaDto.fromJson(Map<String, dynamic> json) =>
      CondicaoOdontologicaDto(
        id: json['id'] as int,
        codigo: json['codigo'] as String,
        nome: json['nome'] as String,
      );
}

/// Um defeito registrado em um dente/face durante um atendimento.
class OdontogramaRegistroDto {
  const OdontogramaRegistroDto({
    required this.id,
    required this.atendimentoId,
    required this.numeroDente,
    required this.face,
    required this.condicaoId,
    this.observacao,
    this.registradoEm,
  });

  final int id;
  final int atendimentoId;
  final int numeroDente;
  final FaceDente face;
  final int condicaoId;
  final String? observacao;
  final DateTime? registradoEm;

  factory OdontogramaRegistroDto.fromJson(Map<String, dynamic> json) =>
      OdontogramaRegistroDto(
        id: json['id'] as int,
        atendimentoId: json['atendimento_id'] as int,
        numeroDente: json['numero_dente'] as int,
        face: FaceDente.fromApi(json['face'] as String),
        condicaoId: json['condicao_id'] as int,
        observacao: json['observacao'] as String?,
        registradoEm: json['registrado_em'] == null
            ? null
            : DateTime.tryParse(json['registrado_em'] as String),
      );
}

/// Dados enviados ao criar/editar um registro.
class OdontogramaRegistroInput {
  const OdontogramaRegistroInput({
    required this.numeroDente,
    required this.face,
    required this.condicaoId,
    this.observacao,
  });

  final int numeroDente;
  final FaceDente face;
  final int condicaoId;
  final String? observacao;

  Map<String, dynamic> toJson() => {
    'numero_dente': numeroDente,
    'face': face.apiValue,
    'condicao_id': condicaoId,
    'observacao': observacao ?? '',
  };
}
