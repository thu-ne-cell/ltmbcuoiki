import 'package:flutter/material.dart';

import '../model/user_model.dart';
import '../db/DatabaseHelper.dart';

class UserProvider with ChangeNotifier {
  User? _currentUser;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  User? get currentUser => _currentUser;

  bool get isLoggedIn => _currentUser != null;

  // Giả sử admin được xác định dựa trên trường username
  bool get isAdmin => _currentUser?.username.toLowerCase() == 'admin';

  /// Đăng nhập người dùng
  Future<bool> login(String username, String password) async {
    final user = await _dbHelper.getUserByUsername(username);
    if (user != null && user.password == password) {
      _currentUser = user;
      // Cập nhật lastActive
      await _dbHelper.updateUserLastActive(user.id, DateTime.now());
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Đăng ký người dùng mới (trả về true nếu thành công)
  Future<bool> register(User newUser) async {
    final existingUser = await _dbHelper.getUserByUsername(newUser.username);
    if (existingUser != null) {
      // Tên đăng nhập đã tồn tại
      return false;
    }
    await _dbHelper.insertUser(newUser);
    _currentUser = newUser;
    notifyListeners();
    return true;
  }

  /// Đăng xuất
  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}