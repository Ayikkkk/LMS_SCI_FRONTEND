import 'package:flutter/material.dart';
import '../../data/models/recap_subject_model.dart';

class RecapTable extends StatelessWidget {
  final RecapSubjectModel subject;
  final double columnWidth;

  const RecapTable({
    super.key,
    required this.subject,
    this.columnWidth = 120,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        defaultColumnWidth: FixedColumnWidth(columnWidth),
        border: TableBorder.all(
          color: theme.dividerColor,
          width: 1,
        ),
        children: [
          // =====================
          // HEADER ROW
          // =====================
          TableRow(
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
            ),
            children: subject.headers.map((header) {
              return Padding(
                padding: const EdgeInsets.all(8),
                child: Center(
                  child: Text(
                    header,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          // =====================
          // VALUE ROW
          // =====================
          TableRow(
            children: subject.headers.map((header) {
              final value = subject.displayScore(header);
              return Padding(
                padding: const EdgeInsets.all(12),
                child: Center(
                  child: Text(
                    value,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
