import 'package:intl/intl.dart';

/// Pure Dart formatting and utility functions (no Flutter widget dependencies)

/// Formats DateTime into readable Indonesian date string
/// e.g. '11 Okt 2026, 23:30'
String formatNoteDate(DateTime date) {
  try {
    final formatter = DateFormat('dd MMM yyyy, HH:mm');
    return formatter.format(date);
  } catch (_) {
    // Fallback if locale data is not loaded
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    final h = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return '$d/$m/$y, $h:$min';
  }
}

/// Formats DateTime into relative time label for UI display
String formatRelativeTime(DateTime date, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final difference = current.difference(date);

  if (difference.inSeconds < 60) {
    return 'Baru saja';
  } else if (difference.inMinutes < 60) {
    return '${difference.inMinutes} menit lalu';
  } else if (difference.inHours < 24 && current.day == date.day) {
    final h = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return 'Hari ini, $h:$min';
  } else if (difference.inDays == 1 ||
      (difference.inHours < 48 && current.day - date.day == 1)) {
    final h = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return 'Kemarin, $h:$min';
  } else {
    return formatNoteDate(date);
  }
}

/// Safely parses an integer ID from route URL parameters
int? parseRouteId(String? idParam) {
  if (idParam == null || idParam.trim().isEmpty) return null;
  return int.tryParse(idParam.trim());
}

/// Sanitizes user input text (trims whitespace and collapses multiple newlines)
String sanitizeText(String text) {
  return text.trim().replaceAll(RegExp(r'\n{3,}'), '\n\n');
}
