import 'package:flutter/material.dart';

class ScoreCell extends StatelessWidget {
  final String value;
  final double width;

  const ScoreCell({
    super.key,
    required this.value,
    this.width = 80,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
      ),
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
