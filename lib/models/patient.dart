class Patient {
  final String id;
  final String? studentId;
  final String? firstName;
  final String? lastName;
  final String? type;
  final String? department;
  final DateTime? birthDate;
  final String? contactNumber;
  final String? address;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  const Patient({
    required this.id,
    this.studentId,
    this.firstName,
    this.lastName,
    this.type,
    this.department,
    this.birthDate,
    this.contactNumber,
    this.address,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  String get fullName {
    final a = (firstName ?? '').trim();
    final b = (lastName ?? '').trim();
    final name = ('$a $b').trim();
    return name.isEmpty ? '-' : name;
  }

  Patient copyWith({
    String? id,
    String? studentId,
    String? firstName,
    String? lastName,
    String? type,
    String? department,
    DateTime? birthDate,
    String? contactNumber,
    String? address,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Patient(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      type: type ?? this.type,
      department: department ?? this.department,
      birthDate: birthDate ?? this.birthDate,
      contactNumber: contactNumber ?? this.contactNumber,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  factory Patient.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
      return null;
    }

    return Patient(
      id: (map['id'] ?? '').toString(),
      studentId: map['student_id']?.toString(),
      firstName: map['first_name']?.toString(),
      lastName: map['last_name']?.toString(),
      type: map['type']?.toString(),
      department: map['department']?.toString(),
      birthDate: parseDate(map['birth_date']),
      contactNumber: map['contact_number']?.toString(),
      address: map['address']?.toString(),
      createdAt: parseDate(map['created_at']),
      updatedAt: parseDate(map['updated_at']),
      deletedAt: parseDate(map['deleted_at']),
    );
  }

  Map<String, dynamic> toMap() {
    String? toIsoDate(DateTime? d) {
      if (d == null) return null;
      final y = d.year.toString().padLeft(4, '0');
      final m = d.month.toString().padLeft(2, '0');
      final day = d.day.toString().padLeft(2, '0');
      return '$y-$m-$day';
    }

    return {
      'id': id,
      'student_id': studentId,
      'first_name': firstName,
      'last_name': lastName,
      'type': type,
      'department': department,
      'birth_date': toIsoDate(birthDate),
      'contact_number': contactNumber,
      'address': address,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}

