import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/atendimento_model.dart';
import '../../models/ficha_semiologia_model.dart';
import '../../models/usuario_model.dart';
import '../../view_models/atendimento_view_model.dart';
import '../../view_models/semiologia_view_model.dart';
import '../../widgets/botao_alternar_tema.dart';
import '../../widgets/navegacao_inferior_aluno.dart';
import '../atendimentos/meus_atendimentos_view.dart';
import '../atendimentos/semiologia/formulario_semiologia_view.dart';
import '../pacientes/buscar_paciente_view.dart';
import '../pacientes/cadastrar_paciente_view.dart';
import 'perfil_aluno_view.dart';
import '../pacientes/prontuario/prontuario_view.dart';

// ---------------------------------------------------------------------------
// Cores de apoio (apenas estética)
// ---------------------------------------------------------------------------

Color _heading(bool dark) => dark ? const Color(0xFFF3F6FC) : AppTheme.navy;
Color _link(bool dark) => dark ? const Color(0xFF9DBBFF) : const Color(0xFF1D4ED8);
Color _softFill(bool dark) => dark ? const Color(0xFF16304F) : const Color(0xFFE4ECFB);
Color _softBox(bool dark) => dark ? const Color(0xFF12233A) : const Color(0xFFEEF3FC);

class InicioAlunoView extends StatefulWidget {
  const InicioAlunoView({
    required this.usuario,
    required this.onLogout,
    super.key,
  });
  final UsuarioModel usuario;
  final VoidCallback onLogout;

  @override
  State<InicioAlunoView> createState() => _InicioAlunoViewState();
}

class _InicioAlunoViewState extends State<InicioAlunoView> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
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
    MaterialPageRoute<void>(builder: (_) => const BuscarPacienteView()),
  );

  void _createPatient() => Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => const CadastrarPacienteView(),
    ),
  );

  void _openAttendances() => Navigator.of(context).push<void>(
    MaterialPageRoute<void>(builder: (_) => const MeusAtendimentosView()),
  );

  void _openPatientRecord(MeuAtendimentoModel item) {
    final patientId = item.paciente?.pacienteId;
    if (patientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível localizar o paciente deste atendimento.',
          ),
        ),
      );
      return;
    }
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ProntuarioView(pacienteId: patientId),
      ),
    );
  }

  Future<void> _editFromHome(MeuAtendimentoModel item) async {
    final fichaId = item.atendimento.fichaId;
    final patient = item.paciente;
    if (fichaId == null || patient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'A API ainda não informa o ID da ficha deste atendimento para permitir a edição.',
          ),
        ),
      );
      return;
    }
    final ficha = await context.read<SemiologiaViewModel>().loadFicha(fichaId);
    if (!mounted) return;
    if (ficha == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível carregar a ficha para edição.'),
        ),
      );
      return;
    }
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => FormularioSemiologiaView(
          paciente: patient,
          atendimentoId: item.atendimento.id,
          ficha: ficha,
          teacherComment: item.atendimento.observacaoCorrecao,
        ),
      ),
    );
    if (mounted && changed == true) {
      context.read<AtendimentoViewModel>().loadMyAttendances();
    }
  }

  void _guidance() => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Como iniciar um atendimento'),
      content: const Text(
        'Busque ou cadastre o paciente, abra o prontuário e inicie um novo atendimento por lá.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Entendi'),
        ),
      ],
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
      key: _scaffoldKey,
      backgroundColor: page,
      drawer: _studentDrawer(dark, foreground, muted, line),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _StudentHeader(
                      usuario: widget.usuario,
                      compact: compact,
                      dark: dark,
                      card: card,
                      line: line,
                      foreground: foreground,
                      onMenu: () => _scaffoldKey.currentState?.openDrawer(),
                      onSearch: _openPatients,
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      compact ? 14 : 28,
                      14,
                      compact ? 14 : 28,
                      16,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1040),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _InfoBanner(
                                dark: dark,
                                foreground: foreground,
                                muted: muted,
                                line: line,
                                onTap: _guidance,
                              ),
                              const SizedBox(height: 20),
                              _SectionHeading(
                                'Acesso rápido',
                                foreground: foreground,
                              ),
                              const SizedBox(height: 10),
                              _quickActions(
                                compact,
                                dark,
                                foreground,
                                muted,
                                line,
                                card,
                              ),
                              const SizedBox(height: 22),
                              _appointmentsHeader(foreground, dark),
                              const SizedBox(height: 10),
                              _appointments(
                                dark,
                                foreground,
                                muted,
                                line,
                                card,
                              ),
                              const SizedBox(height: 10),
                              _seeAllBar(dark),
                              const SizedBox(height: 16),
                              _summary(dark, foreground, muted, line),
                              const SizedBox(height: 12),
                              _HelpCard(
                                dark: dark,
                                foreground: foreground,
                                muted: muted,
                                line: line,
                                onTap: _guidance,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            NavegacaoInferiorAluno(
              currentIndex: _tab,
              onDestinationSelected: (value) {
                if (value == 3) {
                  _openProfile();
                } else if (value == 1) {
                  _openPatients();
                } else if (value == 2) {
                  _openAttendances();
                } else {
                  setState(() => _tab = value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _studentDrawer(bool dark, Color foreground, Color muted, Color line) {
    final surface = dark ? const Color(0xFF0D1B2E) : Colors.white;
    return Drawer(
      backgroundColor: surface,
      child: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 150,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/brand_background.png',
                    fit: BoxFit.cover,
                  ),
                  ColoredBox(
                    color: const Color(0xFF05285A).withValues(alpha: .68),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ol\u00e1, ${widget.usuario.nome.split(' ').first}!',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Aluna de Odontologia',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.home_outlined,
                color: dark ? AppTheme.gold : AppTheme.navy,
              ),
              title: Text('In\u00edcio', style: TextStyle(color: foreground)),
              onTap: () {
                Navigator.pop(context);
                setState(() => _tab = 0);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.people_outline,
                color: dark ? AppTheme.gold : AppTheme.navy,
              ),
              title: Text('Pacientes', style: TextStyle(color: foreground)),
              onTap: () {
                Navigator.pop(context);
                _openPatients();
              },
            ),
            ListTile(
              leading: Icon(
                Icons.assignment_outlined,
                color: dark ? AppTheme.gold : AppTheme.navy,
              ),
              title: Text('Atendimentos', style: TextStyle(color: foreground)),
              onTap: () {
                Navigator.pop(context);
                _openAttendances();
              },
            ),
            Divider(color: line),
            ListTile(
              leading: Icon(Icons.brightness_6_outlined, color: muted),
              title: Text('Tema', style: TextStyle(color: foreground)),
              trailing: const BotaoAlternarTema(),
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFFD92332)),
              title: Text('Sair', style: TextStyle(color: foreground)),
              onTap: () {
                Navigator.pop(context);
                widget.onLogout();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickActions(
    bool compact,
    bool dark,
    Color fg,
    Color muted,
    Color line,
    Color card,
  ) {
    final items = [
      (
        Icons.search,
        'Buscar paciente',
        'Consultar prontuário de um paciente',
        _openPatients,
      ),
      (
        Icons.person_add_alt_1_outlined,
        'Cadastrar novo paciente',
        'Adicionar paciente ao sistema',
        _createPatient,
      ),
      (
        Icons.medical_services_outlined,
        'Novo atendimento',
        'Iniciar atendimento para um paciente',
        _openPatients,
      ),
      (
        Icons.menu_book_outlined,
        'Materiais e protocolos',
        'Guias e documentos de apoio',
        _guidance,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth > 760 ? 4 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: count,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            mainAxisExtent: 96,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return _QuickAction(
              icon: item.$1,
              title: item.$2,
              subtitle: item.$3,
              onTap: item.$4,
              dark: dark,
              foreground: fg,
              muted: muted,
              line: line,
              card: card,
            );
          },
        );
      },
    );
  }

  Widget _appointmentsHeader(Color fg, bool dark) => Row(
    children: [
      Expanded(child: _SectionHeading('Meus atendimentos', foreground: fg)),
      TextButton(
        onPressed: _openAttendances,
        style: TextButton.styleFrom(
          foregroundColor: _link(dark),
          padding: const EdgeInsets.only(left: 8, right: 0),
        ),
        child: const Text(
          'Ver todos',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
      ),
      Icon(Icons.chevron_right, color: _link(dark)),
    ],
  );

  /// Abas de status (mesma lógica dos antigos chips de filtro).
  Widget _statusTabs(bool dark, Color fg, Color muted) {
    const labels = [
      'Rascunhos',
      'Aguardando aprovação',
      'Correção solicitada',
      'Aprovados',
    ];
    const statuses = [
      StatusFicha.rascunho,
      StatusFicha.aguardandoAprovacao,
      StatusFicha.correcaoSolicitada,
      StatusFicha.aprovada,
    ];
    const countColors = [
      Color(0xFF1D4ED8),
      Color(0xFFDB8A00),
      Color(0xFFD92332),
      Color(0xFF16813A),
    ];
    return Consumer<AtendimentoViewModel>(
      builder: (context, model, _) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < labels.length; i++)
              InkWell(
                onTap: () => setState(() => _status = i),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: _status == i ? AppTheme.gold : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        labels[i],
                        style: TextStyle(
                          color: _status == i ? _heading(dark) : muted,
                          fontSize: 13,
                          fontWeight: _status == i ? FontWeight.w800 : FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        constraints: const BoxConstraints(minWidth: 24),
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: _status == i
                              ? countColors[i]
                              : countColors[i].withValues(alpha: dark ? .22 : .14),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${model.countForStatus(statuses[i])}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _status == i ? Colors.white : countColors[i],
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _appointments(
    bool dark,
    Color fg,
    Color muted,
    Color line,
    Color card,
  ) {
    const statuses = [
      StatusFicha.rascunho,
      StatusFicha.aguardandoAprovacao,
      StatusFicha.correcaoSolicitada,
      StatusFicha.aprovada,
    ];
    return Consumer<AtendimentoViewModel>(
      builder: (context, model, _) {
        final records = model.myAttendances
            .where((item) => item.status == statuses[_status])
            .take(2)
            .toList();
        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: card,
            border: Border.all(color: line),
            borderRadius: BorderRadius.circular(16),
            boxShadow: dark
                ? null
                : [
                    BoxShadow(
                      color: const Color(0xFF102B53).withValues(alpha: .04),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Column(
            children: [
              _statusTabs(dark, fg, muted),
              Divider(height: 1, color: line),
              if (model.isLoadingMine && records.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: LinearProgressIndicator(),
                ),
              if (model.myAttendancesError != null &&
                  model.myAttendances.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    model.myAttendancesError!,
                    style: TextStyle(color: muted),
                  ),
                ),
              if (!model.isLoadingMine &&
                  model.myAttendancesError == null &&
                  records.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Nenhum atendimento nesta etapa.',
                    style: TextStyle(color: muted),
                  ),
                ),
              for (var i = 0; i < records.length; i++) ...[
                _AppointmentRow(
                  item: records[i],
                  dark: dark,
                  foreground: fg,
                  muted: muted,
                  onTap: () => _openPatientRecord(records[i]),
                  onEdit: () => _editFromHome(records[i]),
                ),
                if (i < records.length - 1) Divider(height: 1, color: line),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _seeAllBar(bool dark) => Material(
    color: _softFill(dark),
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      onTap: _openAttendances,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Ver todos os meus atendimentos',
              style: TextStyle(
                color: _link(dark),
                fontWeight: FontWeight.w800,
                fontSize: 14.5,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right, color: _link(dark), size: 22),
          ],
        ),
      ),
    ),
  );

  Widget _summary(
    bool dark,
    Color fg,
    Color muted,
    Color line,
  ) => Consumer<AtendimentoViewModel>(
    builder: (context, model, _) => Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF0C1A2D) : Colors.white,
        border: Border.all(color: line),
        borderRadius: BorderRadius.circular(16),
        boxShadow: dark
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF102B53).withValues(alpha: .04),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Resumo dos meus atendimentos',
                  style: TextStyle(
                    color: _heading(dark),
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              Text(
                'Período: Este mês',
                style: TextStyle(color: muted, fontSize: 12),
              ),
              Icon(Icons.expand_more, size: 20, color: muted),
            ],
          ),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SummaryTile(
                icon: Icons.description_outlined,
                count: '${model.countThisMonth(StatusFicha.rascunho)}',
                label: 'Rascunhos',
                color: dark ? const Color(0xFF082B58) : const Color(0xFFE4ECFB),
                accent: dark ? const Color(0xFF9DBBFF) : const Color(0xFF1D4ED8),
              ),
              _SummaryTile(
                icon: Icons.access_time,
                count:
                    '${model.countThisMonth(StatusFicha.aguardandoAprovacao)}',
                label: 'Aguardando aprovação',
                color: dark ? const Color(0xFF45380A) : const Color(0xFFFFF3E0),
                accent: const Color(0xFFEB9B00),
              ),
              _SummaryTile(
                icon: Icons.reply,
                count:
                    '${model.countThisMonth(StatusFicha.correcaoSolicitada)}',
                label: 'Correção solicitada',
                color: dark ? const Color(0xFF44171D) : const Color(0xFFFFEEEE),
                accent: const Color(0xFFD92332),
              ),
              _SummaryTile(
                icon: Icons.check_circle_outline,
                count: '${model.countThisMonth(StatusFicha.aprovada)}',
                label: 'Aprovados',
                color: dark ? const Color(0xFF103C2C) : const Color(0xFFE6F4EA),
                accent: const Color(0xFF16813A),
              ),
            ],
          ),
          ),
        ],
      ),
    ),
  );

  void _openProfile() => Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => PerfilAlunoView(
        usuario: widget.usuario,
        onLogout: widget.onLogout,
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Cabeçalho azul arredondado, logo e busca sobreposta
// ---------------------------------------------------------------------------

class _StudentHeader extends StatelessWidget {
  const _StudentHeader({
    required this.usuario,
    required this.compact,
    required this.dark,
    required this.card,
    required this.line,
    required this.foreground,
    required this.onMenu,
    required this.onSearch,
  });
  final UsuarioModel usuario;
  final bool compact;
  final bool dark;
  final Color card;
  final Color line;
  final Color foreground;
  final VoidCallback onMenu;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final horizontal = compact ? 16.0 : 34.0;
    return SizedBox(
      height: compact ? 232 : 278,
      child: Stack(
        children: [
          // Fundo azul com cantos inferiores arredondados
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 30,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(30),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/brand_background.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFF05285A)
                          .withValues(alpha: dark ? .78 : .74),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Logo da Uninassau Odontologia
          Positioned(
            top: 44,
            right: compact ? 16 : 60,
            child: IgnorePointer(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: compact ? 150 : 220,
                  maxHeight: compact ? 104 : 150,
                ),
                child: Image.asset(
                  'assets/images/uninassau_odontologia_logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),
            ),
          ),
          Positioned(
            top: 3,
            left: 2,
            child: IconButton(
              onPressed: onMenu,
              color: Colors.white,
              icon: const Icon(Icons.menu_rounded),
            ),
          ),
          const Positioned(
            top: 3,
            right: 5,
            child: BotaoAlternarTema(color: Colors.white),
          ),
          Positioned(
            left: horizontal,
            right: 16,
            top: 58,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Olá, ${usuario.nome.split(' ').first}!',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 31 : 40,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Aluna de Odontologia',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .95),
                    fontSize: compact ? 15 : 20,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Turma: ${usuario.matricula?.isNotEmpty == true ? usuario.matricula : 'OD2026A'}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .95),
                    fontSize: compact ? 14 : 19,
                  ),
                ),
              ],
            ),
          ),
          // Busca sobreposta ao fundo azul
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1040),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 28),
                  child: _SearchBanner(
                    dark: dark,
                    foreground: foreground,
                    card: card,
                    line: line,
                    onTap: onSearch,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBanner extends StatelessWidget {
  const _SearchBanner({
    required this.dark,
    required this.foreground,
    required this.card,
    required this.line,
    required this.onTap,
  });
  final bool dark;
  final Color foreground;
  final Color card;
  final Color line;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: card,
    elevation: 0,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        decoration: BoxDecoration(
          border: Border.all(color: line),
          borderRadius: BorderRadius.circular(16),
          boxShadow: dark
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFF102B53).withValues(alpha: .08),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: _link(dark), size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Buscar paciente por nome, CPF ou código do prontuário',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foreground.withValues(alpha: .75),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.qr_code_scanner, color: AppTheme.gold, size: 24),
          ],
        ),
      ),
    ),
  );
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.dark,
    required this.foreground,
    required this.muted,
    required this.line,
    required this.onTap,
  });
  final bool dark;
  final Color foreground;
  final Color muted;
  final Color line;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: _softBox(dark),
    borderRadius: BorderRadius.circular(14),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: line),
          borderRadius: BorderRadius.circular(14),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: AppTheme.gold),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: _link(dark), size: 26),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Encontre o paciente primeiro',
                              style: TextStyle(
                                color: _link(dark),
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Para iniciar um atendimento ou preencher uma ficha de Semiologia, busque o paciente ou cadastre um novo.',
                              style: TextStyle(
                                color: muted,
                                fontSize: 12.5,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: _link(dark)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.text, {required this.foreground});
  final String text;
  final Color foreground;
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text,
      style: TextStyle(
        color: _heading(dark),
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: -.4,
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.dark,
    required this.foreground,
    required this.muted,
    required this.line,
    required this.card,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool dark;
  final Color foreground;
  final Color muted;
  final Color line;
  final Color card;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF111F34) : card,
          border: Border.all(color: line),
          borderRadius: BorderRadius.circular(14),
          boxShadow: dark
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFF102B53).withValues(alpha: .035),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _softFill(dark),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 26,
                color: dark ? AppTheme.gold : AppTheme.navy,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _heading(dark),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: muted, fontSize: 11.5, height: 1.2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _AppointmentRow extends StatelessWidget {
  const _AppointmentRow({
    required this.item,
    required this.dark,
    required this.foreground,
    required this.muted,
    required this.onTap,
    required this.onEdit,
  });
  final MeuAtendimentoModel item;
  final bool dark;
  final Color foreground;
  final Color muted;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final patient = item.paciente;
    final name = patient?.nomeCompleto ?? 'Atendimento #${item.atendimento.id}';
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2);
    final initials = parts.map((part) => part[0].toUpperCase()).join();
    final status = item.status;
    final editable =
        status == StatusFicha.rascunho ||
        status == StatusFicha.correcaoSolicitada;
    final accent = dark ? AppTheme.gold : AppTheme.navy;
    final statusColor = dark && status == StatusFicha.rascunho
        ? AppTheme.gold
        : _homeStatusColor(status);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: _softFill(dark),
              foregroundColor: dark ? const Color(0xFFD5E5FF) : AppTheme.navy,
              child: Text(
                initials.isEmpty ? '?' : initials,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 19,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: _heading(dark),
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 13,
                        color: accent,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          _attendanceDate(item.atendimento.iniciadoEm),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: muted, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1D4ED8),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          'Semiologia (Avaliação inicial)',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: foreground,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: dark ? .18 : .1),
                    border: Border.all(
                      color: statusColor.withValues(alpha: .35),
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    _homeStatusLabel(status),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (editable)
                  IconButton(
                    tooltip: 'Editar ficha',
                    onPressed: onEdit,
                    icon: Icon(Icons.edit_outlined, color: accent, size: 18),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            Icon(Icons.chevron_right, color: _heading(dark)),
          ],
        ),
      ),
    );
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
  StatusFicha.rascunho => const Color(0xFF1D4ED8),
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
  const _SummaryTile({
    required this.icon,
    required this.count,
    required this.label,
    required this.color,
    required this.accent,
  });
  final IconData icon;
  final String count;
  final String label;
  final Color color;
  final Color accent;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.fromLTRB(8, 10, 6, 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 22),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  count,
                  style: TextStyle(
                    color: accent,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 2,
            style: TextStyle(
              color: accent,
              fontSize: 11,
              height: 1.15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

class _HelpCard extends StatelessWidget {
  const _HelpCard({
    required this.dark,
    required this.foreground,
    required this.muted,
    required this.line,
    required this.onTap,
  });
  final bool dark;
  final Color foreground;
  final Color muted;
  final Color line;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: dark ? const Color(0xFF0F1D31) : Colors.white,
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: line),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              Icons.support_agent,
              color: dark ? const Color(0xFFD6E4FA) : AppTheme.navy,
              size: 30,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Precisa de ajuda?',
                    style: TextStyle(
                      color: _heading(dark),
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Fale com o suporte da clínica ou consulte o manual do sistema.',
                    style: TextStyle(color: muted, fontSize: 12, height: 1.25),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: dark ? const Color(0xFFD6E4FA) : AppTheme.navy,
            ),
          ],
        ),
      ),
    ),
  );
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty) return '?';
  return parts
      .take(2)
      .map((part) => part.isEmpty ? '' : part[0].toUpperCase())
      .join();
}