import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../model/user_model.dart';
import '../model/task_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('task_manager.db');
    return _database!;
  }

  Future<Database> _initDB(String filename) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filename);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        id TEXT PRIMARY KEY,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        email TEXT NOT NULL,
        avatar TEXT,
        createdAt INTEGER NOT NULL,
        lastActive INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE tasks(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        status TEXT NOT NULL,
        priority INTEGER NOT NULL,
        dueDate INTEGER,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        assignedTo TEXT,
        createdBy TEXT NOT NULL,
        category TEXT,
        attachments TEXT,
        completed INTEGER NOT NULL,
        FOREIGN KEY (assignedTo) REFERENCES users (id),
        FOREIGN KEY (createdBy) REFERENCES users (id)
      )
    ''');
  }

  /* ---------------------- USER TABLE ---------------------- */

  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert(
      'users',
      {
        'id': user.id,
        'username': user.username,
        'password': user.password,
        'email': user.email,
        'avatar': user.avatar,
        'createdAt': user.createdAt.millisecondsSinceEpoch,
        'lastActive': user.lastActive.millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<User?> getUserByUsername(String username) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    if (maps.isNotEmpty) {
      return _mapToUser(maps.first);
    }
    return null;
  }

  Future<User?> getUserById(String id) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return _mapToUser(maps.first);
    }
    return null;
  }

  Future<int> updateUserLastActive(String id, DateTime lastActive) async {
    final db = await database;
    return await db.update(
      'users',
      {'lastActive': lastActive.millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteUser(String id) async {
    final db = await database;
    return await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  User _mapToUser(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      password: map['password'],
      email: map['email'],
      avatar: map['avatar'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      lastActive: DateTime.fromMillisecondsSinceEpoch(map['lastActive']),
    );
  }

  /* ---------------------- TASK TABLE ---------------------- */

  Future<int> insertTask(Task task) async {
    final db = await database;
    return await db.insert(
      'tasks',
      _taskToMap(task),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Task>> getAllTasks() async {
    final db = await database;
    final maps = await db.query('tasks', orderBy: 'createdAt DESC');
    return maps.map((m) => _mapToTask(m)).toList();
  }

  Future<List<Task>> getTasksByAssignedTo(String assignedTo) async {
    final db = await database;
    final maps = await db.query(
      'tasks',
      where: 'assignedTo = ?',
      whereArgs: [assignedTo],
      orderBy: 'createdAt DESC',
    );
    return maps.map((m) => _mapToTask(m)).toList();
  }

  Future<Task?> getTaskById(String id) async {
    final db = await database;
    final maps = await db.query('tasks', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return _mapToTask(maps.first);
    }
    return null;
  }

  Future<int> updateTask(Task task) async {
    final db = await database;
    return await db.update(
      'tasks',
      _taskToMap(task),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> deleteTask(String id) async {
    final db = await database;
    return await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Map<String, dynamic> _taskToMap(Task task) {
    return {
      'id': task.id,
      'title': task.title,
      'description': task.description,
      'status': task.status,
      'priority': task.priority,
      'dueDate': task.dueDate?.millisecondsSinceEpoch,
      'createdAt': task.createdAt.millisecondsSinceEpoch,
      'updatedAt': task.updatedAt.millisecondsSinceEpoch,
      'assignedTo': task.assignedTo,
      'createdBy': task.createdBy,
      'category': task.category,
      'attachments': task.attachments != null ? jsonEncode(task.attachments) : null,
      'completed': task.completed ? 1 : 0,
    };
  }

  Task _mapToTask(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      status: map['status'],
      priority: map['priority'],
      dueDate: map['dueDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['dueDate'])
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
      assignedTo: map['assignedTo'],
      createdBy: map['createdBy'],
      category: map['category'],
      attachments: map['attachments'] != null
          ? List<String>.from(jsonDecode(map['attachments']))
          : null,
      completed: map['completed'] == 1,
    );
  }
}