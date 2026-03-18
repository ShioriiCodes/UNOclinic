// ignore_for_file: avoid_print

String getFullName(Map<String, dynamic>? patient) {
  print('PATIENT RAW: $patient');
  if (patient == null) return 'Unknown';

  final first = (patient['first_name'] ?? '').toString();
  final last = (patient['last_name'] ?? '').toString();
  final full = '$first $last'.trim();
  return full.isEmpty ? 'Unknown' : full;
}

