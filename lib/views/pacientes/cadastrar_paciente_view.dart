import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/paciente_model.dart';
import '../../view_models/paciente_view_model.dart';
import '../../widgets/cabecalho_pagina_aluno.dart';
import '../../widgets/navegacao_inferior_aluno.dart';
import '../atendimentos/meus_atendimentos_view.dart';
import '../recepcao/widgets/navegacao_inferior_recepcao.dart';

class CadastrarPacienteView extends StatefulWidget {
  const CadastrarPacienteView({
    this.showStudentNavigation = true,
    this.paciente,
    super.key,
  });

  final bool showStudentNavigation;
  final PacienteModel? paciente;

  @override
  State<CadastrarPacienteView> createState() => _CadastrarPacienteViewState();
}

class _CadastrarPacienteViewState extends State<CadastrarPacienteView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cpfController = TextEditingController();
  final _rgController = TextEditingController();
  final _sexController = TextEditingController();
  final _cellphoneController = TextEditingController();
  DateTime? _birthDate;
  bool _didSubmit = false;

  @override
  void initState() {
    super.initState();
    final paciente = widget.paciente;
    if (paciente == null) return;
    _nameController.text = paciente.nomeCompleto ?? '';
    _cpfController.text = paciente.cpf ?? '';
    _rgController.text = paciente.rg ?? '';
    _sexController.text = paciente.sexo ?? '';
    _cellphoneController.text = paciente.celular ?? '';
    final date = DateTime.tryParse(paciente.dataNascimento ?? '');
    if (date != null) _birthDate = date;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cpfController.dispose();
    _rgController.dispose();
    _sexController.dispose();
    _cellphoneController.dispose();
    super.dispose();
  }

  Future<void> _chooseBirthDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Data de nascimento',
    );
    if (selected != null) setState(() => _birthDate = selected);
  }

  Future<void> _submit() async {
    setState(() => _didSubmit = true);
    if (!_formKey.currentState!.validate()) return;
    final birthDate = _birthDate;
    if (birthDate == null && widget.paciente == null) {
      setState(() {});
      return;
    }

    final paciente = PacienteModel(
      nomeCompleto: _nameController.text.trim(),
      cpf: _cpfController.text.trim(),
      rg: _rgController.text.trim().isEmpty ? null : _rgController.text.trim(),
      dataNascimento: birthDate == null ? null : _dateForApi(birthDate),
      sexo: _sexController.text.trim(),
      celular: _cellphoneController.text.trim(),
    );
    final model = context.read<PacienteViewModel>();
    final saved = widget.paciente == null
        ? await model.createPatient(paciente)
        : await model.updatePatient(
            PacienteModel(
              pacienteId: widget.paciente!.pacienteId,
              prontuarioId: widget.paciente!.prontuarioId,
              nomeCompleto: paciente.nomeCompleto,
              cpf: paciente.cpf,
              rg: paciente.rg,
              dataNascimento: paciente.dataNascimento,
              sexo: paciente.sexo,
              celular: paciente.celular,
            ),
          );
    if (!mounted || saved == null) return;
    Navigator.of(context).pop(saved);
  }

  void _navigate(int index) {
    if (index == 0) {
      navegarParaInicioAluno(context);
    } else if (index == 2) {
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (_) => const MeusAtendimentosView()),
      );
    } else if (index == 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Acesse o perfil pelo menu da página inicial.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: EstiloPaginaAluno.background(context),
      body: Theme(
        data: EstiloPaginaAluno.readableTheme(context),
        child: Column(
          children: [
            CabecalhoPaginaAluno(
              title: widget.paciente == null
                  ? 'Cadastrar novo paciente'
                  : 'Editar paciente',
              subtitle: widget.paciente == null
                  ? 'Preencha os dados para criar o cadastro e o prontuário.'
                  : 'Atualize os dados cadastrais do paciente.',
            ),
            Expanded(
              child: SafeArea(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Text(
                        'Dados pessoais',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'O cadastro cria também o prontuário do paciente.',
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Nome completo *',
                        ),
                        validator: _required('Informe o nome completo.'),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _cpfController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'CPF *',
                          hintText: 'Somente números',
                        ),
                        validator: _requiredForCreation('Informe o CPF.'),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _rgController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(labelText: 'RG'),
                      ),
                      const SizedBox(height: 14),
                      InkWell(
                        onTap: _chooseBirthDate,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Data de nascimento *',
                            errorText:
                                widget.paciente == null &&
                                    _birthDate == null &&
                                    _didSubmit
                                ? 'Informe a data de nascimento.'
                                : null,
                            suffixIcon: const Icon(
                              Icons.calendar_month_outlined,
                            ),
                          ),
                          child: Text(
                            _birthDate == null
                                ? 'Selecione a data'
                                : _dateForDisplay(_birthDate!),
                            style: TextStyle(
                              color: _birthDate == null
                                  ? Theme.of(context).hintColor
                                  : null,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _sexController,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Sexo/gênero *',
                          hintText: 'Conforme informado pelo paciente',
                        ),
                        validator: _requiredForCreation('Informe sexo/gênero.'),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _cellphoneController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Celular *',
                          hintText: 'DDD e número, somente números',
                        ),
                        validator: _requiredForCreation('Informe o celular.'),
                      ),
                      const SizedBox(height: 18),
                      Consumer<PacienteViewModel>(
                        builder: (context, model, _) {
                          if (model.errorMessage == null) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              model.errorMessage!,
                              style: TextStyle(color: colors.error),
                            ),
                          );
                        },
                      ),
                      Consumer<PacienteViewModel>(
                        builder: (context, model, _) => ElevatedButton(
                          onPressed: model.isCreating ? null : _submit,
                          child: model.isCreating
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  widget.paciente == null
                                      ? 'Cadastrar paciente'
                                      : 'Salvar alterações',
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: widget.showStudentNavigation
          ? NavegacaoInferiorAluno(
              currentIndex: 1,
              onDestinationSelected: _navigate,
            )
          : NavegacaoInferiorRecepcao(
              currentIndex: 1,
              onDestinationSelected: (index) {
                if (index == 0) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
                if (index == 1 && Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
                if (index == 2) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Perfil da recepção')),
                  );
                }
              },
            ),
    );
  }

  FormFieldValidator<String> _required(String message) =>
      (value) => value == null || value.trim().isEmpty ? message : null;

  FormFieldValidator<String>? _requiredForCreation(String message) =>
      widget.paciente == null ? _required(message) : null;

  String _dateForApi(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  String _dateForDisplay(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year.toString().padLeft(4, '0')}';
}
