import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Icon(
      Icons.check_box_outlined,
      size: size,
      color: theme.colorScheme.primary,
    );
  }
}
