import '../utils/patient_name.dart';

class Referral {
  const Referral({
    required this.id,
    this.patientId,
    this.patientName,
    this.referralDate,
    this.referredTo,
    this.reason,
    this.followUpDue,
    this.status,
    this.followUpNotes,
  });

  final String id;
  final String? patientId;
  final String? patientName;
  final DateTime? referralDate;
  final String? referredTo;
  final String? reason;
  final String? followUpDue;
  final String? status;
  final String? followUpNotes;

  factory Referral.fromMap(Map<String, dynamic> map) {
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

    return Referral(
      id: (map['id'] ?? '').toString(),
      patientId: map['patient_id']?.toString(),
      patientName: parsePatientName(map['patients']) ?? map['patient_name']?.toString(),
      referralDate: parseDate(map['referral_date'] ?? map['created_at']),
      referredTo: map['referred_to']?.toString(),
      reason: map['reason']?.toString(),
      followUpDue: map['follow_up_due']?.toString(),
      status: map['status']?.toString(),
      followUpNotes: map['follow_up_notes']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_id': patientId,
      'referral_date': referralDate?.toIso8601String(),
      'referred_to': referredTo,
      'reason': reason,
      'follow_up_due': followUpDue,
      'status': status,
      'follow_up_notes': followUpNotes,
    };
  }
}

