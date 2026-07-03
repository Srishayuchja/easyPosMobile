import 'package:intl/intl.dart';

final _numFmt = NumberFormat('#,###');

String fmtLKR(double n) => _numFmt.format(n.round());

String timeAgo(DateTime dt) {
  final m = DateTime.now().difference(dt).inMinutes;
  if (m < 1) return 'just now';
  if (m < 60) return '${m}m ago';
  final h = m ~/ 60;
  if (h < 24) return '${h}h ago';
  return '${h ~/ 24}d ago';
}

String dayLabel(DateTime dt) {
  final today = DateTime.now();
  final diff = DateTime(today.year, today.month, today.day)
      .difference(DateTime(dt.year, dt.month, dt.day))
      .inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  return DateFormat('E, d MMM').format(dt);
}
