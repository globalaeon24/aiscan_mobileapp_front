import 'package:flutter/material.dart';

import '../../../storage/token_storage.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/oysyn_logo.dart';
import '../../../models/scan_result.dart';
import '../models/dashboard_document.dart';

class DashboardHeader extends StatefulWidget {
  final int? checksAvailable;
  final List<ScanResult> recentResults;

  const DashboardHeader({
    super.key,
    required this.checksAvailable,
    this.recentResults = const [],
  });

  @override
  State<DashboardHeader> createState() => _DashboardHeaderState();
}

class _DashboardHeaderState extends State<DashboardHeader> {
  late Future<DateTime?> _readAt = TokenStorage.getNotificationsReadAt();

  List<ScanResult> get _notifications => widget.recentResults
      .where((item) => const {'CH', 'FA'}.contains(item.status))
      .take(3)
      .toList();

  Future<void> _showNotifications() async {
    await TokenStorage.markNotificationsRead();
    if (mounted) setState(() => _readAt = Future.value(DateTime.now().toUtc()));
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NotificationsSheet(items: _notifications),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF3E7BFF), Color(0xFF2F5FE0)],
              ),
            ),
            padding: const EdgeInsets.all(4),
            child: const OySynLogo(size: 30),
          ),
          const SizedBox(width: 8),
          const Text(
            'OySyn',
            style: TextStyle(
              color: Color(0xFF2B4CC0),
              fontSize: 18,
              height: 1,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF0FF),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 14,
                  color: Color(0xFF2B5CE0),
                ),
                const SizedBox(width: 5),
                Text(
                  widget.checksAvailable?.toString() ?? '—',
                  style: const TextStyle(
                    color: Color(0xFF2B5CE0),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FutureBuilder<DateTime?>(
            future: _readAt,
            builder: (context, snapshot) {
              final readAt = snapshot.data;
              final hasUnread = _notifications.any(
                (item) => readAt == null || item.createdAt.isAfter(readAt),
              );
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    onPressed: _showNotifications,
                    tooltip: 'Уведомления',
                    icon: const Icon(Icons.notifications_none_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: OySynAuthTokens.divider),
                    ),
                  ),
                  if (hasUnread)
                    Positioned(
                      right: 2,
                      top: 1,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE13F4B),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _NotificationsSheet extends StatelessWidget {
  final List<ScanResult> items;

  const _NotificationsSheet({required this.items});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(
          color: OySynAuthTokens.appBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
                child: SizedBox(width: 42, child: Divider(thickness: 4))),
            const SizedBox(height: 10),
            const Text('Уведомления', style: OySynTextStyles.sectionTitle),
            const SizedBox(height: 12),
            if (items.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: OySynAuthTokens.divider),
                ),
                child: const Text(
                  'Новых уведомлений пока нет',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: OySynAuthTokens.textMuted),
                ),
              )
            else
              ...items.map((result) {
                final document = DashboardDocument.fromScanResult(result);
                final failed = result.status == 'FA';
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: OySynAuthTokens.divider),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        failed
                            ? Icons.error_outline_rounded
                            : Icons.task_alt_rounded,
                        color: failed
                            ? const Color(0xFFE13F4B)
                            : const Color(0xFF15945B),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              failed
                                  ? 'Проверка завершилась с ошибкой'
                                  : 'Проверка завершена',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              document.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: OySynAuthTokens.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      );
}
