class AppUser {
  const AppUser({
    this.id,
    required this.username,
    required this.passwordHash,
    required this.createdAt,
  });

  final int? id;
  final String username;
  final String passwordHash;
  final DateTime createdAt;
}
