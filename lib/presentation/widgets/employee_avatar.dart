import 'package:flutter/material.dart';

class EmployeeAvatar extends StatelessWidget {
  final String initials;
  final String? avatarUrl;
  final double radius;

  const EmployeeAvatar({
    super.key,
    required this.initials,
    this.avatarUrl,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedUrl = avatarUrl?.trim();
    if (normalizedUrl == null || normalizedUrl.isEmpty) {
      return CircleAvatar(
        radius: radius,
        child: Text(initials),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      backgroundImage: NetworkImage(normalizedUrl),
      onBackgroundImageError: (_, __) {},
    );
  }
}
