import '../models/admin_user_demo_dto.dart';
import '../models/usuario_dto.dart';

/// In-memory-only coordinator panel sample; it does not call the backend.
class AdminDemoRepository {
  final List<AdminUserDemoDto> _users = [
    const AdminUserDemoDto(
      id: 1,
      nome: 'Ana Oliveira',
      email: 'ana.oliveira@uninassau.edu.br',
      matricula: 'OD2026A',
      perfil: PerfilUsuario.aluno,
      ativo: true,
    ),
    const AdminUserDemoDto(
      id: 2,
      nome: 'Pedro Lima',
      email: 'pedro.lima@uninassau.edu.br',
      matricula: 'OD2024B',
      perfil: PerfilUsuario.aluno,
      ativo: false,
      observacao: 'Acesso suspenso · trancamento (exemplo fictício)',
    ),
    const AdminUserDemoDto(
      id: 3,
      nome: 'Mariana Santos',
      email: 'mariana.santos@uninassau.edu.br',
      matricula: 'DOC2026',
      perfil: PerfilUsuario.professor,
      ativo: true,
    ),
    const AdminUserDemoDto(
      id: 4,
      nome: 'Recepção Clínica',
      email: 'recepcao@uninassau.edu.br',
      perfil: PerfilUsuario.recepcao,
      ativo: true,
    ),
  ];

  Future<List<AdminUserDemoDto>> listUsers() async => List.unmodifiable(_users);

  Future<List<AdminUserDemoDto>> setActive(int userId, bool active) async {
    final index = _users.indexWhere((user) => user.id == userId);
    if (index < 0) throw StateError('Usuário não encontrado no mock local.');
    _users[index] = _users[index].copyWith(ativo: active);
    return listUsers();
  }
}
