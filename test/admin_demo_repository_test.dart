import 'package:flutter_test/flutter_test.dart';
import 'package:ondonto_uninassau/data/models/usuario_dto.dart';
import 'package:ondonto_uninassau/data/repositories/admin_demo_repository.dart';

void main() {
  test(
    'local coordinator prototype can activate and deactivate users',
    () async {
      final repository = AdminDemoRepository();
      final before = await repository.listUsers();
      final student = before.firstWhere(
        (user) => user.perfil == PerfilUsuario.aluno,
      );

      final after = await repository.setActive(student.id, !student.ativo);
      final updated = after.firstWhere((user) => user.id == student.id);

      expect(updated.ativo, !student.ativo);
    },
  );
}
