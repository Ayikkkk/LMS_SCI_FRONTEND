import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/providers/online_meeting_provider.dart';
import 'jitsi_helper.dart';
import '../../../../scaffold_messenger_key.dart';
import '../../../../navigation_service.dart';
import '../../../../core/constants/error_messages.dart';
import '../../../../core/widgets/error_widget.dart';

class OnlineClassScreen extends ConsumerStatefulWidget {
  const OnlineClassScreen({super.key});

  @override
  ConsumerState<OnlineClassScreen> createState() => _OnlineClassScreenState();
}

class _OnlineClassScreenState extends ConsumerState<OnlineClassScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(onlineMeetingProvider.notifier).loadMeetings();
    });

    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      ref.read(onlineMeetingProvider.notifier).loadMeetings();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refreshMeetings() async {
    await ref.read(onlineMeetingProvider.notifier).loadMeetings();
  }

  String _formatDateTime(DateTime dt) {
    // dt sudah local dari model (toLocal() saat parsing)
    final two = (int n) => n.toString().padLeft(2, '0');
    return '${dt.day}/${two(dt.month)}/${dt.year} ${two(dt.hour)}:${two(dt.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onlineMeetingProvider);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return AppErrorWidget(
        message: state.error!,
        onRetry: _refreshMeetings,
      );
    }

    if (state.meetings.isEmpty) {
      return const Center(child: Text("Tidak ada online meeting"));
    }

    return RefreshIndicator(
      onRefresh: _refreshMeetings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.meetings.length,
        itemBuilder: (_, index) {
          final meeting = state.meetings[index];
          final isLive = meeting.isLive;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(
                meeting.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                "Mulai: ${meeting.startTime != null ? _formatDateTime(meeting.startTime!) : '-'}"
                "\nStatus: ${meeting.status.toUpperCase()}",
              ),
              trailing: isLive
                  ? ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text("LIVE"),
                      onPressed: () async {
                        final notifier =
                            ref.read(onlineMeetingProvider.notifier);

                        try {
                          final result = await notifier.joinMeeting(meeting.id);

                          // 🚨 NAVIGASI AMAN (TANPA CONTEXT)
                          NavigationService.instance.navigatorKey.currentState
                              ?.push(
                            MaterialPageRoute(
                              builder: (_) => JitsiMeetingPage(
                                meetingId: meeting.id,
                                room: result.meetingCode,
                              ),
                            ),
                          );
                        } catch (e) {
                          scaffoldMessengerKey.currentState?.showSnackBar(
                            SnackBar(
                              content: Text(ErrorMessages.fromException(e)),
                            ),
                          );
                        }
                      },
                    )
                  : const Text(
                      "Pending",
                      style: TextStyle(color: Colors.grey),
                    ),
            ),
          );
        },
      ),
    );
  }
}

/// =======================================================
/// JITSI MEETING PAGE — FINAL, STABIL, TANPA ERROR
/// =======================================================

class JitsiMeetingPage extends ConsumerStatefulWidget {
  final int meetingId;
  final String room;

  const JitsiMeetingPage({
    super.key,
    required this.meetingId,
    required this.room,
  });

  @override
  ConsumerState<JitsiMeetingPage> createState() => _JitsiMeetingPageState();
}

class _JitsiMeetingPageState extends ConsumerState<JitsiMeetingPage> {
  bool _joined = false;
  bool _hasLeft = false;

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      if (_joined) return;
      _joined = true;

      await JitsiHelper.joinMeeting(
        room: widget.room,
        displayName: "Siswa",
        onMeetingLeft: _handleLeaveSafely,
      );
    });
  }

  Future<void> _handleLeaveSafely() async {
    if (_hasLeft) return;
    _hasLeft = true;

    final notifier = ref.read(onlineMeetingProvider.notifier);
    await notifier.leaveMeeting(widget.meetingId);

    NavigationService.instance.navigatorKey.currentState?.maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text("Meeting sedang berjalan..."),
      ),
    );
  }
}
