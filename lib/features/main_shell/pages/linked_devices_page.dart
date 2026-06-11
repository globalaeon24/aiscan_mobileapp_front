import 'package:flutter/material.dart';

import '../../../models/linked_device_session.dart';
import '../../../services/linked_devices_service.dart';
import '../../../theme/app_theme.dart';

class LinkedDevicesPage extends StatefulWidget {
  const LinkedDevicesPage({super.key});

  @override
  State<LinkedDevicesPage> createState() => _LinkedDevicesPageState();
}

class _LinkedDevicesPageState extends State<LinkedDevicesPage> {
  late Future<List<LinkedDeviceSession>> _devicesFuture;

  @override
  void initState() {
    super.initState();
    _devicesFuture = LinkedDevicesService.fetchDevices();
  }

  void _reload() {
    setState(() {
      _devicesFuture = LinkedDevicesService.fetchDevices();
    });
  }

  Future<void> _openDetails(LinkedDeviceSession session) async {
    final revoked = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => LinkedDeviceDetailsPage(session: session),
      ),
    );

    if (revoked == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OySynAuthTokens.appBackground,
      appBar: AppBar(
        title: const Text(
          'Связанные устройства',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: () async => _reload(),
        child: FutureBuilder<List<LinkedDeviceSession>>(
          future: _devicesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _LinkedDevicesLoading();
            }

            if (snapshot.hasError) {
              return _LinkedDevicesMessage(
                icon: Icons.wifi_off_rounded,
                title: 'Не удалось загрузить устройства',
                message:
                    snapshot.error.toString().replaceFirst('Exception: ', ''),
                action: OutlinedButton.icon(
                  onPressed: _reload,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Повторить'),
                ),
              );
            }

            final devices = snapshot.data ?? const <LinkedDeviceSession>[];
            if (devices.isEmpty) {
              return const _LinkedDevicesMessage(
                icon: Icons.devices_other_rounded,
                title: 'Нет связанных устройств',
                message:
                    'Активные веб-сессии появятся здесь после входа через QR.',
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                const _LinkedDevicesHeader(),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < devices.length; i++) ...[
                        _LinkedDeviceTile(
                          session: devices[i],
                          onTap: () => _openDetails(devices[i]),
                        ),
                        if (i != devices.length - 1)
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: OySynAuthTokens.divider,
                            indent: 74,
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class LinkedDeviceDetailsPage extends StatefulWidget {
  final LinkedDeviceSession session;

  const LinkedDeviceDetailsPage({super.key, required this.session});

  @override
  State<LinkedDeviceDetailsPage> createState() =>
      _LinkedDeviceDetailsPageState();
}

class _LinkedDeviceDetailsPageState extends State<LinkedDeviceDetailsPage> {
  bool _revoking = false;

  Future<void> _revoke() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отключить устройство?'),
        content: Text(
          '${widget.session.title} будет отключен от вашей учетной записи.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Отключить'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _revoking = true);
    try {
      await LinkedDevicesService.revokeDevice(widget.session.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Устройство отключено')),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _revoking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;

    return Scaffold(
      backgroundColor: OySynAuthTokens.appBackground,
      appBar: AppBar(
        title: const Text(
          'Устройство',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 26, 20, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEAF0FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.laptop_mac_rounded,
                    color: OySynAuthTokens.primaryBlue,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  session.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: OySynAuthTokens.textDark,
                    fontSize: 21,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  session.subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: OySynAuthTokens.textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _DetailRow(
                  icon: Icons.language_rounded,
                  label: 'Программа',
                  value: _fallback(session.softwareLabel, 'Не определено'),
                ),
                const _DetailDivider(),
                _DetailRow(
                  icon: Icons.devices_rounded,
                  label: 'Тип устройства',
                  value: session.deviceTypeLabel,
                ),
                const _DetailDivider(),
                _DetailRow(
                  icon: Icons.desktop_mac_rounded,
                  label: 'Операционная система',
                  value: _fallback(session.osLabel, 'Не определено'),
                ),
                const _DetailDivider(),
                _DetailRow(
                  icon: Icons.schedule_rounded,
                  label: 'Последняя активность',
                  value: _friendlyDate(session.lastActiveAt),
                ),
                const _DetailDivider(),
                _DetailRow(
                  icon: Icons.login_rounded,
                  label: 'Вход выполнен',
                  value: _friendlyDate(session.firstSeenAt),
                ),
                const _DetailDivider(),
                _DetailRow(
                  icon: Icons.place_outlined,
                  label: 'Место входа',
                  value: session.location ?? 'Не определено',
                ),
                const _DetailDivider(),
                _DetailRow(
                  icon: Icons.public_rounded,
                  label: 'IP-адрес',
                  value: session.ipAddress ?? 'Не определен',
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 54,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              onPressed: _revoking || !session.isActive ? null : _revoke,
              icon: _revoking
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.link_off_rounded),
              label:
                  Text(session.isActive ? 'Отключить устройство' : 'Отключено'),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkedDevicesHeader extends StatelessWidget {
  const _LinkedDevicesHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.phonelink_lock_rounded,
            color: OySynAuthTokens.primaryBlue,
            size: 30,
          ),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'Проверьте, где открыт ваш аккаунт. Незнакомые устройства можно отключить в один шаг.',
              style: TextStyle(
                color: OySynAuthTokens.textMuted,
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkedDeviceTile extends StatelessWidget {
  final LinkedDeviceSession session;
  final VoidCallback onTap;

  const _LinkedDeviceTile({
    required this.session,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      minVerticalPadding: 14,
      contentPadding: const EdgeInsets.fromLTRB(16, 8, 10, 8),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFEAF0FF),
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Icon(
          Icons.laptop_mac_rounded,
          color: OySynAuthTokens.primaryBlue,
          size: 24,
        ),
      ),
      title: Text(
        session.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: OySynAuthTokens.textDark,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          '${session.subtitle}\n${_activityText(session)}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: OySynAuthTokens.textMuted,
            fontSize: 13,
            height: 1.25,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: OySynAuthTokens.iconGrey,
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: OySynAuthTokens.iconGrey, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: OySynAuthTokens.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: OySynAuthTokens.textDark,
                    fontSize: 15,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailDivider extends StatelessWidget {
  const _DetailDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      color: OySynAuthTokens.divider,
      indent: 52,
    );
  }
}

class _LinkedDevicesLoading extends StatelessWidget {
  const _LinkedDevicesLoading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        for (var i = 0; i < 4; i++) ...[
          Container(
            height: i == 0 ? 84 : 72,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(child: CircularProgressIndicator()),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _LinkedDevicesMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const _LinkedDevicesMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 28),
      children: [
        Icon(icon, color: OySynAuthTokens.iconGrey, size: 54),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: OySynAuthTokens.textDark,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: OySynAuthTokens.textMuted,
            fontSize: 14,
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (action != null) ...[
          const SizedBox(height: 18),
          Center(child: action),
        ],
      ],
    );
  }
}

String _activityText(LinkedDeviceSession session) {
  if (!session.isActive) return 'Отключено';
  final date = session.lastActiveAt;
  if (date == null) return 'Активно сейчас';
  return 'Активно: ${_friendlyDate(date)}';
}

String _fallback(String value, String fallback) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? fallback : trimmed;
}

String _friendlyDate(DateTime? value) {
  if (value == null) return 'Неизвестно';

  final now = DateTime.now();
  final difference = now.difference(value);
  if (difference.inMinutes < 1) return 'только что';
  if (difference.inMinutes < 60) {
    return '${difference.inMinutes} мин назад';
  }
  if (difference.inHours < 24 && _sameDay(now, value)) {
    return 'сегодня, ${_two(value.hour)}:${_two(value.minute)}';
  }
  if (difference.inHours < 48 &&
      _sameDay(now.subtract(const Duration(days: 1)), value)) {
    return 'вчера, ${_two(value.hour)}:${_two(value.minute)}';
  }
  return '${_two(value.day)}.${_two(value.month)}.${value.year}, ${_two(value.hour)}:${_two(value.minute)}';
}

bool _sameDay(DateTime left, DateTime right) {
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}

String _two(int value) => value.toString().padLeft(2, '0');
