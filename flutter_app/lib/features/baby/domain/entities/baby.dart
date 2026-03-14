class Baby {
  const Baby({
    this.id,
    required this.userId,
    required this.name,
    required this.birthDate,
    required this.gender,
    this.avatar,
    required this.createdAt,
  });

  final int? id;
  final int userId;
  final String name;
  final DateTime birthDate;
  final String gender;
  final String? avatar;
  final DateTime createdAt;
}
