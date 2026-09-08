import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class OySynLogo extends StatelessWidget {
  final double size;

  const OySynLogo({super.key, required this.size});

  @override
  Widget build(BuildContext context) => ClipOval(
        child: Image.asset(
          OySynAuthTokens.logoAsset,
          width: size,
          height: size,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
          semanticLabel: 'OySyn',
        ),
      );
}
