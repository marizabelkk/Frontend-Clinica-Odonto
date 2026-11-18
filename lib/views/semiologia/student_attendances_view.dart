import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/atendimento_dto.dart';
import '../../data/models/ficha_semiologia_dto.dart';
import '../../data/viewmodels/atendimento_view_model.dart';
import '../../data/viewmodels/semiologia_view_model.dart';
import '../pacientes/patient_search_view.dart';
import '../prontuario/prontuario_view.dart';
import '../widgets/student_footer_navigation.dart';
import '../widgets/student_page_header.dart';
import 'semiologia_form_view.dart';

class StudentAttendancesView extends StatefulWidget {
  const StudentAttendancesView({super.key});

  @override
  State<StudentAttendancesView> createState() => _StudentAttendancesViewState();
}

class _StudentAttendancesViewState extends State<StudentAttendancesView> {
  final _searchController = TextEditingController();
  StatusFicha? _filter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AtendimentoViewModel>().loadMyAttendances();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final foreground = dark ? AppTheme.darkText : AppTheme.lightText;
    final muted = dark ? const Color(0xFFB9C7DD) : const Color(0xFF52647E);
    final border = dark ? const Color(0xFF263A56) : const Color(0xFFE3E8F0);
    final surface = dark ? AppTheme.darkSurface : Colors.white;

    return Scaffold(
      backgroundColor: StudentPageStyle.background(context),
      body: Theme(
        data: StudentPageStyle.readableTheme(context),
        child: Column(children: [
          const StudentPageHeader(
            title: 'Meus atendimentos',
            subtitle: 'Acompanhe e gerencie todos os seus atendimentos clínicos.',
          ),
          Expanded(child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                style: TextStyle(color: foreground),
                decoration: InputDecoration(
                  hintText: 'Buscar por paciente, tipo de ficha ou data',
                  prefixIcon: Icon(Icons.search, color: dark ? AppTheme.gold : AppTheme.navy),
                  suffixIcon: IconButton(
                    tooltip: 'Atualizar atendimentos',
                    onPressed: () => context.read<AtendimentoViewModel>().loadMyAttendances(),
                    icon: Icon(Icons.refresh_rounded, color: dark ? AppTheme.gold : AppTheme.navy),
                  ),
                  filled: true,
                  fillColor: surface,
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: dark ? AppTheme.gold : AppTheme.navy, width: 1.4)),
                ),
              ),
              const SizedBox(height: 12),
              _filters(context, dark, foreground),
              const SizedBox(height: 8),
              Expanded(child: Consumer<AtendimentoViewModel>(
                builder: (context, model, _) {
                  if (model.isLoadingMine && model.myAttendances.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (model.myAttendancesError != null && model.myAttendances.isEmpty) {
                    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.cloud_off_outlined, size: 42, color: dark ? AppTheme.gold : AppTheme.navy),
                      const SizedBox(height: 10),
                      Text(model.myAttendancesError!, textAlign: TextAlign.center, style: TextStyle(color: foreground)),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(onPressed: model.loadMyAttendances, icon: const Icon(Icons.refresh), label: const Text('Tentar novamente')),
                    ]));
                  }

                  final query = _searchController.text.trim().toLowerCase();
                  final items = model.myAttendances.where((item) {
                    if (_filter != null && item.status != _filter) return false;
                    if (query.isEmpty) return true;
                    final patient = item.paciente?.nomeCompleto?.toLowerCase() ?? '';
                    final cpf = item.paciente?.cpf?.toLowerCase() ?? '';
                    final date = _formatDate(item.atendimento.iniciadoEm).toLowerCase();
                    final prontuario = item.atendimento.prontuarioId?.toString() ?? '';
                    return patient.contains(query) ||
                        cpf.contains(query) ||
                        (query.length >= 4 && 'semiologia avaliação inicial'.contains(query)) ||
                        date.contains(query) ||
                        prontuario.contains(query) ||
                        item.atendimento.id.toString() == query;
                  }).toList();

                  if (items.isEmpty) {
                    return Center(child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.assignment_outlined, size: 42, color: dark ? AppTheme.gold : AppTheme.navy),
                        const SizedBox(height: 8),
                        Text('Nenhum atendimento encontrado', style: TextStyle(color: foreground, fontSize: 16, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text('Tente outro filtro ou inicie um novo atendimento.', textAlign: TextAlign.center, style: TextStyle(color: muted)),
                      ]),
                    ));
                  }

                  return RefreshIndicator(
                    onRefresh: model.loadMyAttendances,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 8, top: 2),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) => _AttendanceCard(
                        item: items[index],
                        dark: dark,
                        foreground: foreground,
                        muted: muted,
                        border: border,
                        onOpen: () => _openPatient(items[index]),
                        onEdit: () => _editFicha(items[index]),
                        onDelete: () => items[index].status == StatusFicha.rascunho
                            ? _deleteDraft(items[index])
                            : _deleteAttendance(items[index]),
                      ),
                    ),
                  );
                },
              )),
              const SizedBox(height: 8),
              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dark ? AppTheme.gold : AppTheme.navy,
                    foregroundColor: dark ? AppTheme.navy : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => const PatientSearchView())),
                  icon: const Icon(Icons.add, size: 25),
                  label: const Text('Novo atendimento', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 4),
            ]),
          )),
        ]),
      ),
      bottomNavigationBar: StudentFooterNavigation(
        currentIndex: 2,
        onDestinationSelected: (index) {
          if (index == 0) navigateToStudentHome(context);
          if (index == 1) Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => const PatientSearchView()));
          if (index == 3) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Acesse o perfil pelo menu da página inicial.')));
        },
      ),
    );
  }

  Widget _filters(BuildContext context, bool dark, Color foreground) {
    final model = context.watch<AtendimentoViewModel>();
    final filters = <(StatusFicha?, String, int)>[
      (null, 'Todos', model.myAttendances.length),
      (StatusFicha.rascunho, 'Rascunhos', model.countForStatus(StatusFicha.rascunho)),
      (StatusFicha.aguardandoAprovacao, 'Aguardando aprovação', model.countForStatus(StatusFicha.aguardandoAprovacao)),
      (StatusFicha.correcaoSolicitada, 'Correção solicitada', model.countForStatus(StatusFicha.correcaoSolicitada)),
      (StatusFicha.aprovada, 'Aprovados', model.countForStatus(StatusFicha.aprovada)),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        for (final item in filters) ...[
          if (item != filters.first) const SizedBox(width: 7),
          ChoiceChip(
            selected: _filter == item.$1,
            onSelected: (_) => setState(() => _filter = item.$1),
            showCheckmark: false,
            label: Text('${item.$2}  ${item.$3}', style: TextStyle(color: _filter == item.$1 ? (dark ? AppTheme.navy : Colors.white) : foreground, fontWeight: FontWeight.w600, fontSize: 12)),
            selectedColor: dark ? AppTheme.gold : AppTheme.navy,
            backgroundColor: dark ? const Color(0xFF14243A) : const Color(0xFFF1F4F8),
            side: BorderSide(color: dark ? const Color(0xFF2E415C) : const Color(0xFFE4E8EE)),
          ),
        ],
      ]),
    );
  }

  Future<void> _openPatient(MeuAtendimentoDto item) async {
    final patientId = item.paciente?.pacienteId;
    if (patientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível localizar o paciente associado a este prontuário.')));
      return;
    }
    await Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => ProntuarioView(pacienteId: patientId)));
    if (mounted) context.read<AtendimentoViewModel>().loadMyAttendances();
  }

  Future<void> _editFicha(MeuAtendimentoDto item) async {
    final fichaId = item.atendimento.fichaId;
    if (fichaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A API ainda não informa o ID da ficha deste atendimento; a edição precisa desse dado.')));
      return;
    }
    final patient = item.paciente;
    if (patient == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível localizar o paciente desta ficha.')));
      return;
    }
    final model = context.read<SemiologiaViewModel>();
    final ficha = await model.loadFicha(fichaId);
    if (!mounted) return;
    if (ficha == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(model.errorMessage ?? 'Não foi possível abrir a ficha.')));
      return;
    }
    final changed = await Navigator.of(context).push<bool>(MaterialPageRoute<bool>(
      builder: (_) => SemiologiaFormView(
        paciente: patient,
        atendimentoId: item.atendimento.id,
        ficha: ficha,
        teacherComment: item.atendimento.observacaoCorrecao,
      ),
    ));
    if (mounted && changed == true) context.read<AtendimentoViewModel>().loadMyAttendances();
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

  Future<void> _deleteDraft(MeuAtendimentoDto item) async {
    final fichaId = item.atendimento.fichaId;
    final status = item.status;
    if (fichaId == null || status != StatusFicha.rascunho) return;
    if (!await _confirmDelete('O rascunho será removido permanentemente.')) return;
    final deleted = await context
        .read<SemiologiaViewModel>()
        .deleteDraft(fichaId: fichaId, status: status!);
    if (!mounted) return;
    if (deleted) {
      await context.read<AtendimentoViewModel>().loadMyAttendances();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<SemiologiaViewModel>().errorMessage ??
                'Não foi possível excluir o rascunho.',
          ),
        ),
      );
    }
  }

  Future<void> _deleteAttendance(MeuAtendimentoDto item) async {
    if (item.status != null) return;
    if (!await _confirmDelete('O atendimento será removido permanentemente.')) return;
    final error = await context
        .read<AtendimentoViewModel>()
        .deleteAttendance(item.atendimento.id);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }
}

class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard({required this.item, required this.dark, required this.foreground, required this.muted, required this.border, required this.onOpen, required this.onEdit, required this.onDelete});
  final MeuAtendimentoDto item;
  final bool dark;
  final Color foreground;
  final Color muted;
  final Color border;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final name = item.paciente?.nomeCompleto ?? 'Atendimento #${item.atendimento.id}';
    final initials = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).take(2).map((part) => part[0].toUpperCase()).join();
    final status = item.status;
    final editable = status == StatusFicha.rascunho || status == StatusFicha.correcaoSolicitada;
    final statusColor = dark && status == StatusFicha.rascunho
        ? AppTheme.gold
        : _statusColor(status);
    final date = _formatDate(item.atendimento.iniciadoEm);
    return Material(
      color: dark ? const Color(0xFF101E32) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(border: Border.all(color: border), borderRadius: BorderRadius.circular(16), boxShadow: dark ? null : [BoxShadow(color: const Color(0xFF102B53).withValues(alpha: .04), blurRadius: 10, offset: const Offset(0, 3))]),
          child: Column(children: [
            Row(children: [
              CircleAvatar(radius: 25, backgroundColor: dark ? const Color(0xFF1C3558) : const Color(0xFFE6ECF8), foregroundColor: dark ? const Color(0xFFE1EBFC) : AppTheme.navy, child: Text(initials.isEmpty ? '?' : initials, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17))),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: foreground, fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('Semiologia (Avaliação inicial)', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: foreground, fontSize: 12)),
              ])),
              const SizedBox(width: 6),
              ConstrainedBox(constraints: const BoxConstraints(maxWidth: 124), child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: statusColor.withValues(alpha: dark ? .18 : .12), borderRadius: BorderRadius.circular(16)), child: Text(_statusLabel(status), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w700)))),
            ]),
            const SizedBox(height: 7),
            Row(children: [
              Expanded(child: Wrap(spacing: 10, runSpacing: 4, children: [
                _Metadata(icon: Icons.calendar_today_outlined, text: date, dark: dark, muted: muted),
                _Metadata(icon: Icons.description_outlined, text: 'Prontuário: ${item.atendimento.prontuarioId?.toString().padLeft(6, '0') ?? '—'}', dark: dark, muted: muted),
              ])),
              if (editable)
                IconButton(tooltip: 'Editar ficha', onPressed: onEdit, icon: Icon(Icons.edit_outlined, color: dark ? AppTheme.gold : AppTheme.navy, size: 20), visualDensity: VisualDensity.compact),
              if (status == StatusFicha.rascunho || status == null)
                IconButton(
                  tooltip: status == StatusFicha.rascunho
                      ? 'Excluir rascunho'
                      : 'Excluir atendimento',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, color: Color(0xFFD92332), size: 20),
                  visualDensity: VisualDensity.compact,
                )
              else if (!editable)
                Icon(Icons.chevron_right, color: dark ? AppTheme.gold : AppTheme.navy, size: 24),
            ]),
            if (item.atendimento.observacaoCorrecao?.trim().isNotEmpty == true)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 9),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: dark ? const Color(0xFF351B25) : const Color(0xFFFFF1F0),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFD92332).withValues(alpha: .28)),
                ),
                child: Text(
                  'Observação do professor: ${item.atendimento.observacaoCorrecao}',
                  style: const TextStyle(color: Color(0xFFD92332), fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

class _Metadata extends StatelessWidget {
  const _Metadata({required this.icon, required this.text, required this.dark, required this.muted});
  final IconData icon;
  final String text;
  final bool dark;
  final Color muted;
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 14, color: dark ? AppTheme.gold : AppTheme.navy), const SizedBox(width: 4), Text(text, style: TextStyle(color: muted, fontSize: 11))]);
}

String _statusLabel(StatusFicha? status) => switch (status) {
  StatusFicha.rascunho => 'Rascunho',
  StatusFicha.aguardandoAprovacao => 'Aguardando aprovação',
  StatusFicha.correcaoSolicitada => 'Correção solicitada',
  StatusFicha.aprovada => 'Aprovado',
  null => 'Sem ficha',
};

Color _statusColor(StatusFicha? status) => switch (status) {
  StatusFicha.rascunho => const Color(0xFF3973C9),
  StatusFicha.aguardandoAprovacao => const Color(0xFFDB8A00),
  StatusFicha.correcaoSolicitada => const Color(0xFFD92332),
  StatusFicha.aprovada => const Color(0xFF16813A),
  null => const Color(0xFF7C8798),
};

String _formatDate(DateTime? value) {
  if (value == null) return 'Data não informada';
  final local = value.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year} às ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}
