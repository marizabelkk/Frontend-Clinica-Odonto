import 'package:flutter/foundation.dart';

import '../models/admin_user_demo_dto.dart';
import '../repositories/admin_demo_repository.dart';

class AdminViewModel extends ChangeNotifier {
  AdminViewModel({required this.repository});

  final AdminDemoRepository repository;
  List<AdminUserDemoDto> _users = const [];
  bool _isLoading = false;

  List<AdminUserDemoDto> get users => _users;
  bool get isLoading => _isLoading;

  Future<void> loadUsers() async {
    _isLoading = true;
    notifyListeners();
    _users = await repository.listUsers();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> setActive(int userId, bool active) async {
    _isLoading = true;
    notifyListeners();
    _users = await repository.setActive(userId, active);
    _isLoading = false;
    notifyListeners();
  }
}
