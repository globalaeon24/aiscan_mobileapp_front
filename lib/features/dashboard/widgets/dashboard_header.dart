import 'package:flutter/material.dart';

import '../../../storage/token_storage.dart';
import '../../../theme/app_theme.dart';

class DashboardHeader extends StatelessWidget {
  final int checksAvailable;

  const DashboardHeader({
    super.key,
    required this.checksAvailable,
  });

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
            child: Image.asset(OySynAuthTokens.logoAsset),
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
                  '$checksAvailable',
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
          FutureBuilder<Map<String, dynamic>?>(
            future: TokenStorage.getUser(),
            builder: (context, snapshot) {
              return CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF2F5FE0),
                child: Text(
                  TokenStorage.initials(snapshot.data).substring(0, 1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
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
