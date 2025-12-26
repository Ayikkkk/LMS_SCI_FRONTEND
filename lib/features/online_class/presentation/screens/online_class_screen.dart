import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/providers/online_meeting_provider.dart';
import 'jitsi_helper.dart';

class OnlineClassScreen extends ConsumerStatefulWidget {
  const OnlineClassScreen({super.key});

  @override
  ConsumerState<OnlineClassScreen> createState() =>
      _OnlineClassScreenState();
}

class _OnlineClassScreenState extends ConsumerState<OnlineClassScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    // Auto refresh setiap 10 detik
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      ref.invalidate(onlineMeetingProvider);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refreshMeetings() async {
    ref.invalidate(onlineMeetingProvider);
  }

  @override
  Widget build(BuildContext context) {
    final meetingsAsync = ref.watch(onlineMeetingProvider);

    return RefreshIndicator(
      onRefresh: _refreshMeetings,
      child: meetingsAsync.when(
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
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  title: Text(
                    meeting.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Mulai: ${meeting.startTime}\nStatus: ${meeting.status.toUpperCase()}",
                  ),
                  trailing: isLive
                      ? ElevatedButton(
                          onPressed: () async {
                            final repo =
                                ref.read(onlineMeetingRepositoryProvider);

                            final jitsiUrl =
                                await repo.joinMeeting(meeting.id);
                            final room = jitsiUrl.split('/').last;

                            // Join Jitsi & listen exit callback
                            await JitsiHelper.joinMeeting(
                              room: room,
                              displayName: 'Siswa',
                              onLeft: () async {
                                await repo.leaveMeeting(meeting.id);
                                ref.invalidate(onlineMeetingProvider);
                              },
                            );
                          },
                          child: const Text('Join'),
                        )
                      : const Text(
                          'Belum Live',
                          style: TextStyle(color: Colors.grey),
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
