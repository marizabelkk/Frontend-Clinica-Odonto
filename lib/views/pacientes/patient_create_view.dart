import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/models/paciente_dto.dart';
import '../../data/viewmodels/patient_view_model.dart';
import '../widgets/student_page_header.dart';

class PatientCreateView extends StatefulWidget {
  const PatientCreateView({super.key});

  @override
  State<PatientCreateView> createState() => _PatientCreateViewState();
}

class _PatientCreateViewState extends State<PatientCreateView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cpfController = TextEditingController();
  final _rgController = TextEditingController();
  final _sexController = TextEditingController();
  final _cellphoneController = TextEditingController();
  DateTime? _birthDate;
  bool _didSubmit = false;

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
    if (birthDate == null) {
      setState(() {});
      return;
    }

    final paciente = PacienteDto(
      nomeCompleto: _nameController.text.trim(),
      cpf: _cpfController.text.trim(),
      rg: _rgController.text.trim().isEmpty ? null : _rgController.text.trim(),
      dataNascimento: _dateForApi(birthDate),
      sexo: _sexController.text.trim(),
      celular: _cellphoneController.text.trim(),
    );
    final created = await context.read<PatientViewModel>().createPatient(
      paciente,
    );
    if (!mounted || created == null) return;
    Navigator.of(context).pop(created);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: StudentPageStyle.background(context),
      body: Theme(
        data: StudentPageStyle.readableTheme(context),
        child: Column(children: [
          const StudentPageHeader(
            title: 'Cadastrar novo paciente',
            subtitle: 'Preencha os dados para criar o cadastro e o prontuário.',
          ),
          Expanded(child: SafeArea(
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
              const Text('O cadastro cria também o prontuário do paciente.'),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Nome completo *'),
                validator: _required('Informe o nome completo.'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _cpfController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'CPF *',
                  hintText: 'Somente números',
                ),
                validator: _required('Informe o CPF.'),
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
                    errorText: _birthDate == null && _didSubmit
                        ? 'Informe a data de nascimento.'
                        : null,
                    suffixIcon: const Icon(Icons.calendar_month_outlined),
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
                validator: _required('Informe sexo/gênero.'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _cellphoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Celular *',
                  hintText: 'DDD e número, somente números',
                ),
                validator: _required('Informe o celular.'),
              ),
              const SizedBox(height: 18),
              Consumer<PatientViewModel>(
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
              Consumer<PatientViewModel>(
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
                      : const Text('Cadastrar paciente'),
                ),
              ),
            ],
          ),
        ),
          )),
        ]),
      ),
    );
  }

  FormFieldValidator<String> _required(String message) =>
      (value) => value == null || value.trim().isEmpty ? message : null;

  String _dateForApi(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  String _dateForDisplay(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year.toString().padLeft(4, '0')}';
}
