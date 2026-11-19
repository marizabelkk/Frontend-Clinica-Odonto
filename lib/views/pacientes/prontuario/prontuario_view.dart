import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/paciente_model.dart';
import '../../../models/prontuario_model.dart';
import '../../../models/ficha_semiologia_model.dart';
import '../../../models/usuario_model.dart';
import '../../../view_models/atendimento_view_model.dart';
import '../../../view_models/autenticacao_view_model.dart';
import '../../../view_models/paciente_view_model.dart';
import '../../../view_models/semiologia_view_model.dart';
import '../../odontograma/odontograma_view.dart';
import '../../atendimentos/iniciar_atendimento_view.dart';
import '../../atendimentos/semiologia/formulario_semiologia_view.dart';
import '../../atendimentos/meus_atendimentos_view.dart';
import '../../../widgets/navegacao_inferior_aluno.dart';
import '../../../widgets/cabecalho_pagina_aluno.dart';

class ProntuarioView extends StatefulWidget {
  const ProntuarioView({required this.pacienteId, super.key});

  final int pacienteId;

  @override
  State<ProntuarioView> createState() => _ProntuarioViewState();
}

class _ProntuarioViewState extends State<ProntuarioView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<PacienteViewModel>().loadProntuario(widget.pacienteId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AutenticacaoViewModel>().usuario;
    final perfil = usuario?.perfil;
    final isStudent = perfil == PerfilUsuario.aluno;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final foreground = dark ? AppTheme.darkText : AppTheme.lightText;
    final muted = dark ? const Color(0xFFB9C7DD) : const Color(0xFF52647E);

    return Scaffold(
      backgroundColor: EstiloPaginaAluno.background(context),
      body: Theme(
        data: EstiloPaginaAluno.readableTheme(context),
        child: Column(children: [
          CabecalhoPaginaAluno(
            title: 'Prontuário do Paciente',
            subtitle: 'Informações clínicas e histórico de atendimentos',
            actions: [
              PopupMenuButton<String>(
                tooltip: 'Mais opções',
                iconColor: Colors.white,
                onSelected: (_) => context.read<PacienteViewModel>().loadProntuario(widget.pacienteId),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'refresh', child: Text('Atualizar prontuário')),
                ],
              ),
            ],
          ),
          Expanded(
            child: Consumer<PacienteViewModel>(
              builder: (context, model, _) {
                if (model.isLoading) return const Center(child: CircularProgressIndicator());
                if (model.errorMessage != null) {
                  return Center(child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.cloud_off_outlined, size: 44, color: dark ? AppTheme.gold : AppTheme.navy),
                      const SizedBox(height: 12),
                      Text(model.errorMessage!, textAlign: TextAlign.center, style: TextStyle(color: foreground, fontSize: 15)),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => model.loadProntuario(widget.pacienteId),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tentar novamente'),
                      ),
                    ]),
                  ));
                }

                final prontuario = model.prontuario;
                if (prontuario == null) {
                  return Center(child: Text('Paciente não encontrado.', style: TextStyle(color: foreground)));
                }
                return _RecordContent(
                  prontuario: prontuario,
                  canStartAttendance: isStudent,
                  currentUserId: usuario?.id,
                  canViewOdontograma: perfil == PerfilUsuario.aluno || perfil == PerfilUsuario.professor || perfil == PerfilUsuario.admin,
                  foreground: foreground,
                  muted: muted,
                  dark: dark,
                );
              },
            ),
          ),
        ]),
      ),
      bottomNavigationBar: isStudent
          ? NavegacaoInferiorAluno(
              currentIndex: 1,
              onDestinationSelected: (index) {
                if (index == 0) navegarParaInicioAluno(context);
                if (index == 2) {
                  Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => const MeusAtendimentosView()));
                }
                if (index == 3) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Acesse o perfil pelo menu da página inicial.')),
                  );
                }
              },
            )
          : null,
    );
  }
}

class _RecordContent extends StatefulWidget {
  const _RecordContent({
    required this.prontuario,
    required this.canStartAttendance,
    required this.currentUserId,
    required this.canViewOdontograma,
    required this.foreground,
    required this.muted,
    required this.dark,
  });

  final ProntuarioModel prontuario;
  final bool canStartAttendance;
  final int? currentUserId;
  final bool canViewOdontograma;
  final Color foreground;
  final Color muted;
  final bool dark;

  @override
  State<_RecordContent> createState() => _RecordContentState();
}

class _RecordContentState extends State<_RecordContent> {
  int _tab = 0;
  bool _showMore = false;

  PacienteModel get paciente => widget.prontuario.paciente;

  StatusFicha? _statusOf(Map<String, dynamic> item) {
    final raw = item['status']?.toString();
    for (final status in StatusFicha.values) {
      if (status.apiValue == raw) return status;
    }
    return null;
  }

  int? _intField(Map<String, dynamic> item, String key) =>
      item[key] is int ? item[key] as int : null;

  Future<void> _openFicha(Map<String, dynamic> item, {required bool edit}) async {
    final fichaId = _intField(item, 'ficha_id');
    final atendimentoId = _intField(item, 'id');
    final status = _statusOf(item);
    final editable = status == StatusFicha.rascunho ||
        status == StatusFicha.correcaoSolicitada;
    if (fichaId == null || atendimentoId == null || (edit && !editable)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esta ficha não está disponível para esta ação.')),
      );
      return;
    }
    final viewModel = context.read<SemiologiaViewModel>();
    final ficha = await viewModel.loadFicha(fichaId);
    if (!mounted) return;
    if (ficha == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(viewModel.errorMessage ?? 'Não foi possível abrir a ficha.')),
      );
      return;
    }
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => FormularioSemiologiaView(
          paciente: paciente,
          atendimentoId: atendimentoId,
          ficha: ficha,
          readOnly: !edit,
          teacherComment: item['observacao_correcao']?.toString(),
        ),
      ),
    );
    if (mounted && changed == true) {
      await context.read<PacienteViewModel>().loadProntuario(widget.prontuario.pacienteId);
      await context.read<AtendimentoViewModel>().loadMyAttendances();
    }
  }

  Future<bool> _confirmDelete(String description) async =>
      await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.warning_amber_rounded, color: AppTheme.gold),
          title: const Text('Confirmar exclusão'),
          content: Text('Tem certeza que você quer excluir? $description'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD92332),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Excluir'),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _deleteEntry(Map<String, dynamic> item) async {
    final status = _statusOf(item);
    final fichaId = _intField(item, 'ficha_id');
    final attendanceId = _intField(item, 'id');
    if (status == StatusFicha.rascunho && fichaId != null) {
      if (!await _confirmDelete('O rascunho será removido permanentemente.')) return;
      final deleted = await context
          .read<SemiologiaViewModel>()
          .deleteDraft(fichaId: fichaId, status: status!);
      if (!mounted) return;
      if (!deleted) {
        final error = context.read<SemiologiaViewModel>().errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error ?? 'Não foi possível excluir o rascunho.')),
        );
        return;
      }
      // After deleting the draft, also delete its attendance to prevent a stale row.
      if (attendanceId != null) {
        final error = await context
            .read<AtendimentoViewModel>()
            .deleteAttendance(attendanceId);
        if (!mounted) return;
        if (error != null) {
          await context
              .read<PacienteViewModel>()
              .loadProntuario(widget.prontuario.pacienteId);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Rascunho removido, mas nao foi possivel remover o atendimento associado. $error',
              ),
            ),
          );
          return;
        }
      }
    } else if (status == null && attendanceId != null) {
      if (!await _confirmDelete('O atendimento será removido permanentemente.')) return;
      final error = await context
          .read<AtendimentoViewModel>()
          .deleteAttendance(attendanceId);
      if (!mounted) return;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
        return;
      }
    } else {
      return;
    }
    await context.read<PacienteViewModel>().loadProntuario(widget.prontuario.pacienteId);
  }

  Widget _attendanceRow(Map<String, dynamic> item) => _AttendanceRow(
        item: item,
        dark: widget.dark,
        foreground: widget.foreground,
        muted: widget.muted,
        canManage: widget.canStartAttendance,
        onView: item['ficha_id'] is int ? () => _openFicha(item, edit: false) : null,
        onEdit: () => _openFicha(item, edit: true),
        onDelete: () => _deleteEntry(item),
      );

  @override
  Widget build(BuildContext context) {
    final line = widget.dark ? const Color(0xFF263A56) : const Color(0xFFE3E9F3);
    final surface = widget.dark ? AppTheme.darkSurface : Colors.white;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
        child: _PatientProfileCard(
          paciente: paciente,
          prontuarioId: widget.prontuario.id,
          expanded: _showMore,
          onToggle: () => setState(() => _showMore = !_showMore),
          foreground: widget.foreground,
          muted: widget.muted,
          dark: widget.dark,
        ),
      ),
      _RecordTabs(selected: _tab, dark: widget.dark, onSelected: (index) => setState(() => _tab = index)),
      Expanded(
        child: Container(
          color: EstiloPaginaAluno.background(context),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
            child: Center(child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: switch (_tab) {
                0 => _summary(context, surface, line),
                1 => _attendanceList(context, surface, line, initialOnly: true),
                2 => _attendanceList(context, surface, line),
                3 => _odontogramPanel(context, surface, line),
                4 => _emptySection(surface, line, Icons.biotech_outlined, 'Exames', 'Os exames complementares aparecerão aqui quando forem vinculados ao prontuário.'),
                _ => _emptySection(surface, line, Icons.folder_open_outlined, 'Documentos', 'Os documentos vinculados ao prontuário aparecerão aqui.'),
              },
            )),
          ),
        ),
      ),
    ]);
  }

  Widget _summary(BuildContext context, Color surface, Color line) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _SectionCard(
        surface: surface,
        line: line,
        title: 'Resumo clínico',
        trailing: TextButton(onPressed: () => setState(() => _tab = 1), child: const Text('Ver tudo')),
        child: _clinicalSummary(),
      ),
      const SizedBox(height: 10),
      _SectionCard(
        surface: surface,
        line: line,
        title: 'Avaliação inicial (Semiologia)',
        trailing: TextButton(onPressed: () => setState(() => _tab = 1), child: const Text('Ver avaliações')),
        child: _recentAttendance(context, initialOnly: true),
      ),
      const SizedBox(height: 10),
      _SectionCard(
        surface: surface,
        line: line,
        title: 'Histórico de atendimentos',
        trailing: TextButton(onPressed: () => setState(() => _tab = 2), child: const Text('Ver todos')),
        child: Column(children: [
          _recentAttendance(context),
          if (widget.canStartAttendance) ...[
            const SizedBox(height: 10),
            SizedBox(width: double.infinity, child: OutlinedButton.icon(
              onPressed: _startAttendance,
              icon: const Icon(Icons.add, size: 22),
              label: const Text('Novo atendimento', style: TextStyle(fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48), side: BorderSide(color: widget.dark ? AppTheme.gold : AppTheme.navy, width: 1.4)),
            )),
          ],
        ]),
      ),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: widget.dark ? const Color(0xFF12233A) : const Color(0xFFEEF3FC), borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          Icon(Icons.lock_outline, color: widget.dark ? AppTheme.gold : AppTheme.navy, size: 24),
          const SizedBox(width: 10),
          Expanded(child: Text('Este prontuário contém informações confidenciais. Acesso restrito a alunos e professores autorizados.', style: TextStyle(color: widget.foreground, fontSize: 13))),
        ]),
      ),
    ],
  );

  Widget _clinicalSummary() {
    final categories = [
      ('Condições médicas', widget.prontuario.condicoesMedicas, const Color(0xFF174A9A)),
      ('Alergias', widget.prontuario.alergias, const Color(0xFFD62935)),
      ('Medicamentos em uso', widget.prontuario.medicamentos, const Color(0xFF159457)),
    ];
    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth > 750 ? 3 : 2;
      return GridView.count(
        crossAxisCount: columns,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: columns == 2 ? 1.15 : 1.65,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        children: categories.map((category) => Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: widget.dark ? const Color(0xFF0D1A2C) : const Color(0xFFFAFBFE), border: Border.all(color: widget.dark ? const Color(0xFF263A56) : const Color(0xFFE4EAF4)), borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(category.$1, style: TextStyle(color: category.$3, fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 5),
            Expanded(child: category.$2.isEmpty
                ? Text('Nenhuma informação cadastrada', style: TextStyle(color: widget.muted, fontSize: 12))
                : ListView(shrinkWrap: true, children: category.$2.take(2).map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Icon(Icons.circle, color: category.$3, size: 7),
                      const SizedBox(width: 6),
                      Expanded(child: Text(_itemLabel(item), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: widget.foreground, fontSize: 12))),
                    ]),
                  )).toList())),
          ]),
        )).toList(),
      );
    });
  }

  Widget _recentAttendance(BuildContext context, {bool initialOnly = false}) {
    var entries = widget.prontuario.atendimentos;
    if (initialOnly) {
      final filtered = entries.where((item) => _itemLabel(item).toLowerCase().contains('semiologia')).toList();
      entries = filtered;
    }
    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          Icon(Icons.info_outline, color: widget.dark ? AppTheme.gold : AppTheme.navy),
          const SizedBox(width: 8),
          Expanded(child: Text(initialOnly ? 'Nenhuma avaliação de Semiologia foi registrada para este prontuário.' : 'Nenhum atendimento foi retornado para este prontuário.', style: TextStyle(color: widget.muted, fontSize: 13))),
        ]),
      );
    }
    final shown = initialOnly ? entries.take(1) : entries.take(4);
    return Column(children: [
      for (final item in shown) _attendanceRow(item),
    ]);
  }

  Widget _attendanceList(BuildContext context, Color surface, Color line, {bool initialOnly = false}) {
    var entries = widget.prontuario.atendimentos;
    if (initialOnly) {
      final filtered = entries.where((item) => _itemLabel(item).toLowerCase().contains('semiologia')).toList();
      entries = filtered;
    }
    return _SectionCard(
      surface: surface,
      line: line,
      title: initialOnly ? 'Avaliações de Semiologia' : 'Histórico de atendimentos',
      child: Column(children: [
        if (entries.isEmpty)
          _emptySection(
            surface,
            line,
            Icons.assignment_outlined,
            initialOnly ? 'Nenhuma avaliação de Semiologia' : 'Nenhum atendimento',
            initialOnly
                ? 'As avaliações iniciais de Semiologia deste paciente serão exibidas aqui.'
                : 'Os atendimentos registrados serão exibidos nesta lista.',
          ),
        for (final item in entries) _attendanceRow(item),
        if (widget.canStartAttendance) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _startAttendance,
              icon: const Icon(Icons.add),
              label: Text(initialOnly ? 'Nova avaliação inicial' : 'Novo atendimento'),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _odontogramPanel(BuildContext context, Color surface, Color line) => _SectionCard(
    surface: surface,
    line: line,
    title: 'Odontogramas',
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Consulte o mapa odontológico e os registros vinculados ao prontuário.', style: TextStyle(color: widget.muted)),
      const SizedBox(height: 12),
      FilledButton.icon(
        onPressed: widget.canViewOdontograma && paciente.prontuarioId != null
            ? () => Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => OdontogramaView(
                prontuarioId: paciente.prontuarioId!,
                pacienteNome: paciente.nomeCompleto,
                canManageExisting: widget.canStartAttendance,
                currentUserId: widget.currentUserId,
                showStudentNavigation: widget.canStartAttendance,
              )))
            : null,
        icon: const Icon(Icons.grid_view_rounded),
        label: const Text('Abrir odontograma'),
      ),
      if (paciente.prontuarioId == null)
        Padding(padding: const EdgeInsets.only(top: 8), child: Text('O prontuario_id não foi retornado pela API.', style: TextStyle(color: widget.muted))),
    ]),
  );

  Widget _emptySection(Color surface, Color line, IconData icon, String title, String message) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: surface, border: Border.all(color: line), borderRadius: BorderRadius.circular(15)),
    child: Column(children: [
      Icon(icon, size: 35, color: widget.dark ? AppTheme.gold : AppTheme.navy),
      const SizedBox(height: 7),
      Text(title, style: TextStyle(color: widget.foreground, fontSize: 16, fontWeight: FontWeight.w700)),
      const SizedBox(height: 4),
      Text(message, textAlign: TextAlign.center, style: TextStyle(color: widget.muted, fontSize: 13)),
    ]),
  );

  Future<void> _startAttendance() async {
    final id = paciente.prontuarioId;
    if (!widget.canStartAttendance || id == null) return;
    await Navigator.of(context).push<void>(MaterialPageRoute<void>(
      builder: (_) => IniciarAtendimentoView(paciente: paciente, prontuarioId: id),
    ));
    if (mounted) {
      await context.read<PacienteViewModel>().loadProntuario(widget.prontuario.pacienteId);
    }
  }
}

class _PatientProfileCard extends StatelessWidget {
  const _PatientProfileCard({required this.paciente, required this.prontuarioId, required this.expanded, required this.onToggle, required this.foreground, required this.muted, required this.dark});
  final PacienteModel paciente;
  final int prontuarioId;
  final bool expanded;
  final VoidCallback onToggle;
  final Color foreground;
  final Color muted;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final border = dark ? const Color(0xFF263A56) : const Color(0xFFE6EBF4);
    final initials = _initials(paciente.nomeCompleto);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: dark ? AppTheme.darkSurface : Colors.white, border: Border.all(color: border), borderRadius: BorderRadius.circular(18), boxShadow: dark ? null : [BoxShadow(color: const Color(0xFF102B53).withValues(alpha: .05), blurRadius: 12, offset: const Offset(0, 4))]),
      child: Column(children: [
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          CircleAvatar(radius: 34, backgroundColor: dark ? const Color(0xFF0A356D) : const Color(0xFFE4EAF8), foregroundColor: dark ? const Color(0xFFE3ECFC) : AppTheme.navy, child: Text(initials, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(paciente.nomeCompleto ?? 'Paciente', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: foreground, fontSize: 19, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('CPF: ${_maskCpf(paciente.cpf)}   •   ${_formatBirth(paciente.dataNascimento)}   •   ${paciente.sexo ?? 'Sexo não informado'}', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: muted, fontSize: 12)),
            if (paciente.celular != null || paciente.rg != null) ...[
              const SizedBox(height: 5),
              Row(children: [
                if (paciente.celular != null) ...[Icon(Icons.call_outlined, size: 16, color: dark ? AppTheme.gold : AppTheme.navy), const SizedBox(width: 5), Flexible(child: Text(paciente.celular!, style: TextStyle(color: muted, fontSize: 12)))],
                if (paciente.rg != null) ...[const SizedBox(width: 12), Icon(Icons.badge_outlined, size: 16, color: dark ? AppTheme.gold : AppTheme.navy), const SizedBox(width: 4), Flexible(child: Text('RG: ${paciente.rg}', style: TextStyle(color: muted, fontSize: 12)))],
              ]),
            ],
          ])),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: dark ? const Color(0xFF40350E) : const Color(0xFFFFF5D8), border: Border.all(color: AppTheme.gold), borderRadius: BorderRadius.circular(18)), child: Text('Código: ${prontuarioId.toString().padLeft(6, '0')}', style: TextStyle(color: foreground, fontSize: 12, fontWeight: FontWeight.w600))),
          const Spacer(),
          TextButton.icon(onPressed: onToggle, icon: Icon(expanded ? Icons.expand_less : Icons.expand_more, size: 19), label: Text(expanded ? 'Ver menos' : 'Ver mais'), style: TextButton.styleFrom(foregroundColor: dark ? AppTheme.gold : AppTheme.navy)),
        ]),
        if (expanded) ...[
          Divider(color: border),
          _DetailLine(label: 'Nascimento', value: _formatBirth(paciente.dataNascimento), foreground: foreground, muted: muted),
          _DetailLine(label: 'Sexo/gênero', value: paciente.sexo ?? 'Não informado', foreground: foreground, muted: muted),
          _DetailLine(label: 'Celular', value: paciente.celular ?? 'Não informado', foreground: foreground, muted: muted),
          _DetailLine(label: 'RG', value: paciente.rg ?? 'Não informado', foreground: foreground, muted: muted),
        ],
      ]),
    );
  }
}

class _RecordTabs extends StatelessWidget {
  const _RecordTabs({required this.selected, required this.dark, required this.onSelected});
  final int selected;
  final bool dark;
  final ValueChanged<int> onSelected;

  static const tabs = [
    (Icons.view_agenda_outlined, 'Resumo'),
    (Icons.assignment_outlined, 'Avaliação inicial'),
    (Icons.content_paste_search, 'Atendimentos'),
    (Icons.medical_services_outlined, 'Odontogramas'),
    (Icons.biotech_outlined, 'Exames'),
    (Icons.description_outlined, 'Documentos'),
  ];

  @override
  Widget build(BuildContext context) => Container(
    color: dark ? const Color(0xFF0C1A2D) : Colors.white,
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        for (var i = 0; i < tabs.length; i++)
          InkWell(
            onTap: () => onSelected(i),
            child: Container(
              constraints: const BoxConstraints(minWidth: 94),
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 7),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: selected == i ? (dark ? AppTheme.gold : AppTheme.navy) : Colors.transparent, width: 3))),
              child: Column(children: [
                Icon(tabs[i].$1, color: selected == i ? (dark ? AppTheme.gold : AppTheme.navy) : (dark ? const Color(0xFF9DAFCC) : const Color(0xFF516887)), size: 23),
                const SizedBox(height: 3),
                Text(tabs[i].$2, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: selected == i ? (dark ? AppTheme.gold : AppTheme.navy) : (dark ? const Color(0xFF9DAFCC) : const Color(0xFF516887)), fontSize: 10, fontWeight: selected == i ? FontWeight.w700 : FontWeight.normal)),
              ]),
            ),
          ),
      ]),
    ),
  );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.surface, required this.line, required this.title, required this.child, this.trailing});
  final Color surface;
  final Color line;
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: surface, border: Border.all(color: line), borderRadius: BorderRadius.circular(16), boxShadow: Theme.of(context).brightness == Brightness.dark ? null : [BoxShadow(color: const Color(0xFF102B53).withValues(alpha: .035), blurRadius: 10, offset: const Offset(0, 3))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [Expanded(child: Text(title, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 17, fontWeight: FontWeight.w800))), if (trailing != null) trailing!]),
      const SizedBox(height: 7),
      child,
    ]),
  );
}

class _AttendanceRow extends StatelessWidget {
  const _AttendanceRow({required this.item, required this.dark, required this.foreground, required this.muted, required this.canManage, this.onView, required this.onEdit, required this.onDelete});
  final Map<String, dynamic> item;
  final bool dark;
  final Color foreground;
  final Color muted;
  final bool canManage;
  final VoidCallback? onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final title = _firstValue(item, ['especialidade_nome', 'especialidade', 'tipo', 'titulo', 'nome']) ?? 'Atendimento';
    final detail = _firstValue(item, ['descricao', 'queixa_principal', 'procedimento', 'observacao']) ?? 'Avaliação clínica';
    final date = _firstValue(item, ['data_atendimento', 'criado_em', 'data', 'created_at']) ?? 'Data não informada';
    final statusRaw = _firstValue(item, ['status', 'situacao']) ?? 'Registrado';
    final status = _statusLabel(statusRaw);
    final color = _statusColor(statusRaw);
    final normalizedStatus = statusRaw.toUpperCase();
    final isDraft = normalizedStatus.contains('RASCUN');
    final isCorrection = normalizedStatus.contains('CORRE');
    final hasFicha = item['ficha_id'] is int;
    final canEdit = hasFicha && (isDraft || isCorrection);
    final correctionNote = item['observacao_correcao']?.toString();
    final student = item['aluno_responsavel'];
    final studentName = student is Map ? student['nome']?.toString() : item['aluno']?.toString();
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(color: dark ? const Color(0xFF0D1B2E) : const Color(0xFFFCFDFF), border: Border.all(color: dark ? const Color(0xFF263A56) : const Color(0xFFE5EAF3)), borderRadius: BorderRadius.circular(13)),
      child: Row(children: [
        CircleAvatar(radius: 23, backgroundColor: dark ? const Color(0xFF172A45) : const Color(0xFFEDF2FB), foregroundColor: dark ? AppTheme.gold : AppTheme.navy, child: const Icon(Icons.medical_services_outlined, size: 23)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: foreground, fontSize: 14, fontWeight: FontWeight.w700)),
          Text(detail, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: muted, fontSize: 12)),
          Text('$date${studentName == null ? '' : '  •  Aluno: $studentName'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: muted, fontSize: 11)),
          if (correctionNote?.trim().isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                'Observação do professor: $correctionNote',
                style: const TextStyle(color: Color(0xFFD92332), fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
        ])),
        const SizedBox(width: 6),
        SizedBox(
          width: 128,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 128),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: dark ? .18 : .12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _statusLabel(statusRaw),
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              if (canManage) ...[
                if (hasFicha)
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      tooltip: 'Visualizar ficha',
                      onPressed: onView,
                      icon: Icon(Icons.visibility_outlined, color: dark ? AppTheme.gold : AppTheme.navy, size: 19),
                      constraints: const BoxConstraints.tightFor(width: 38, height: 36),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                if (canEdit)
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      tooltip: 'Editar ficha',
                      onPressed: onEdit,
                      icon: Icon(Icons.edit_outlined, color: dark ? AppTheme.gold : AppTheme.navy, size: 19),
                      constraints: const BoxConstraints.tightFor(width: 38, height: 36),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                if (isDraft || !hasFicha)
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      tooltip: isDraft ? 'Excluir rascunho' : 'Excluir atendimento',
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline, color: Color(0xFFD92332), size: 19),
                      constraints: const BoxConstraints.tightFor(width: 38, height: 36),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ]),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value, required this.foreground, required this.muted});
  final String label;
  final String value;
  final Color foreground;
  final Color muted;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(children: [SizedBox(width: 130, child: Text(label, style: TextStyle(color: muted, fontWeight: FontWeight.w600))), Expanded(child: Text(value, style: TextStyle(color: foreground)))]));
}

String _initials(String? name) {
  final parts = (name ?? '').trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  return parts.take(2).map((part) => part[0].toUpperCase()).join();
}

String _maskCpf(String? cpf) {
  if (cpf == null || cpf.isEmpty) return 'Não informado';
  final digits = cpf.replaceAll(RegExp(r'\D'), '');
  if (digits.length != 11) return cpf;
  return '***.***.***-${digits.substring(9)}';
}

String _formatBirth(String? value) {
  if (value == null || value.isEmpty) return 'Nascimento não informado';
  final raw = value.trim();
  // Datas simples da API podem vir em MM/DD/YYYY; datas ISO permanecem intactas.
  final americanDate = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(raw);
  final date = americanDate == null
      ? DateTime.tryParse(raw)
      : DateTime(
          int.parse(americanDate.group(3)!),
          int.parse(americanDate.group(1)!),
          int.parse(americanDate.group(2)!),
        );
  if (date == null) return value;
  final age = DateTime.now().year - date.year - ((DateTime.now().month < date.month || (DateTime.now().month == date.month && DateTime.now().day < date.day)) ? 1 : 0);
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ($age anos)';
}

String _itemLabel(Map<String, dynamic> item) {
  final known = _firstValue(item, ['especialidade_nome', 'nome', 'descricao', 'condicao', 'medicamento', 'alergia', 'principio_ativo', 'nome_comercial']);
  if (known != null) return known;
  for (final entry in item.entries) {
    if (['id', 'paciente_id', 'prontuario_id'].contains(entry.key)) continue;
    if (entry.value is String && (entry.value as String).trim().isNotEmpty) {
      return entry.value as String;
    }
  }
  return 'Informação registrada';
}

String? _firstValue(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value is String && value.trim().isNotEmpty) return value;
    if (value is Map && value['nome'] is String) return value['nome'] as String;
  }
  return null;
}

String _statusLabel(String status) {
  final normalized = status.toUpperCase();
  if (normalized.contains('CORRE')) return 'Correção solicitada';
  if (normalized.contains('AGUARD') || normalized.contains('PEND')) return 'Aguardando aprovação';
  if (normalized.contains('APROV')) return 'Aprovado';
  if (normalized.contains('RASCUN')) return 'Rascunho';
  return status;
}

Color _statusColor(String status) {
  final normalized = status.toUpperCase();
  if (normalized.contains('RASCUN')) return const Color(0xFF3973C9);
  if (normalized.contains('CORRE')) return const Color(0xFFD92332);
  if (normalized.contains('AGUARD') || normalized.contains('PEND')) return const Color(0xFFDB9700);
  if (normalized.contains('APROV')) return const Color(0xFF16813A);
  return const Color(0xFFE59A00);
}
