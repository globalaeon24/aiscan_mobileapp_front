import '../../../models/scan_result.dart';

class DocumentListFilter {
  const DocumentListFilter._();

  static List<ScanResult> apply({
    required List<ScanResult> items,
    required String query,
    required String? status,
    required Duration? period,
    required bool newestFirst,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final from = period == null
        ? null
        : DateTime(current.year, current.month, current.day).subtract(
            Duration(days: period.inDays > 0 ? period.inDays - 1 : 0),
          );
    final normalizedQuery = query.trim().toLowerCase();
    final normalizedStatus = status?.trim().toUpperCase();

    final filtered = items.where((item) {
      final matchesPeriod = from == null || !item.createdAt.isBefore(from);
      final matchesStatus = normalizedStatus == null ||
          normalizedStatus.isEmpty ||
          item.status?.trim().toUpperCase() == normalizedStatus;
      final haystack = [
        item.title,
        item.fileName,
        item.authorName,
        item.documentType,
      ].whereType<String>().join(' ').toLowerCase();
      final matchesSearch =
          normalizedQuery.isEmpty || haystack.contains(normalizedQuery);
      return matchesPeriod && matchesStatus && matchesSearch;
    }).toList();

    filtered.sort((a, b) => newestFirst
        ? b.createdAt.compareTo(a.createdAt)
        : a.createdAt.compareTo(b.createdAt));
    return filtered;
  }

  static List<ScanResult> page({
    required List<ScanResult> items,
    required int page,
    required int pageSize,
  }) {
    if (items.isEmpty || pageSize <= 0) return const [];
    final totalPages = (items.length / pageSize).ceil();
    final safePage = page.clamp(1, totalPages);
    return items.skip((safePage - 1) * pageSize).take(pageSize).toList();
  }
}
