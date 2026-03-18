import '../utils/patient_name.dart';

class Visit {
  final String id;
  final String? patientId;
  final DateTime? visitDate;
  final String? vitals;
  final String? assessment;
  final String? treatment;
  final String? notes;
  final String? staffId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  // Computed (joined) fields for UI display
  final String? patientName;
  final String? staffName;

  const Visit({
    required this.id,
    this.patientId,
    this.visitDate,
    this.vitals,
    this.assessment,
    this.treatment,
    this.notes,
    this.staffId,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.patientName,
    this.staffName,
  });

  Visit copyWith({
    String? id,
    String? patientId,
    DateTime? visitDate,
    String? vitals,
    String? assessment,
    String? treatment,
    String? notes,
    String? staffId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? patientName,
    String? staffName,
  }) {
    return Visit(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      visitDate: visitDate ?? this.visitDate,
      vitals: vitals ?? this.vitals,
      assessment: assessment ?? this.assessment,
      treatment: treatment ?? this.treatment,
      notes: notes ?? this.notes,
      staffId: staffId ?? this.staffId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      patientName: patientName ?? this.patientName,
      staffName: staffName ?? this.staffName,
    );
  }

  factory Visit.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
      return null;
    }

    String? buildPatientName(dynamic patients) {
      if (patients is Map) {
        return getFullName(patients.cast<String, dynamic>());
      }
      return null;
    }

    String? buildStaffName(dynamic profiles) {
      if (profiles is Map) {
        final m = profiles.cast<String, dynamic>();
        final full = (m['full_name'] ?? '').toString().trim();
        return full.isEmpty ? null : full;
      }
      return null;
    }

    return Visit(
      id: (map['id'] ?? '').toString(),
      patientId: map['patient_id']?.toString(),
      visitDate: parseDate(map['visit_date']),
      vitals: map['vitals']?.toString(),
      assessment: map['assessment']?.toString(),
      treatment: map['treatment']?.toString(),
      notes: map['notes']?.toString(),
      staffId: map['staff_id']?.toString(),
      createdAt: parseDate(map['created_at']),
      updatedAt: parseDate(map['updated_at']),
      deletedAt: parseDate(map['deleted_at']),
      patientName: map.containsKey('patients') ? buildPatientName(map['patients']) : map['patient_name']?.toString(),
      staffName: map.containsKey('profiles') ? buildStaffName(map['profiles']) : map['staff_name']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_id': patientId,
      'visit_date': visitDate?.toIso8601String(),
      'vitals': vitals,
      'assessment': assessment,
      'treatment': treatment,
      'notes': notes,
      'staff_id': staffId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}

