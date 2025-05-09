import 'package:flutter/material.dart';

import '../model/task_model.dart';
import '../db/DatabaseHelper.dart';

class TaskProvider with ChangeNotifier {
  List<Task> _tasks = [];
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<Task> get tasks => [..._tasks];

  /// Lấy tất cả công việc hoặc lọc theo user/admin
  /// Nếu isAdmin == true thì lấy toàn bộ công việc
  /// Nếu userId khác null thì lấy công việc gán cho user đó
  Future<void> fetchTasks({String? userId, bool isAdmin = false}) async {
    if (isAdmin) {
      _tasks = await _dbHelper.getAllTasks();
    } else if (userId != null) {
      _tasks = await _dbHelper.getTasksByAssignedTo(userId);
    } else {
      _tasks = [];
    }
    notifyListeners();
  }

  /// Thêm công việc mới
  Future<void> addTask(Task task) async {
    await _dbHelper.insertTask(task);
    _tasks.add(task);
    notifyListeners();
  }

  /// Cập nhật công việc
  Future<void> updateTask(Task task) async {
    await _dbHelper.updateTask(task);
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index >= 0) {
      _tasks[index] = task;
      notifyListeners();
    }
  }

  /// Xóa công việc
  Future<void> deleteTask(String taskId) async {
    await _dbHelper.deleteTask(taskId);
    _tasks.removeWhere((t) => t.id == taskId);
    notifyListeners();
  }

  /// Tìm kiếm công việc theo tiêu đề hoặc mô tả
  List<Task> searchTasks(String query) {
    final q = query.toLowerCase();
    return _tasks.where((t) {
      return t.title.toLowerCase().contains(q) ||
          (t.description.toLowerCase().contains(q));
    }).toList();
  }

  /// Lọc công việc theo trạng thái và phân loại
  List<Task> filterTasks({String? status, String? category}) {
    return _tasks.where((t) {
      final matchStatus = status == null || t.status == status;
      final matchCategory = category == null || t.category == category;
      return matchStatus && matchCategory;
    }).toList();
  }
}