import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class MainBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;
  final bool showOrganization;

  const MainBottomNav({
    super.key,
    required this.currentIndex,
    required this.onChanged,
    required this.showOrganization,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 4),
      child: Container(
        height: 76,
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
            top: BorderSide(color: Color(0xFFE5EAF3), width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.06),
              blurRadius: 24,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: Row(
          children: [
            _NavItem(
              index: 0,
              selectedIndex: currentIndex,
              icon: Icons.home_outlined,
              selectedIcon: Icons.home_rounded,
              label: 'Главная',
              onTap: onChanged,
            ),
            _NavItem(
              index: 1,
              selectedIndex: currentIndex,
              icon: Icons.description_outlined,
              selectedIcon: Icons.description_rounded,
              label: 'Документы',
              onTap: onChanged,
            ),
            if (showOrganization)
              _NavItem(
                index: 2,
                selectedIndex: currentIndex,
                icon: Icons.business_outlined,
                selectedIcon: Icons.business_rounded,
                label: 'Организация',
                onTap: onChanged,
              ),
            _NavItem(
              index: 3,
              selectedIndex: currentIndex,
              icon: Icons.qr_code_2_rounded,
              selectedIcon: Icons.qr_code_2_rounded,
              label: 'OySyn QR',
              onTap: onChanged,
            ),
            _NavItem(
              index: 4,
              selectedIndex: currentIndex,
              icon: Icons.person_outline_rounded,
              selectedIcon: Icons.person_rounded,
              label: 'Профиль',
              onTap: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final int selectedIndex;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.index,
    required this.selectedIndex,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = index == selectedIndex;
    final color =
        selected ? OySynAuthTokens.primaryBlue : const Color(0xFF6F7B84);

    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 32,
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFEAF0FF) : Colors.transparent,
                border: selected
                    ? Border.all(color: const Color(0xFFDCE7FF))
                    : null,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(
                selected ? selectedIcon : icon,
                color: color,
                size: 23,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
                height: 1,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
