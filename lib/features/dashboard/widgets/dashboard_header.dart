import 'package:flutter/material.dart';

import '../../../models/app_notification.dart';
import '../../../models/scan_result.dart';
import '../../../screens/scan_details_screen.dart';
import '../../../services/notification_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/oysyn_controls.dart';
import '../../../widgets/oysyn_logo.dart';

class DashboardHeader extends StatefulWidget {
  final int? checksAvailable;
  final bool isOrganizationUser;
  final List<ScanResult> recentResults;

  const DashboardHeader({
    super.key,
    required this.checksAvailable,
    required this.isOrganizationUser,
    this.recentResults = const [],
  });

  @override
  State<DashboardHeader> createState() => _DashboardHeaderState();
}

class _DashboardHeaderState extends State<DashboardHeader> {
  late Future<NotificationFeed> _feed = NotificationService.fetch();
  bool _openingNotifications = false;

  Future<void> _showNotifications() async {
    if (_openingNotifications) return;
    setState(() => _openingNotifications = true);
    try {
      final feed = await NotificationService.fetch();
      await NotificationService.markAllRead();
      if (!mounted) return;
      setState(() {
        _feed = Future.value(NotificationFeed(
          items: feed.items,
          unreadCount: 0,
        ));
      });
      final check = await showModalBottomSheet<ScanResult>(
        context: context,
        useSafeArea: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _NotificationsSheet(items: feed.items),
      );
      if (check == null || !mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ScanDetailsScreen(
            result: check,
            loadFromBackend: true,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _openingNotifications = false);
    }
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
          const SizedBox(width: 8),
          Tooltip(
            message: widget.isOrganizationUser
                ? 'Пользователь организации'
                : 'Частный пользователь',
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: OySynAuthTokens.divider),
              ),
              child: Icon(
                widget.isOrganizationUser
                    ? Icons.business_rounded
                    : Icons.person_outline_rounded,
                size: 17,
                color: OySynAuthTokens.primaryBlue,
              ),
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
          FutureBuilder<NotificationFeed>(
            future: _feed,
            builder: (context, snapshot) {
              final hasUnread = (snapshot.data?.unreadCount ?? 0) > 0;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    onPressed:
                        _openingNotifications ? null : _showNotifications,
                    tooltip: 'Уведомления',
                    icon: _openingNotifications
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.notifications_none_rounded),
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
  final List<AppNotification> items;

  const _NotificationsSheet({required this.items});

  @override
  Widget build(BuildContext context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .72,
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
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
              Padding(
                padding: EdgeInsets.only(
                  bottom: 24 + oysynSystemBottomInset(context),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: OySynAuthTokens.divider),
                  ),
                  child: const Text(
                    'Уведомлений пока нет',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: OySynAuthTokens.textMuted),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  padding: EdgeInsets.only(
                    bottom: 24 + oysynSystemBottomInset(context),
                  ),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: item.check == null
                            ? null
                            : () => Navigator.of(context).pop(item.check),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: OySynAuthTokens.divider,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: (item.failed
                                          ? const Color(0xFFE13F4B)
                                          : const Color(0xFF15945B))
                                      .withValues(alpha: .1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  item.failed
                                      ? Icons.error_outline_rounded
                                      : Icons.task_alt_rounded,
                                  color: item.failed
                                      ? const Color(0xFFE13F4B)
                                      : const Color(0xFF15945B),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      item.body,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: OySynAuthTokens.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (item.check != null) ...[
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: OySynAuthTokens.iconGrey,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      );
}
