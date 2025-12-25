// lib/features/online_class/presentation/screens/online_class_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/providers/online_meeting_provider.dart';
import 'jitsi_helper.dart';

class OnlineClassScreen extends ConsumerWidget {
  const OnlineClassScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meetingsAsync = ref.watch(onlineMeetingProvider);

    return meetingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text(err.toString())),
      data: (meetings) {
        if (meetings.isEmpty) {
          return const Center(child: Text('Tidak ada online meeting'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: meetings.length,
          itemBuilder: (context, index) {
            final meeting = meetings[index];
            final isLive = meeting.status == 'live';

            return Card(
              child: ListTile(
                title: Text(meeting.title),
                subtitle: Text(
                  'Mulai: ${meeting.startTime}\nStatus: ${meeting.status.toUpperCase()}',
                ),
                trailing: isLive
                    ? ElevatedButton(
                        onPressed: () async {
                          final repo =
                              ref.read(onlineMeetingRepositoryProvider);

                          final jitsiUrl =
                              await repo.joinMeeting(meeting.id);

                          final room =
                              jitsiUrl.split('/').last;

                          await JitsiHelper.joinMeeting(
                            room: room,
                            displayName: 'Siswa',
                          );
                        },
                        child: const Text('Join'),
                      )
                    : const Text('Belum Live'),
              ),
            );
          },
        );
      },
    );
  }
}
