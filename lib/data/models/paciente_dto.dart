class PacienteDto {
  const PacienteDto({
    this.pacienteId,
    this.prontuarioId,
    this.nomeCompleto,
    this.cpf,
    this.rg,
    this.dataNascimento,
    this.sexo,
    this.celular,
  });

  /// `paciente_id` appears in the documented patient creation response.
  final int? pacienteId;

  /// Returned when the API resolves the patient's linked medical record.
  final int? prontuarioId;

  final String? nomeCompleto;
  final String? cpf;
  final String? rg;
  final String? dataNascimento;
  final String? sexo;
  final String? celular;

  factory PacienteDto.fromJson(Map<String, dynamic> json) => PacienteDto(
    // The create response uses `paciente_id`; patient list/detail responses
    // expose the same identifier as `id`.
    pacienteId: _optionalInt(json['paciente_id'] ?? json['id'], 'id'),
    prontuarioId: _optionalInt(json['prontuario_id'], 'prontuario_id'),
    nomeCompleto: json['nome_completo'] as String?,
    cpf: json['cpf'] as String?,
    rg: json['rg'] as String?,
    dataNascimento: json['data_nascimento']?.toString(),
    sexo: json['sexo'] as String?,
    celular: json['celular'] as String?,
  );

  static int? _optionalInt(Object? value, String field) {
    if (value == null) return null;
    if (value is int) return value;
    throw FormatException('Campo $field deve ser um inteiro ou null.');
  }

  /// Fields shown in the contract's patient creation request.
  Map<String, dynamic> toCreateJson() => {
    if (nomeCompleto != null) 'nome_completo': nomeCompleto,
    if (cpf != null) 'cpf': cpf,
    if (rg != null) 'rg': rg,
    if (dataNascimento != null) 'data_nascimento': dataNascimento,
    if (sexo != null) 'sexo': sexo,
    if (celular != null) 'celular': celular,
  };
}
