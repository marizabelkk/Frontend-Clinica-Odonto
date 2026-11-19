import 'paciente_model.dart';

class ProntuarioModel {
  const ProntuarioModel({
    required this.id,
    required this.pacienteId,
    required this.criadoEm,
    required this.paciente,
    required this.condicoesMedicas,
    required this.alergias,
    required this.medicamentos,
    required this.atendimentos,
  });

  final int id;
  final int pacienteId;
  final String criadoEm;
  final PacienteModel paciente;
  final List<Map<String, dynamic>> condicoesMedicas;
  final List<Map<String, dynamic>> alergias;
  final List<Map<String, dynamic>> medicamentos;
  final List<Map<String, dynamic>> atendimentos;

  factory ProntuarioModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final pacienteId = json['paciente_id'];
    final criadoEm = json['criado_em'];
    final patientJson = json['paciente'];
    if (id is! int ||
        pacienteId is! int ||
        criadoEm is! String ||
        patientJson is! Map ||
        !_isObjectList(json['condicoes_medicas']) ||
        !_isObjectList(json['alergias']) ||
        !_isObjectList(json['medicamentos']) ||
        !_isObjectList(json['atendimentos'])) {
      throw const FormatException(
        'A API retornou o prontuário em formato inválido.',
      );
    }

    return ProntuarioModel(
      id: id,
      pacienteId: pacienteId,
      criadoEm: criadoEm,
      paciente: PacienteModel.fromJson(Map<String, dynamic>.from(patientJson)),
      condicoesMedicas: _mapList(json, 'condicoes_medicas'),
      alergias: _mapList(json, 'alergias'),
      medicamentos: _mapList(json, 'medicamentos'),
      atendimentos: _mapList(json, 'atendimentos'),
    );
  }

  Map<String, dynamic> get resumo => {
    'condicoes_medicas': condicoesMedicas,
    'alergias': alergias,
    'medicamentos': medicamentos,
    'atendimentos': atendimentos,
  };

  static List<Map<String, dynamic>> _mapList(
    Map<String, dynamic> json,
    String key,
  ) {
    final value = json[key];
    if (value is! List) {
      throw FormatException('A resposta do prontuário não contém $key.');
    }
    return value
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(growable: false);
  }

  static bool _isObjectList(Object? value) =>
      value is List && value.every((item) => item is Map);
}
