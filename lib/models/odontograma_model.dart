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

/// Condição do catálogo (`GET condicoes-odontologicas`).
class CondicaoOdontologicaModel {
  const CondicaoOdontologicaModel({
    required this.id,
    required this.codigo,
    required this.nome,
  });

  final int id;
  final String codigo;
  final String nome;

  factory CondicaoOdontologicaModel.fromJson(Map<String, dynamic> json) =>
      CondicaoOdontologicaModel(
        id: json['id'] as int,
        codigo: json['codigo'] as String,
        nome: json['nome'] as String,
      );
}

/// Uma condição registrada em um dente/face durante um atendimento.
class OdontogramaRegistroModel {
  const OdontogramaRegistroModel({
    required this.id,
    required this.atendimentoId,
    required this.numeroDente,
    required this.face,
    required this.condicaoId,
    this.registradoPor,
    this.observacao,
    this.registradoEm,
  });

  final int id;
  final int atendimentoId;
  final int numeroDente;
  final FaceDente face;
  final int condicaoId;
  final int? registradoPor;
  final String? observacao;
  final DateTime? registradoEm;

  factory OdontogramaRegistroModel.fromJson(Map<String, dynamic> json) =>
      OdontogramaRegistroModel(
        id: json['id'] as int,
        atendimentoId: json['atendimento_id'] as int,
        numeroDente: json['numero_dente'] as int,
        face: FaceDente.fromApi(json['face'] as String),
        condicaoId: json['condicao_id'] as int,
        registradoPor: json['registrado_por'] as int?,
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
