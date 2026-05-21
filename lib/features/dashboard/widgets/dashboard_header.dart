import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../data/demo_dashboard_data.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: Colors.white,
      child: Row(
        children: [
          Image.asset(
            OySynAuthTokens.logoAsset,
            width: 34,
            height: 34,
          ),
          const SizedBox(width: 8),
          const Text(
            'OySyn',
            style: TextStyle(
              color: OySynAuthTokens.primaryBlue,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Color(0xFF18181B),
              size: 25,
            ),
          ),
          const SizedBox(width: 8),
          const CircleAvatar(
            radius: 20,
            backgroundColor: Color(0xFFEAF0FF),
            child: Text(
              DemoDashboardData.userInitials,
              style: TextStyle(
                color: OySynAuthTokens.primaryBlue,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
