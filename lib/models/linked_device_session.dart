class LinkedDeviceSession {
  final int id;
  final String deviceName;
  final String? browser;
  final String? browserVersion;
  final String? platform;
  final String? osVersion;
  final String? deviceType;
  final String? location;
  final String? ipAddress;
  final String? userAgent;
  final String status;
  final DateTime? firstSeenAt;
  final DateTime? lastActiveAt;
  final DateTime? revokedAt;

  const LinkedDeviceSession({
    required this.id,
    required this.deviceName,
    required this.status,
    this.browser,
    this.browserVersion,
    this.platform,
    this.osVersion,
    this.deviceType,
    this.location,
    this.ipAddress,
    this.userAgent,
    this.firstSeenAt,
    this.lastActiveAt,
    this.revokedAt,
  });

  bool get isActive => status.toLowerCase() == 'active' && revokedAt == null;

  String get title {
    final value = deviceName.trim();
    if (value.isNotEmpty) return value;
    if (browser != null && browser!.trim().isNotEmpty) return browser!.trim();
    return deviceType == 'mobile' || deviceType == 'tablet'
        ? 'Мобильное устройство'
        : 'Веб-браузер';
  }

  String get subtitle {
    final parts = [
      softwareLabel,
      osLabel,
    ];
    final visible = parts.where((part) => part.trim().isNotEmpty).toList();
    if (visible.isNotEmpty) return visible.join(' • ');
    return isActive ? 'Активная сессия' : 'Сессия отключена';
  }

  String get softwareLabel {
    final name = browser?.trim();
    if (name == null || name.isEmpty) return '';
    final version = browserVersion?.trim();
    if (version == null || version.isEmpty) return name;
    return '$name ${_majorVersion(version)}';
  }

  String get osLabel {
    final name = platform?.trim();
    if (name == null || name.isEmpty) return '';
    final version = osVersion?.trim();
    if (version == null || version.isEmpty) return name;
    return '$name $version';
  }

  String get deviceTypeLabel {
    return switch (deviceType?.toLowerCase().trim()) {
      'mobile' => 'Телефон',
      'tablet' => 'Планшет',
      'desktop' => 'Компьютер',
      _ => 'Устройство',
    };
  }

  factory LinkedDeviceSession.fromJson(Map<String, dynamic> json) {
    final rawId =
        json['id'] ?? json['core_session_id'] ?? json['session_id'] ?? 0;

    return LinkedDeviceSession(
      id: rawId is int ? rawId : int.tryParse(rawId.toString()) ?? 0,
      deviceName: _text(json['device_name'] ?? json['device']) ?? '',
      browser: _text(json['browser']),
      browserVersion: _text(json['browser_version']),
      platform: _text(json['platform']),
      osVersion: _text(json['os_version']),
      deviceType: _text(json['device_type']),
      location: _text(json['location']),
      ipAddress: _text(json['ip_address'] ?? json['ip']),
      userAgent: _text(json['user_agent']),
      status: _text(json['status']) ?? 'active',
      firstSeenAt: _date(json['first_seen_at'] ?? json['created_at']),
      lastActiveAt: _date(json['last_active_at'] ?? json['last_activity']),
      revokedAt: _date(json['revoked_at']),
    );
  }

  static String? _text(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static DateTime? _date(dynamic value) {
    if (value is DateTime) return value.toLocal();
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return DateTime.tryParse(text)?.toLocal();
  }

  static String _majorVersion(String version) {
    final parts = version.split('.');
    return parts.isEmpty ? version : parts.first;
  }
}
