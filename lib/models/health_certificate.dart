import '../utils/patient_name.dart';

class HealthCertificate {
  const HealthCertificate({
    required this.id,
    this.patientId,
    this.patientName,
    this.requestDate,
    this.purpose,
    this.status,
    this.releasedDate,
  });

  final String id;
  final String? patientId;
  final String? patientName;
  final DateTime? requestDate;
  final String? purpose;
  final String? status;
  final DateTime? releasedDate;

  factory HealthCertificate.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
      return null;
    }

    String? parsePatientName(dynamic patients) {
      if (patients is List && patients.isNotEmpty) {
        return parsePatientName(patients.first);
      }
      if (patients is Map) {
        return getFullName(patients.cast<String, dynamic>());
      }
      return null;
    }

    return HealthCertificate(
      id: (map['id'] ?? '').toString(),
      patientId: map['patient_id']?.toString(),
      patientName: parsePatientName(map['patients']) ?? map['patient_name']?.toString(),
      requestDate: parseDate(map['request_date'] ?? map['created_at']),
      purpose: map['purpose']?.toString(),
      status: map['status']?.toString(),
      releasedDate: parseDate(map['released_date'] ?? map['released_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_id': patientId,
      'purpose': purpose,
      'status': status,
      'request_date': requestDate?.toIso8601String(),
      'released_date': releasedDate?.toIso8601String(),
    };
  }
}

