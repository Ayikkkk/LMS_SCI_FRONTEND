import 'package:flutter/material.dart';
import '../../data/models/recap_subject_model.dart';
import 'recap_table.dart';

class SubjectSection extends StatelessWidget {
  final RecapSubjectModel subject;

  const SubjectSection({
    super.key,
    required this.subject,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // MAPEL TITLE
            Text(
              subject.mapel,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // TABLE
            RecapTable(subject: subject),
          ],
        ),
      ),
    );
  }
}
