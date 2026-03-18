class UserProfile {
  final String id;
  final String email;
  final String role; // 'ADMIN' | 'STAFF'
  final String? fullName;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  const UserProfile({
    required this.id,
    required this.email,
    required this.role,
    this.fullName,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  bool get isAdmin => role.toUpperCase() == 'ADMIN';

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
      return null;
    }

    return UserProfile(
      id: (map['id'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      role: (map['role'] ?? 'STAFF').toString(),
      fullName: map['full_name']?.toString(),
      createdAt: parseDate(map['created_at']),
      updatedAt: parseDate(map['updated_at']),
      deletedAt: parseDate(map['deleted_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'full_name': fullName,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}

