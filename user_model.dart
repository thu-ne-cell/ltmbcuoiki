class User {
  final String id;
  final String username;
  final String password;
  final String email;
  final String? avatar;
  final DateTime createdAt;
  final DateTime lastActive;

  User({
    required this.id,
    required this.username,
    required this.password,
    required this.email,
    this.avatar,
    required this.createdAt,
    required this.lastActive,
  });
}