class User {
  const User({
    required this.id,
    required this.email,
    required this.role,
    this.name,
    this.phone,
    this.year,
    this.branch,
  });

  final String id;
  final String email;
  final String role;
  final String? name;
  final String? phone;
  final String? year;
  final String? branch;

  /// Display name: use name if available, otherwise derive from email.
  String get displayName => (name != null && name!.isNotEmpty) ? name! : email.split('@').first;

  User copyWith({
    String? id,
    String? email,
    String? role,
    String? name,
    String? phone,
    String? year,
    String? branch,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      year: year ?? this.year,
      branch: branch ?? this.branch,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'name': name,
      'phone': phone,
      'year': year,
      'branch': branch,
    };
  }

  factory User.fromMap(Map<dynamic, dynamic> map) {
    return User(
      id: (map['id'] ?? '') as String,
      email: (map['email'] ?? '') as String,
      role: (map['role'] ?? 'student') as String,
      name: map['name'] as String?,
      phone: map['phone'] as String?,
      year: map['year'] as String?,
      branch: map['branch'] as String?,
    );
  }
}
