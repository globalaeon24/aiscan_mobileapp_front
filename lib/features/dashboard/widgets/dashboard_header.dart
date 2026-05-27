import 'package:flutter/material.dart';

import '../../../storage/token_storage.dart';
import '../../../theme/app_theme.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        border: const Border(
          bottom: BorderSide(color: Color(0xFFE5EAF3)),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF0FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.asset(OySynAuthTokens.logoAsset),
          ),
          const SizedBox(width: 10),
          RichText(
            text: const TextSpan(
              text: 'OySyn',
              style: TextStyle(
                color: OySynAuthTokens.primaryBlue,
                fontSize: 22,
                height: 1,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
              children: [
                TextSpan(
                  text: ' mobile',
                  style: TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F8FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: Color(0xFF18181B),
                size: 23,
              ),
            ),
          ),
          const SizedBox(width: 8),
          FutureBuilder<Map<String, dynamic>?>(
            future: TokenStorage.getUser(),
            builder: (context, snapshot) {
              return CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFEAF0FF),
                child: Text(
                  TokenStorage.initials(snapshot.data),
                  style: const TextStyle(
                    color: OySynAuthTokens.primaryBlue,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
