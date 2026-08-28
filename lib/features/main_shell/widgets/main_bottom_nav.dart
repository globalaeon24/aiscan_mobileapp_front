import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class MainBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const MainBottomNav({
    super.key,
    required this.currentIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
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
            _NavItem(
              index: 2,
              selectedIndex: currentIndex,
              icon: Icons.add_rounded,
              selectedIcon: Icons.add_rounded,
              label: 'Проверить',
              center: true,
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
  final bool center;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.index,
    required this.selectedIndex,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.onTap,
    this.center = false,
  });

  @override
  Widget build(BuildContext context) {
    final selected = index == selectedIndex;
    final color =
        selected ? OySynAuthTokens.primaryBlue : const Color(0xFF6F7B84);

    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        child: Transform.translate(
          offset: center ? const Offset(0, -10) : Offset.zero,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (center)
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF3E7BFF), Color(0xFF2F5FE0)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color:
                            OySynAuthTokens.primaryBlue.withValues(alpha: 0.18),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    selected ? selectedIcon : icon,
                    color: Colors.white,
                    size: 27,
                  ),
                )
              else
                Container(
                  width: 42,
                  height: 32,
                  decoration: BoxDecoration(
                    color:
                        selected ? const Color(0xFFEAF0FF) : Colors.transparent,
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
                  fontSize: center ? 10.5 : 11,
                  height: 1,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
