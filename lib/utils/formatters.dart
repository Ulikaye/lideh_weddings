import 'package:intl/intl.dart';

String formatMoney(num? n) {
  final formatter = NumberFormat.decimalPattern('en_US');
  return 'TZS ${formatter.format(n ?? 0)}';
}

String formatDateIso(String? iso) {
  if (iso == null || iso.isEmpty) return '—';
  try {
    final dt = DateTime.parse(iso);
    return DateFormat('d MMMM yyyy', 'en_GB').format(dt);
  } catch (_) {
    return iso;
  }
}

String todayIso() => DateTime.now().toIso8601String().substring(0, 10);
