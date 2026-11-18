import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/atendimento_dto.dart';
import '../../data/models/ficha_semiologia_dto.dart';
import '../../data/models/usuario_dto.dart';
import '../../data/viewmodels/atendimento_view_model.dart';
import '../../data/viewmodels/auth_view_model.dart';
import '../../data/viewmodels/semiologia_view_model.dart';
import '../admin/admin_home_view.dart';
import '../pacientes/patient_search_view.dart';
import '../pacientes/reception_home_view.dart';
import '../professor/professor_home_view.dart';
import '../prontuario/prontuario_view.dart';
import '../semiologia/semiologia_form_view.dart';
import '../semiologia/student_attendances_view.dart';
import '../widgets/student_footer_navigation.dart';
import '../widgets/theme_toggle_button.dart';
import 'login_view.dart';

/// Routes authenticated users to the area allowed by their profile.
class ProfileLandingView extends StatelessWidget {
  const ProfileLandingView({required this.usuario, super.key});

  final UsuarioDto usuario;

  @override
  Widget build(BuildContext context) {
    return switch (usuario.perfil) {
      PerfilUsuario.professor => const ProfessorHomeView(),
      PerfilUsuario.recepcao => const ReceptionHomeView(),
      PerfilUsuario.admin => const AdminHomeView(),
      PerfilUsuario.aluno => _StudentHomeView(usuario: usuario),
      _ => _UnknownProfileView(usuario: usuario),
    };
  }
}

class _UnknownProfileView extends StatelessWidget {
  const _UnknownProfileView({required this.usuario});
  final UsuarioDto usuario;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Perfil não reconhecido'), actions: const [ThemeToggleButton()]),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.verified_user_outlined, size: 48),
          const SizedBox(height: 16),
          Text(usuario.nome, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text('O perfil retornado pela API não está definido.'),
          const SizedBox(height: 24),
          OutlinedButton.icon(onPressed: () => _logout(context), icon: const Icon(Icons.logout), label: const Text('Sair')),
        ]),
      ),
    ),
  );
}

void _logout(BuildContext context) {
  context.read<AuthViewModel>().logout();
  Navigator.of(context).pushAndRemoveUntil<void>(
    MaterialPageRoute<void>(builder: (_) => const LoginView()), (_) => false,
  );
}

class _StudentHomeView extends StatefulWidget {
  const _StudentHomeView({required this.usuario});
  final UsuarioDto usuario;

  @override
  State<_StudentHomeView> createState() => _StudentHomeViewState();
}

class _StudentHomeViewState extends State<_StudentHomeView> {
  int _tab = 0;
  int _status = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AtendimentoViewModel>().loadMyAttendances();
    });
  }

  void _openPatients() => Navigator.of(context).push<void>(
    MaterialPageRoute<void>(builder: (_) => const PatientSearchView()),
  );

  void _openAttendances() => Navigator.of(context).push<void>(
    MaterialPageRoute<void>(builder: (_) => const StudentAttendancesView()),
  );

  void _openPatientRecord(MeuAtendimentoDto item) {
    final patientId = item.paciente?.pacienteId;
    if (patientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível localizar o paciente deste atendimento.')));
      return;
    }
    Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => ProntuarioView(pacienteId: patientId)));
  }

  Future<void> _editFromHome(MeuAtendimentoDto item) async {
    final fichaId = item.atendimento.fichaId;
    final patient = item.paciente;
    if (fichaId == null || patient == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A API ainda não informa o ID da ficha deste atendimento para permitir a edição.')));
      return;
    }
    final ficha = await context.read<SemiologiaViewModel>().loadFicha(fichaId);
    if (!mounted) return;
    if (ficha == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível carregar a ficha para edição.')));
      return;
    }
    final changed = await Navigator.of(context).push<bool>(MaterialPageRoute<bool>(builder: (_) => SemiologiaFormView(
      paciente: patient,
      atendimentoId: item.atendimento.id,
      ficha: ficha,
      teacherComment: item.atendimento.observacaoCorrecao,
    )));
    if (mounted && changed == true) context.read<AtendimentoViewModel>().loadMyAttendances();
  }

  void _guidance() => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Como iniciar um atendimento'),
      content: const Text('Busque ou cadastre o paciente, abra o prontuário e inicie um novo atendimento por lá.'),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Entendi'))],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final foreground = dark ? const Color(0xFFF3F6FC) : const Color(0xFF102B53);
    final muted = dark ? const Color(0xFFB9C7DD) : const Color(0xFF52647E);
    final page = dark ? const Color(0xFF071426) : const Color(0xFFF7F8FA);
    final card = dark ? const Color(0xFF101E32) : Colors.white;
    final line = dark ? const Color(0xFF263A56) : const Color(0xFFE1E5EB);
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 600;

    return Scaffold(
      backgroundColor: page,
      body: SafeArea(bottom: false, child: Column(children: [
        Expanded(child: CustomScrollView(slivers: [
          SliverToBoxAdapter(child: _StudentHeader(
            usuario: widget.usuario, compact: compact, dark: dark,
            onMenu: () => _showMenu(context),
          )),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(compact ? 14 : 28, 12, compact ? 14 : 28, 16),
            sliver: SliverToBoxAdapter(child: Center(child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                _SearchBanner(dark: dark, foreground: foreground, card: card, line: line, onTap: _openPatients),
                const SizedBox(height: 12),
                _InfoBanner(dark: dark, foreground: foreground, muted: muted, line: line, onTap: _guidance),
                const SizedBox(height: 18),
                _SectionHeading('Acesso rápido', foreground: foreground),
                const SizedBox(height: 10),
                _quickActions(compact, dark, foreground, muted, line, card),
                const SizedBox(height: 20),
                _appointmentsHeader(foreground, dark),
                const SizedBox(height: 10),
                _statusFilters(dark, foreground, line),
                _appointments(dark, foreground, muted, line, card),
                const SizedBox(height: 16),
                _summary(dark, foreground, muted, line),
                const SizedBox(height: 12),
                _HelpCard(dark: dark, foreground: foreground, muted: muted, line: line, onTap: _guidance),
              ]),
            ))),
          ),
        ])),
        StudentFooterNavigation(currentIndex: _tab, onDestinationSelected: (value) {
          if (value == 3) {
            _showProfile(context, foreground, muted, dark);
          } else if (value == 1) {
            _openPatients();
          } else if (value == 2) {
            _openAttendances();
          } else {
            setState(() => _tab = value);
          }
        }),
      ])),
    );
  }

  Widget _quickActions(bool compact, bool dark, Color fg, Color muted, Color line, Color card) {
    final items = [
      (Icons.search, 'Buscar\npaciente', 'Consultar prontuário', _openPatients),
      (Icons.person_add_alt_1_outlined, 'Cadastrar\nnovo paciente', 'Adicionar paciente\nao sistema', _openPatients),
      (Icons.medical_services_outlined, 'Novo\natendimento', 'Iniciar atendimento\npara um paciente', _openPatients),
      (Icons.menu_book_outlined, 'Materiais e\nprotocolos', 'Guias e documentos\nde apoio', _guidance),
    ];
    return LayoutBuilder(builder: (context, constraints) {
      final count = constraints.maxWidth > 760 ? 4 : (constraints.maxWidth > 430 ? 4 : 2);
      return GridView.count(
        crossAxisCount: count,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: count == 4 ? (compact ? .75 : 1.05) : 1.1,
        children: items.map((item) => _QuickAction(
          icon: item.$1, title: item.$2, subtitle: item.$3, onTap: item.$4,
          dark: dark, foreground: fg, muted: muted, line: line, card: card,
        )).toList(),
      );
    });
  }

  Widget _appointmentsHeader(Color fg, bool dark) => Row(children: [
    Expanded(child: _SectionHeading('Meus atendimentos', foreground: fg)),
    TextButton(onPressed: _openAttendances, child: Text('Ver todos', style: TextStyle(color: dark ? AppTheme.gold : AppTheme.navy, fontWeight: FontWeight.bold))),
    Icon(Icons.chevron_right, color: dark ? AppTheme.gold : AppTheme.navy),
  ]);

  Widget _statusFilters(bool dark, Color fg, Color line) {
    const labels = ['Rascunhos', 'Aguardando aprovação', 'Correção solicitada', 'Aprovados'];
    const statuses = [StatusFicha.rascunho, StatusFicha.aguardandoAprovacao, StatusFicha.correcaoSolicitada, StatusFicha.aprovada];
    return Consumer<AtendimentoViewModel>(builder: (context, model, _) => SizedBox(height: 38, child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: labels.length,
      separatorBuilder: (_, __) => const SizedBox(width: 6),
      itemBuilder: (context, i) {
        final selected = _status == i;
        return ChoiceChip(
          selected: selected,
          onSelected: (_) => setState(() => _status = i),
          label: Text('${labels[i]}  ${model.countForStatus(statuses[i])}', style: TextStyle(color: selected ? (dark ? const Color(0xFF1A2B43) : Colors.white) : fg, fontSize: 12, fontWeight: FontWeight.w600)),
          selectedColor: dark ? AppTheme.gold : AppTheme.navy,
          backgroundColor: dark ? const Color(0xFF14243A) : const Color(0xFFEFF2F7),
          side: BorderSide(color: selected ? Colors.transparent : line),
          showCheckmark: false,
          padding: const EdgeInsets.symmetric(horizontal: 7),
          visualDensity: VisualDensity.compact,
        );
      },
    )));
  }

  Widget _appointments(bool dark, Color fg, Color muted, Color line, Color card) {
    const statuses = [StatusFicha.rascunho, StatusFicha.aguardandoAprovacao, StatusFicha.correcaoSolicitada, StatusFicha.aprovada];
    return Consumer<AtendimentoViewModel>(builder: (context, model, _) {
      final records = model.myAttendances.where((item) => item.status == statuses[_status]).take(2).toList();
      return Container(
      decoration: BoxDecoration(color: card, border: Border.all(color: line), borderRadius: BorderRadius.circular(14)),
      child: Column(children: [
        if (model.isLoadingMine && records.isEmpty) const Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator()),
        if (model.myAttendancesError != null && model.myAttendances.isEmpty) Padding(padding: const EdgeInsets.all(16), child: Text(model.myAttendancesError!, style: TextStyle(color: muted))),
        if (!model.isLoadingMine && model.myAttendancesError == null && records.isEmpty) Padding(padding: const EdgeInsets.all(16), child: Text('Nenhum atendimento nesta etapa.', style: TextStyle(color: muted))),
        for (var i = 0; i < records.length; i++) ...[
          _AppointmentRow(item: records[i], dark: dark, foreground: fg, muted: muted, onTap: () => _openPatientRecord(records[i]), onEdit: () => _editFromHome(records[i])),
          if (i < records.length - 1) Divider(height: 1, color: line),
        ],
        Divider(height: 1, color: line),
        TextButton.icon(onPressed: _openAttendances, icon: const Icon(Icons.chevron_right), label: const Text('Ver todos os meus atendimentos'), style: TextButton.styleFrom(foregroundColor: dark ? AppTheme.gold : AppTheme.navy)),
      ]),
    );
    });
  }

  Widget _summary(bool dark, Color fg, Color muted, Color line) => Consumer<AtendimentoViewModel>(builder: (context, model, _) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: dark ? const Color(0xFF0C1A2D) : Colors.white, border: Border.all(color: line), borderRadius: BorderRadius.circular(14)),
    child: Column(children: [
      Row(children: [Expanded(child: Text('Resumo dos meus atendimentos', style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 13))), Text('Período: Este mês', style: TextStyle(color: muted, fontSize: 11)), const Icon(Icons.expand_more, size: 18)]),
      const SizedBox(height: 10),
      Row(children: [
        _SummaryTile(icon: Icons.description_outlined, count: '${model.countThisMonth(StatusFicha.rascunho)}', label: 'Rascunhos', color: dark ? const Color(0xFF082B58) : const Color(0xFFEDF2FA), accent: dark ? AppTheme.gold : AppTheme.navy),
        _SummaryTile(icon: Icons.access_time, count: '${model.countThisMonth(StatusFicha.aguardandoAprovacao)}', label: 'Aguardando\naprovação', color: dark ? const Color(0xFF45380A) : const Color(0xFFFFF6E5), accent: const Color(0xFFEB9B00)),
        _SummaryTile(icon: Icons.reply, count: '${model.countThisMonth(StatusFicha.correcaoSolicitada)}', label: 'Correção\nsolicitada', color: dark ? const Color(0xFF44171D) : const Color(0xFFFFEEEE), accent: const Color(0xFFD92332)),
        _SummaryTile(icon: Icons.check_circle_outline, count: '${model.countThisMonth(StatusFicha.aprovada)}', label: 'Aprovados', color: dark ? const Color(0xFF103C2C) : const Color(0xFFEAF6EF), accent: const Color(0xFF16813A)),
      ]),
    ]),
  ));

  void _showMenu(BuildContext context) => showModalBottomSheet<void>(context: context, builder: (context) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
    ListTile(leading: const Icon(Icons.people_outline), title: const Text('Pacientes'), onTap: () { Navigator.pop(context); _openPatients(); }),
    ListTile(leading: const Icon(Icons.logout), title: const Text('Sair'), onTap: () { Navigator.pop(context); _logout(context); }),
  ])));

  void _showProfile(BuildContext context, Color fg, Color muted, bool dark) => showModalBottomSheet<void>(context: context, builder: (context) => SafeArea(child: Padding(
    padding: const EdgeInsets.all(24),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      CircleAvatar(radius: 32, child: Text(_initials(widget.usuario.nome))),
      const SizedBox(height: 10), Text(widget.usuario.nome, style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 18)),
      Text(widget.usuario.email, style: TextStyle(color: muted)),
      const SizedBox(height: 14),
      const ThemeToggleButton(),
      TextButton.icon(onPressed: () { Navigator.pop(context); _logout(context); }, icon: const Icon(Icons.logout), label: const Text('Sair')),
    ]),
  )));
}

class _StudentHeader extends StatelessWidget {
  const _StudentHeader({required this.usuario, required this.compact, required this.dark, required this.onMenu});
  final UsuarioDto usuario;
  final bool compact;
  final bool dark;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: compact ? 190 : 250,
    child: Stack(fit: StackFit.expand, children: [
      Image.asset('assets/images/brand_background.png', fit: BoxFit.cover, alignment: Alignment.center),
      DecoratedBox(decoration: BoxDecoration(color: const Color(0xFF05285A).withValues(alpha: dark ? .72 : .66))),
      Positioned(top: 3, left: 2, child: IconButton(onPressed: onMenu, color: Colors.white, icon: const Icon(Icons.menu_rounded))),
      const Positioned(top: 3, right: 5, child: ThemeToggleButton(color: Colors.white)),
      Positioned(left: compact ? 16 : 34, right: 16, bottom: compact ? 14 : 22, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Olá, ${usuario.nome.split(' ').first}!', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white, fontSize: compact ? 25 : 38, fontWeight: FontWeight.w800, letterSpacing: -.5)),
        const SizedBox(height: 2),
        Text('Aluna de Odontologia', style: TextStyle(color: Colors.white.withValues(alpha: .95), fontSize: compact ? 14 : 20)),
        Text('Turma: ${usuario.matricula?.isNotEmpty == true ? usuario.matricula : 'OD2026A'}', style: TextStyle(color: Colors.white.withValues(alpha: .95), fontSize: compact ? 13 : 19)),
      ])),
    ]),
  );
}

class _SearchBanner extends StatelessWidget {
  const _SearchBanner({required this.dark, required this.foreground, required this.card, required this.line, required this.onTap});
  final bool dark; final Color foreground; final Color card; final Color line; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(color: Colors.transparent, child: InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), decoration: BoxDecoration(color: card, border: Border.all(color: line), borderRadius: BorderRadius.circular(14)), child: Row(children: [
      Icon(Icons.search, color: foreground, size: 24), const SizedBox(width: 10),
      Expanded(child: Text('Buscar paciente por nome, CPF ou código do prontuário', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: foreground, fontSize: 12, fontWeight: FontWeight.w600))),
      const SizedBox(width: 6), Icon(Icons.qr_code_scanner, color: AppTheme.gold, size: 24),
    ])),
  ));
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.dark, required this.foreground, required this.muted, required this.line, required this.onTap});
  final bool dark; final Color foreground; final Color muted; final Color line; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(color: dark ? const Color(0xFF14243A) : const Color(0xFFF0F3F8), borderRadius: BorderRadius.circular(13), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(13), child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
    decoration: BoxDecoration(border: Border.all(color: line), borderRadius: BorderRadius.circular(13)),
    child: Row(children: [const Icon(Icons.info_outline, color: AppTheme.gold, size: 23), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Encontre o paciente primeiro', style: TextStyle(color: foreground, fontSize: 13, fontWeight: FontWeight.bold)), const SizedBox(height: 2), Text('Para iniciar um atendimento ou preencher uma ficha de Semiologia, busque o paciente ou cadastre um novo.', style: TextStyle(color: muted, fontSize: 11, height: 1.3))])), Icon(Icons.chevron_right, color: dark ? AppTheme.gold : AppTheme.navy)]),
  )));
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.text, {required this.foreground});
  final String text; final Color foreground;
  @override
  Widget build(BuildContext context) => Text(text, style: TextStyle(color: foreground, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -.3));
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.title, required this.subtitle, required this.onTap, required this.dark, required this.foreground, required this.muted, required this.line, required this.card});
  final IconData icon; final String title; final String subtitle; final VoidCallback onTap; final bool dark; final Color foreground; final Color muted; final Color line; final Color card;
  @override
  Widget build(BuildContext context) => Material(color: Colors.transparent, child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: Container(
    padding: const EdgeInsets.all(9),
    decoration: BoxDecoration(color: dark ? const Color(0xFF111F34) : card, border: Border.all(color: line), borderRadius: BorderRadius.circular(12)),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 31, color: dark ? AppTheme.gold : AppTheme.navy), const SizedBox(height: 7),
      Text(title, textAlign: TextAlign.center, style: TextStyle(color: foreground, fontSize: 12, fontWeight: FontWeight.bold, height: 1.1)),
      const SizedBox(height: 5), Text(subtitle, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: muted, fontSize: 10, height: 1.15)),
    ]),
  )));
}

class _AppointmentRow extends StatelessWidget {
  const _AppointmentRow({required this.item, required this.dark, required this.foreground, required this.muted, required this.onTap, required this.onEdit});
  final MeuAtendimentoDto item;
  final bool dark;
  final Color foreground;
  final Color muted;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final patient = item.paciente;
    final name = patient?.nomeCompleto ?? 'Atendimento #${item.atendimento.id}';
    final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).take(2);
    final initials = parts.map((part) => part[0].toUpperCase()).join();
    final status = item.status;
    final editable = status == StatusFicha.rascunho || status == StatusFicha.correcaoSolicitada;
    final accent = dark ? AppTheme.gold : AppTheme.navy;
    final statusColor = dark && status == StatusFicha.rascunho ? AppTheme.gold : _homeStatusColor(status);
    return InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 11), child: Row(children: [
      CircleAvatar(radius: 24, backgroundColor: dark ? const Color(0xFF0A356D) : const Color(0xFFEAF0F9), foregroundColor: dark ? const Color(0xFFD5E5FF) : AppTheme.navy, child: Text(initials.isEmpty ? '?' : initials, style: const TextStyle(fontWeight: FontWeight.bold))),
      const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name, style: TextStyle(color: foreground, fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2), Text('Semiologia (Avaliação inicial)', style: TextStyle(color: muted, fontSize: 11)),
        Row(children: [Icon(Icons.calendar_today_outlined, size: 12, color: accent), const SizedBox(width: 4), Expanded(child: Text(_attendanceDate(item.atendimento.iniciadoEm), style: TextStyle(color: muted, fontSize: 10)))]),
      ])),
      const SizedBox(width: 4),
      Column(children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: statusColor.withValues(alpha: dark ? .18 : .12), borderRadius: BorderRadius.circular(18)), child: Text(_homeStatusLabel(status), style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold))),
        if (editable) IconButton(tooltip: 'Editar ficha', onPressed: onEdit, icon: Icon(Icons.edit_outlined, color: accent, size: 17), visualDensity: VisualDensity.compact),
      ]),
      Icon(Icons.chevron_right, color: accent),
    ])));
  }
}

String _homeStatusLabel(StatusFicha? status) => switch (status) {
  StatusFicha.rascunho => 'Rascunho',
  StatusFicha.aguardandoAprovacao => 'Aguardando',
  StatusFicha.correcaoSolicitada => 'Correção',
  StatusFicha.aprovada => 'Aprovado',
  null => 'Sem ficha',
};

Color _homeStatusColor(StatusFicha? status) => switch (status) {
  StatusFicha.rascunho => const Color(0xFF3973C9),
  StatusFicha.aguardandoAprovacao => const Color(0xFFDB8A00),
  StatusFicha.correcaoSolicitada => const Color(0xFFD92332),
  StatusFicha.aprovada => const Color(0xFF16813A),
  null => const Color(0xFF7C8798),
};

String _attendanceDate(DateTime? value) {
  if (value == null) return 'Data não informada';
  final date = value.toLocal();
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} · ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.icon, required this.count, required this.label, required this.color, required this.accent});
  final IconData icon; final String count; final String label; final Color color; final Color accent;
  @override
  Widget build(BuildContext context) => Expanded(child: Container(margin: const EdgeInsets.symmetric(horizontal: 2), padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)), child: Column(children: [
    Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: accent, size: 18), const SizedBox(width: 3), Text(count, style: TextStyle(color: accent, fontSize: 20, fontWeight: FontWeight.w800))]),
    Text(label, textAlign: TextAlign.center, maxLines: 2, style: TextStyle(color: accent, fontSize: 10, height: 1.05)),
  ])));
}

class _HelpCard extends StatelessWidget {
  const _HelpCard({required this.dark, required this.foreground, required this.muted, required this.line, required this.onTap});
  final bool dark; final Color foreground; final Color muted; final Color line; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(color: dark ? const Color(0xFF0F1D31) : Colors.white, borderRadius: BorderRadius.circular(13), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(13), child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), decoration: BoxDecoration(border: Border.all(color: line), borderRadius: BorderRadius.circular(13)), child: Row(children: [Icon(Icons.support_agent, color: dark ? const Color(0xFFD6E4FA) : AppTheme.navy, size: 27), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Precisa de ajuda?', style: TextStyle(color: foreground, fontWeight: FontWeight.bold, fontSize: 12)), Text('Fale com o suporte da clínica ou consulte o manual do sistema.', style: TextStyle(color: muted, fontSize: 10))])), Icon(Icons.chevron_right, color: dark ? const Color(0xFFD6E4FA) : AppTheme.navy)]))));
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty) return '?';
  return parts.take(2).map((part) => part.isEmpty ? '' : part[0].toUpperCase()).join();
}
