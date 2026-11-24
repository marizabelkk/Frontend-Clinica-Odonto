import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/paciente_model.dart';
import '../../view_models/paciente_view_model.dart';
import 'prontuario/prontuario_view.dart';
import '../../widgets/navegacao_inferior_aluno.dart';
import '../../widgets/cabecalho_pagina_aluno.dart';
import '../atendimentos/meus_atendimentos_view.dart';
import 'cadastrar_paciente_view.dart';
import '../recepcao/widgets/navegacao_inferior_recepcao.dart';

part 'widgets/patient_search_components.dart';

class BuscarPacienteView extends StatefulWidget {
  const BuscarPacienteView({this.allowOpenRecord = true, super.key});

  final bool allowOpenRecord;

  @override
  State<BuscarPacienteView> createState() => _BuscarPacienteViewState();
}

class _BuscarPacienteViewState extends State<BuscarPacienteView> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _sort = 'Relevância';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<PacienteViewModel>().loadPatients();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) context.read<PacienteViewModel>().loadPatients(query: value);
    });
  }

  Future<void> _createPatient() async {
    final created = await Navigator.of(context).push<PacienteModel>(
      MaterialPageRoute<PacienteModel>(
        builder: (_) => CadastrarPacienteView(
          showStudentNavigation: widget.allowOpenRecord,
        ),
      ),
    );
    if (!mounted || created?.pacienteId == null) return;
    await context.read<PacienteViewModel>().loadPatients(
      query: _searchController.text,
    );
    if (!mounted) return;
    if (widget.allowOpenRecord) {
      await _openRecord(created!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paciente cadastrado com sucesso.')),
      );
    }
  }

  Future<void> _openRecord(PacienteModel paciente) async {
    final id = paciente.pacienteId;
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O paciente não possui paciente_id.')),
      );
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => ProntuarioView(pacienteId: id)),
    );
  }

  Future<void> _editPatient(PacienteModel paciente) async {
    final updated = await Navigator.of(context).push<PacienteModel>(
      MaterialPageRoute(
        builder: (_) => CadastrarPacienteView(
          showStudentNavigation: widget.allowOpenRecord,
          paciente: paciente,
        ),
      ),
    );
    if (!mounted || updated == null) return;
    await context.read<PacienteViewModel>().loadPatients(
      query: _searchController.text,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Cadastro atualizado.')));
  }

  Future<void> _deletePatient(PacienteModel paciente) async {
    final id = paciente.pacienteId;
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir paciente'),
        content: Text(
          'Tem certeza que deseja excluir ${paciente.nomeCompleto ?? 'este paciente'}? Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final model = context.read<PacienteViewModel>();
    final deleted = await model.deletePatient(id);
    if (!mounted) return;
    if (deleted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Paciente excluído.')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            model.errorMessage ?? 'Não foi possível excluir o paciente.',
          ),
        ),
      );
    }
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
        SnackBar(
          content: Text(
            index == 2
                ? 'Abra um prontuário para ver os atendimentos.'
                : 'Acesse o perfil pelo menu da página inicial.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final foreground = dark ? const Color(0xFFF3F6FC) : const Color(0xFF102B53);
    final muted = dark ? const Color(0xFFB9C7DD) : const Color(0xFF435D86);
    final surface = dark ? const Color(0xFF0B192C) : Colors.white;
    final border = dark ? const Color(0xFF2A3D59) : const Color(0xFFD9E0EF);

    return Scaffold(
      backgroundColor: EstiloPaginaAluno.background(context),
      body: Theme(
        data: EstiloPaginaAluno.readableTheme(context),
        child: Column(
          children: [
            CabecalhoPaginaAluno(
              title: 'Buscar paciente',
              subtitle:
                  'Encontre um paciente cadastrado por nome,\nCPF ou código do prontuário.',
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: surface,
                  border: Border(
                    top: BorderSide(color: AppTheme.gold, width: 3),
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(26),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!widget.allowOpenRecord)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 10),
                          child: Text(
                            'A recepção pode cadastrar e editar pacientes. A exclusão fica disponível para cadastros sem atendimentos vinculados.',
                          ),
                        ),
                      TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        textInputAction: TextInputAction.search,
                        style: TextStyle(color: foreground, fontSize: 16),
                        decoration: InputDecoration(
                          hintText:
                              'Digite o nome, CPF ou código do prontuário',
                          hintMaxLines: 1,
                          prefixIcon: Icon(
                            Icons.search,
                            color: dark ? AppTheme.gold : AppTheme.navy,
                            size: 27,
                          ),
                          suffixIcon: _searchController.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Limpar busca',
                                  onPressed: () {
                                    _searchController.clear();
                                    _onSearchChanged('');
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.close),
                                ),
                          filled: true,
                          fillColor: dark
                              ? const Color(0xFF111F34)
                              : Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 18,
                            horizontal: 14,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(color: border, width: 1.2),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(
                              color: dark ? AppTheme.gold : AppTheme.navy,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Resultados da busca',
                              style: TextStyle(
                                color: foreground,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          PopupMenuButton<String>(
                            initialValue: _sort,
                            onSelected: (value) =>
                                setState(() => _sort = value),
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 'Relevância',
                                child: Text('Relevância'),
                              ),
                              PopupMenuItem(
                                value: 'Nome A–Z',
                                child: Text('Nome A–Z'),
                              ),
                            ],
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Ordenar',
                                  style: TextStyle(color: muted, fontSize: 12),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.keyboard_arrow_down,
                                  color: dark ? AppTheme.gold : AppTheme.navy,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Consumer<PacienteViewModel>(
                          builder: (context, model, _) {
                            if (model.isLoading) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            if (model.errorMessage != null) {
                              return _SearchMessage(
                                icon: Icons.cloud_off_outlined,
                                title: 'Não foi possível carregar os pacientes',
                                message: model.errorMessage!,
                                foreground: foreground,
                                muted: muted,
                                border: border,
                                action: TextButton.icon(
                                  onPressed: () => model.loadPatients(
                                    query: _searchController.text,
                                  ),
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Tentar novamente'),
                                ),
                              );
                            }
                            final patients = [...model.pacientes];
                            if (_sort == 'Nome A–Z') {
                              patients.sort(
                                (a, b) => (a.nomeCompleto ?? '').compareTo(
                                  b.nomeCompleto ?? '',
                                ),
                              );
                            }
                            if (patients.isEmpty) {
                              return _SearchMessage(
                                icon: Icons.manage_search_rounded,
                                title: 'Nenhum paciente encontrado',
                                message:
                                    'Verifique os dados digitados ou cadastre um novo paciente.',
                                foreground: foreground,
                                muted: muted,
                                border: border,
                              );
                            }
                            return ListView.separated(
                              padding: const EdgeInsets.fromLTRB(0, 2, 0, 12),
                              itemCount: patients.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) => _PatientCard(
                                paciente: patients[index],
                                dark: dark,
                                foreground: foreground,
                                muted: muted,
                                border: border,
                                onTap: widget.allowOpenRecord
                                    ? () => _openRecord(patients[index])
                                    : null,
                                onEdit: () => _editPatient(patients[index]),
                                onDelete: widget.allowOpenRecord
                                    ? null
                                    : () => _deletePatient(patients[index]),
                                isDeleting: model.isDeleting,
                              ),
                            );
                          },
                        ),
                      ),

                      SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                          child: SizedBox(
                            height: 54,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: dark
                                    ? AppTheme.gold
                                    : AppTheme.navy,
                                foregroundColor: dark
                                    ? AppTheme.navy
                                    : Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: _createPatient,
                              icon: const Icon(Icons.add, size: 25),
                              label: const Text(
                                'Cadastrar novo paciente',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
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
      bottomNavigationBar: widget.allowOpenRecord
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
                if (index == 2) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Perfil da recepção')),
                  );
                }
              },
            ),
    );
  }
}
