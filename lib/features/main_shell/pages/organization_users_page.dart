import 'package:flutter/material.dart';

import '../../../services/profile_service.dart';
import '../../../theme/app_theme.dart';

class OrganizationUsersPage extends StatefulWidget {
  final int organizationId;
  final String organizationName;

  const OrganizationUsersPage({
    super.key,
    required this.organizationId,
    required this.organizationName,
  });

  @override
  State<OrganizationUsersPage> createState() => _OrganizationUsersPageState();
}

class _OrganizationUsersPageState extends State<OrganizationUsersPage> {
  late Future<List<Map<String, dynamic>>> _future;
  final _searchController = TextEditingController();
  String? _role;
  bool? _active;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reload() {
    _future = ProfileService.getOrganizationUsers(widget.organizationId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OySynAuthTokens.appBackground,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              organizationName: widget.organizationName,
              onBack: () => Navigator.of(context).pop(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Поиск по ФИО, email, роли...',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _FilterMenu<String?>(
                          value: _role,
                          label: _role == null ? 'Все роли' : _roleLabel(_role),
                          items: const [
                            null,
                            'MOD',
                            'SUP',
                            'EXP',
                            'ADM',
                            'AUT',
                            'DEC'
                          ],
                          itemLabel: (value) =>
                              value == null ? 'Все роли' : _roleLabel(value),
                          onChanged: (value) => setState(() => _role = value),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _FilterMenu<bool?>(
                          value: _active,
                          label: _active == null
                              ? 'Все статусы'
                              : (_active! ? 'Активные' : 'Заблокированные'),
                          items: const [null, true, false],
                          itemLabel: (value) => value == null
                              ? 'Все статусы'
                              : (value ? 'Активные' : 'Заблокированные'),
                          onChanged: (value) => setState(() => _active = value),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return _MessageState(
                      message: 'Не удалось загрузить пользователей',
                      onRetry: () => setState(_reload),
                    );
                  }
                  final users = _filtered(snapshot.data ?? const []);
                  if (users.isEmpty) {
                    return const _MessageState(
                        message: 'Пользователи не найдены');
                  }
                  return RefreshIndicator(
                    onRefresh: () async => setState(_reload),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: users.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) => _UserCard(
                        user: users[index],
                        onView: () => _showUser(users[index]),
                        onEdit: () => _editUser(users[index]),
                        onToggle: () => _toggleUser(users[index]),
                        onDelete: () => _notAvailable('Удаление пользователя'),
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
              color: Colors.white,
              child: Column(
                children: [
                  FilledButton.icon(
                    onPressed: () => _editUser(null),
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    label: const Text('Добавить сотрудника'),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Регистрация сотрудника вручную',
                    style: TextStyle(
                        color: OySynAuthTokens.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _filtered(List<Map<String, dynamic>> users) {
    final query = _searchController.text.trim().toLowerCase();
    return users.where((user) {
      final haystack = [
        user['full_name'],
        user['email'],
        user['role'],
        user['role_display']
      ].whereType<Object>().join(' ').toLowerCase();
      final active = user['is_active'] != false;
      return (query.isEmpty || haystack.contains(query)) &&
          (_role == null || user['role'] == _role) &&
          (_active == null || active == _active);
    }).toList();
  }

  void _showUser(Map<String, dynamic> user) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 4, 22, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_name(user), style: _Styles.title),
            const SizedBox(height: 14),
            _InfoRow('Email', _value(user['email'])),
            _InfoRow('Телефон', _value(user['phone_number'])),
            _InfoRow('Роль', _roleLabel(user['role']?.toString())),
            _InfoRow('Проверок осталось', '${_int(user['checks_available'])}'),
          ],
        ),
      ),
    );
  }

  Future<void> _editUser(Map<String, dynamic>? user) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => _UserEditorDialog(
        organizationId: widget.organizationId,
        user: user,
      ),
    );
    if (saved == true && mounted) setState(_reload);
  }

  Future<void> _toggleUser(Map<String, dynamic> user) async {
    final id = _nullableInt(user['id']);
    if (id == null) return;
    try {
      await ProfileService.updateOrganizationUser(
        widget.organizationId,
        id,
        {'is_active': user['is_active'] == false},
      );
      if (mounted) setState(_reload);
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  void _notAvailable(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('$feature будет доступно после добавления API Core.')),
    );
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Не удалось сохранить: $error')),
    );
  }
}

class _Header extends StatelessWidget {
  final String organizationName;
  final VoidCallback onBack;
  const _Header({required this.organizationName, required this.onBack});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        child: Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                minimumSize: const Size(48, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Организация · $organizationName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _Styles.eyebrow),
                  const Text('Пользователи', style: _Styles.pageTitle),
                ],
              ),
            ),
          ],
        ),
      );
}

class _FilterMenu<T> extends StatelessWidget {
  final T value;
  final String label;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T> onChanged;
  const _FilterMenu(
      {required this.value,
      required this.label,
      required this.items,
      required this.itemLabel,
      required this.onChanged});

  @override
  Widget build(BuildContext context) => PopupMenuButton<T>(
        initialValue: value,
        onSelected: onChanged,
        itemBuilder: (_) => items
            .map((item) =>
                PopupMenuItem<T>(value: item, child: Text(itemLabel(item))))
            .toList(),
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: _Styles.card,
          child: Row(children: [
            Expanded(child: Text(label, style: _Styles.filter)),
            const Icon(Icons.keyboard_arrow_down_rounded,
                color: OySynAuthTokens.textMuted)
          ]),
        ),
      );
}

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  const _UserCard(
      {required this.user,
      required this.onView,
      required this.onEdit,
      required this.onToggle,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final active = user['is_active'] != false;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _Styles.card,
      child: Column(children: [
        Row(children: [
          CircleAvatar(
              radius: 29,
              backgroundColor: const Color(0xFFEFE8FF),
              child: Text(_initials(user),
                  style: const TextStyle(
                      color: Color(0xFF6D4EF0), fontWeight: FontWeight.w800))),
          const SizedBox(width: 13),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(_name(user),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _Styles.title),
                const SizedBox(height: 3),
                Text(_value(user['email']),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _Styles.subtitle)
              ])),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            _StatusBadge(
                label: _roleLabel(user['role']?.toString()),
                color: const Color(0xFF6D4EF0),
                background: const Color(0xFFEFE6FF)),
            const SizedBox(height: 5),
            _StatusBadge(
                label: active ? 'Активен' : 'Заблокирован',
                color:
                    active ? const Color(0xFF168A4C) : const Color(0xFFD83B44),
                background:
                    active ? const Color(0xFFE4F8EE) : const Color(0xFFFFE7E9)),
          ]),
        ]),
        const Divider(height: 24, color: OySynAuthTokens.divider),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          _ActionButton(icon: Icons.visibility_outlined, onTap: onView),
          _ActionButton(
              icon: Icons.edit_outlined,
              color: OySynAuthTokens.primaryBlue,
              onTap: onEdit),
          _ActionButton(
              icon: active ? Icons.block_rounded : Icons.check_rounded,
              color: active ? const Color(0xFFD28A13) : const Color(0xFF168A4C),
              onTap: onToggle),
          _ActionButton(
              icon: Icons.delete_outline_rounded,
              color: const Color(0xFFE13C45),
              onTap: onDelete),
        ]),
      ]),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton(
      {required this.icon,
      required this.onTap,
      this.color = const Color(0xFF61708D)});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 9),
        child: IconButton(
            onPressed: onTap,
            icon: Icon(icon, size: 20),
            color: color,
            style: IconButton.styleFrom(
                side: const BorderSide(color: OySynAuthTokens.divider),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)))),
      );
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;
  const _StatusBadge(
      {required this.label, required this.color, required this.background});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: background, borderRadius: BorderRadius.circular(9)),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w800)));
}

class _UserEditorDialog extends StatefulWidget {
  final int organizationId;
  final Map<String, dynamic>? user;
  const _UserEditorDialog({required this.organizationId, this.user});
  @override
  State<_UserEditorDialog> createState() => _UserEditorDialogState();
}

class _UserEditorDialogState extends State<_UserEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _email;
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _password;
  late String _role;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = widget.user;
    _email = TextEditingController(text: user?['email']?.toString() ?? '');
    _firstName =
        TextEditingController(text: user?['first_name']?.toString() ?? '');
    _lastName =
        TextEditingController(text: user?['last_name']?.toString() ?? '');
    _password = TextEditingController();
    _role = user?['role']?.toString() ?? 'EXP';
  }

  @override
  void dispose() {
    _email.dispose();
    _firstName.dispose();
    _lastName.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final payload = <String, dynamic>{
      'email': _email.text.trim(),
      'first_name': _firstName.text.trim(),
      'last_name': _lastName.text.trim(),
      'role': _role,
      if (_password.text.isNotEmpty) 'password': _password.text,
    };
    try {
      final id = _nullableInt(widget.user?['id']);
      if (id == null) {
        await ProfileService.createOrganizationUser(
            widget.organizationId, payload);
      } else {
        await ProfileService.updateOrganizationUser(
            widget.organizationId, id, payload);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Не удалось сохранить: $error')));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.user == null
            ? 'Добавить сотрудника'
            : 'Редактировать сотрудника'),
        content: SizedBox(
            width: 380,
            child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (value) =>
                          value == null || !value.contains('@')
                              ? 'Укажите email'
                              : null),
                  const SizedBox(height: 10),
                  TextFormField(
                      controller: _firstName,
                      decoration: const InputDecoration(labelText: 'Имя')),
                  const SizedBox(height: 10),
                  TextFormField(
                      controller: _lastName,
                      decoration: const InputDecoration(labelText: 'Фамилия')),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                      initialValue: _role,
                      decoration: const InputDecoration(labelText: 'Роль'),
                      items: const ['MOD', 'SUP', 'EXP', 'ADM', 'AUT', 'DEC']
                          .map((role) => DropdownMenuItem(
                              value: role, child: Text(_roleLabel(role))))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _role = value ?? _role)),
                  const SizedBox(height: 10),
                  TextFormField(
                      controller: _password,
                      obscureText: true,
                      decoration: InputDecoration(
                          labelText: widget.user == null
                              ? 'Пароль'
                              : 'Новый пароль (необязательно)'),
                      validator: (value) => widget.user == null &&
                              (value == null || value.length < 6)
                          ? 'Минимум 6 символов'
                          : null),
                ])))),
        actions: [
          TextButton(
              onPressed: _saving ? null : () => Navigator.of(context).pop(),
              child: const Text('Отмена')),
          FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Сохранение...' : 'Сохранить'))
        ],
      );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(children: [
        Expanded(child: Text(label, style: _Styles.subtitle)),
        Flexible(
            child:
                Text(value, textAlign: TextAlign.right, style: _Styles.filter))
      ]));
}

class _MessageState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const _MessageState({required this.message, this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(message, style: _Styles.subtitle),
        if (onRetry != null) ...[
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Повторить'))
        ]
      ]));
}

class _Styles {
  static const pageTitle = TextStyle(
      color: OySynAuthTokens.textDark,
      fontSize: 24,
      fontWeight: FontWeight.w800);
  static const eyebrow = TextStyle(
      color: OySynAuthTokens.textMuted,
      fontSize: 12,
      fontWeight: FontWeight.w700);
  static const title = TextStyle(
      color: OySynAuthTokens.textDark,
      fontSize: 16,
      fontWeight: FontWeight.w800);
  static const subtitle = TextStyle(
      color: OySynAuthTokens.textMuted,
      fontSize: 13,
      fontWeight: FontWeight.w600);
  static const filter = TextStyle(
      color: Color(0xFF5E6A80), fontSize: 14, fontWeight: FontWeight.w700);
  static final card = BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: OySynAuthTokens.divider));
}

String _name(Map<String, dynamic> user) => _value(
    user['full_name'] ??
        [user['last_name'], user['first_name']].whereType<Object>().join(' '),
    _value(user['email']));
String _initials(Map<String, dynamic> user) {
  final parts = _name(user).split(RegExp(r'\s+'));
  return parts
      .take(2)
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase())
      .join();
}

String _value(dynamic value, [String fallback = 'Не указано']) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? fallback : text;
}

int _int(dynamic value) =>
    value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;
int? _nullableInt(dynamic value) => value == null ? null : _int(value);
String _roleLabel(String? role) => switch (role) {
      'MOD' => 'Модератор',
      'SUP' => 'Супервизор',
      'ADM' => 'Администратор',
      'AUT' => 'Автор',
      'DEC' => 'Деканат',
      _ => 'Эксперт'
    };
