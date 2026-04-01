import 'package:intl/intl.dart';

/// Format a large count: 1234567 → "1.2M", 12345 → "12.3K"
String formatCount(int? count) {
  if (count == null) return '0';
  if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
  if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
  return count.toString();
}

/// Human-readable relative time: "2 days ago", "3 weeks ago"
String timeAgo(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} minute${diff.inMinutes == 1 ? '' : 's'} ago';
  if (diff.inHours < 24) return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
  if (diff.inDays < 7) return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
  if (diff.inDays < 30) {
    final w = diff.inDays ~/ 7;
    return '$w week${w == 1 ? '' : 's'} ago';
  }
  if (diff.inDays < 365) {
    final m = diff.inDays ~/ 30;
    return '$m month${m == 1 ? '' : 's'} ago';
  }
  final y = diff.inDays ~/ 365;
  return '$y year${y == 1 ? '' : 's'} ago';
}

/// Full date string: "Apr 1, 2026"
String formatDate(DateTime date) => DateFormat.yMMMd().format(date);
