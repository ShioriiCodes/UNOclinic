// ignore_for_file: unused_element
// Mock data for UNOclinic UI — no backend. All in-memory.

class MockPatient {
  final String id;
  final String schoolId;
  final String name;
  final String type; // Student, Faculty, Staff
  final String department;
  final DateTime? lastVisit;

  MockPatient({
    required this.id,
    required this.schoolId,
    required this.name,
    required this.type,
    required this.department,
    this.lastVisit,
  });
}

class MockVisit {
  final String id;
  final String patientId;
  final String patientName;
  final DateTime dateTime;
  final String complaint;
  final String handledBy;
  final String? vitals;
  final String? assessment;
  final String? treatment;
  final String? notes;

  MockVisit({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.dateTime,
    required this.complaint,
    required this.handledBy,
    this.vitals,
    this.assessment,
    this.treatment,
    this.notes,
  });
}

class MockCertificate {
  final String id;
  final String patientId;
  final String patientName;
  final DateTime requestDate;
  final String purpose;
  final String status; // Pending, Approved, Released
  final DateTime? releasedDate;

  MockCertificate({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.requestDate,
    required this.purpose,
    required this.status,
    this.releasedDate,
  });
}

class MockReferral {
  final String id;
  final String patientId;
  final String patientName;
  final DateTime referralDate;
  final String referredTo;
  final String reason;
  final String? followUpDue;
  final String status; // Pending, Completed
  final String? followUpNotes;

  MockReferral({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.referralDate,
    required this.referredTo,
    required this.reason,
    this.followUpDue,
    required this.status,
    this.followUpNotes,
  });
}

class MockInventoryItem {
  final String id;
  final String name;
  final String category;
  final int totalStock;
  final int threshold;

  MockInventoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.totalStock,
    required this.threshold,
  });
}

class MockBatch {
  final String id;
  final String itemId;
  final String itemName;
  final String batchNo;
  final DateTime expiryDate;
  final int qtyAvailable;
  final String status; // OK, Near Expiry, Expired

  MockBatch({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.batchNo,
    required this.expiryDate,
    required this.qtyAvailable,
    required this.status,
  });
}

class MockTransaction {
  final String id;
  final String itemName;
  final String type; // Receive, Dispense, Adjust
  final int qty;
  final DateTime date;
  final String? notes;

  MockTransaction({
    required this.id,
    required this.itemName,
    required this.type,
    required this.qty,
    required this.date,
    this.notes,
  });
}

class MockActivity {
  final String id;
  final String description;
  final DateTime time;
  final String type; // visit, certificate, referral, etc.

  MockActivity({required this.id, required this.description, required this.time, required this.type});
}

class MockAlert {
  final String id;
  final String title;
  final String message;
  final String severity; // low, medium, high

  MockAlert({required this.id, required this.title, required this.message, required this.severity});
}

class MockUser {
  final String id;
  final String name;
  final String role;
  final String email;

  MockUser({required this.id, required this.name, required this.role, required this.email});
}

class MockAuditEntry {
  final String id;
  final String action;
  final String user;
  final DateTime time;

  MockAuditEntry({required this.id, required this.action, required this.user, required this.time});
}

final List<MockPatient> mockPatients = [
  MockPatient(id: 'p1', schoolId: '2021-001234', name: 'Juan Dela Cruz', type: 'Student', department: 'CCS', lastVisit: DateTime.now().subtract(const Duration(days: 2))),
  MockPatient(id: 'p2', schoolId: '2020-005678', name: 'Maria Santos', type: 'Student', department: 'COE', lastVisit: DateTime.now().subtract(const Duration(days: 5))),
  MockPatient(id: 'p3', schoolId: 'F-2022-001', name: 'Dr. Ana Reyes', type: 'Faculty', department: 'CCS', lastVisit: DateTime.now().subtract(const Duration(days: 10))),
  MockPatient(id: 'p4', schoolId: 'S-2019-002', name: 'Pedro Garcia', type: 'Staff', department: 'Admin', lastVisit: DateTime.now().subtract(const Duration(days: 1))),
  MockPatient(id: 'p5', schoolId: '2022-009876', name: 'Lisa Mendoza', type: 'Student', department: 'CABE', lastVisit: null),
];

final List<MockVisit> mockVisits = [
  MockVisit(id: 'v1', patientId: 'p1', patientName: 'Juan Dela Cruz', dateTime: DateTime.now(), complaint: 'Fever, cough', handledBy: 'Dr. Cruz', vitals: 'BP 120/80, Temp 37.2', assessment: 'URTI', treatment: 'Paracetamol, rest', notes: 'Follow-up in 3 days'),
  MockVisit(id: 'v2', patientId: 'p4', patientName: 'Pedro Garcia', dateTime: DateTime.now().subtract(const Duration(days: 1)), complaint: 'Headache', handledBy: 'Nurse Santos', vitals: 'BP 118/78', assessment: 'Tension headache', treatment: 'Pain reliever', notes: null),
  MockVisit(id: 'v3', patientId: 'p2', patientName: 'Maria Santos', dateTime: DateTime.now().subtract(const Duration(days: 3)), complaint: 'Allergy', handledBy: 'Dr. Cruz', vitals: 'Normal', assessment: 'Allergic rhinitis', treatment: 'Antihistamine', notes: null),
];

final List<MockCertificate> mockCertificates = [
  MockCertificate(id: 'c1', patientId: 'p1', patientName: 'Juan Dela Cruz', requestDate: DateTime.now().subtract(const Duration(days: 1)), purpose: 'Enrollment', status: 'Pending', releasedDate: null),
  MockCertificate(id: 'c2', patientId: 'p2', patientName: 'Maria Santos', requestDate: DateTime.now().subtract(const Duration(days: 3)), purpose: 'Sports', status: 'Released', releasedDate: DateTime.now().subtract(const Duration(days: 2))),
  MockCertificate(id: 'c3', patientId: 'p3', patientName: 'Dr. Ana Reyes', requestDate: DateTime.now().subtract(const Duration(days: 5)), purpose: 'Travel', status: 'Approved', releasedDate: null),
];

final List<MockReferral> mockReferrals = [
  MockReferral(id: 'r1', patientId: 'p1', patientName: 'Juan Dela Cruz', referralDate: DateTime.now().subtract(const Duration(days: 2)), referredTo: 'Quezon Memorial Hospital', reason: 'Chest X-ray', followUpDue: '2025-03-01', status: 'Pending', followUpNotes: null),
  MockReferral(id: 'r2', patientId: 'p2', patientName: 'Maria Santos', referralDate: DateTime.now().subtract(const Duration(days: 10)), referredTo: 'Eye Center', reason: 'Vision check', followUpDue: null, status: 'Completed', followUpNotes: 'Done'),
];

final List<MockInventoryItem> mockInventoryItems = [
  MockInventoryItem(id: 'i1', name: 'Paracetamol 500mg', category: 'Medication', totalStock: 45, threshold: 50),
  MockInventoryItem(id: 'i2', name: 'Cotton Balls', category: 'Supplies', totalStock: 200, threshold: 100),
  MockInventoryItem(id: 'i3', name: 'Betadine', category: 'Medication', totalStock: 8, threshold: 10),
  MockInventoryItem(id: 'i4', name: 'Face Masks (box)', category: 'PPE', totalStock: 15, threshold: 20),
];

final List<MockBatch> mockBatches = [
  MockBatch(id: 'b1', itemId: 'i1', itemName: 'Paracetamol 500mg', batchNo: 'B2024-001', expiryDate: DateTime.now().add(const Duration(days: 180)), qtyAvailable: 45, status: 'OK'),
  MockBatch(id: 'b2', itemId: 'i3', itemName: 'Betadine', batchNo: 'B2024-002', expiryDate: DateTime.now().add(const Duration(days: 25)), qtyAvailable: 8, status: 'Near Expiry'),
  MockBatch(id: 'b3', itemId: 'i4', itemName: 'Face Masks (box)', batchNo: 'B2023-010', expiryDate: DateTime.now().subtract(const Duration(days: 5)), qtyAvailable: 5, status: 'Expired'),
];

final List<MockTransaction> mockTransactions = [
  MockTransaction(id: 't1', itemName: 'Paracetamol 500mg', type: 'Dispense', qty: -10, date: DateTime.now(), notes: 'Visit v1'),
  MockTransaction(id: 't2', itemName: 'Cotton Balls', type: 'Receive', qty: 50, date: DateTime.now().subtract(const Duration(days: 1)), notes: 'Restock'),
];

final List<MockActivity> mockDashboardActivity = [
  MockActivity(id: 'a1', description: 'Juan Dela Cruz — Visit (Fever, cough)', time: DateTime.now(), type: 'visit'),
  MockActivity(id: 'a2', description: 'Health certificate released — Maria Santos', time: DateTime.now().subtract(const Duration(hours: 2)), type: 'certificate'),
  MockActivity(id: 'a3', description: 'Referral created — Juan Dela Cruz to QMH', time: DateTime.now().subtract(const Duration(days: 1)), type: 'referral'),
  MockActivity(id: 'a4', description: 'Stock received — Cotton Balls +50', time: DateTime.now().subtract(const Duration(days: 1)), type: 'inventory'),
];

final List<MockAlert> mockDashboardAlerts = [
  MockAlert(id: 'al1', title: 'Low stock', message: 'Paracetamol 500mg (45 left, threshold 50)', severity: 'medium'),
  MockAlert(id: 'al2', title: 'Near expiry (30 days)', message: 'Betadine batch B2024-002', severity: 'high'),
  MockAlert(id: 'al3', title: 'Follow-up due', message: 'Juan Dela Cruz — referral follow-up 2025-03-01', severity: 'medium'),
];

final List<MockUser> mockUsers = [
  MockUser(id: 'u1', name: 'Admin User', role: 'Admin', email: 'admin@psu.edu.ph'),
  MockUser(id: 'u2', name: 'Nurse Santos', role: 'Staff', email: 'nurse@psu.edu.ph'),
];

final List<MockAuditEntry> mockAuditLog = [
  MockAuditEntry(id: 'au1', action: 'Login', user: 'Admin User', time: DateTime.now()),
  MockAuditEntry(id: 'au2', action: 'Released certificate c2', user: 'Nurse Santos', time: DateTime.now().subtract(const Duration(hours: 1))),
  MockAuditEntry(id: 'au3', action: 'Created referral r1', user: 'Dr. Cruz', time: DateTime.now().subtract(const Duration(days: 1))),
];

// Dashboard KPIs (computed from mock data for UI)
int get todayVisitsCount => mockVisits.where((v) => _isToday(v.dateTime)).length;
int get pendingCertificatesCount => mockCertificates.where((c) => c.status == 'Pending').length;
int get pendingReferralsCount => mockReferrals.where((r) => r.status == 'Pending').length;
int get lowStockCount => mockInventoryItems.where((i) => i.totalStock <= i.threshold).length;
int get nearExpiryCount => mockBatches.where((b) => b.status == 'Near Expiry' || b.status == 'Expired').length;

bool _isToday(DateTime d) {
  final n = DateTime.now();
  return d.year == n.year && d.month == n.month && d.day == n.day;
}

final List<String> mockDepartments = ['CCS', 'COE', 'CABE', 'Admin', 'All'];
final List<String> mockReportTypes = ['Visits Summary', 'Certificates Issued', 'Referrals', 'Inventory Report', 'Patient Demographics'];
