// lib/features/online_class/domain/providers/online_meeting_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/online_meeting_model.dart';
import '../../data/repository/online_meeting_repository.dart';
import '../../../../core/constants/error_messages.dart';
import '../../../../core/network/api_client.dart';

/// =======================
/// Repository Provider
/// =======================
final onlineMeetingRepositoryProvider =
    Provider<OnlineMeetingRepository>((ref) {
  final dio = ref.read(apiClientProvider);
  return OnlineMeetingRepository(dio);
});

/// =======================
/// State
/// =======================
class OnlineMeetingState {
  final bool isLoading;
  final List<OnlineMeetingModel> meetings;
  final String? error;

  const OnlineMeetingState({
    required this.isLoading,
    required this.meetings,
    this.error,
  });

  OnlineMeetingState copyWith({
    bool? isLoading,
    List<OnlineMeetingModel>? meetings,
    String? error,
  }) {
    return OnlineMeetingState(
      isLoading: isLoading ?? this.isLoading,
      meetings: meetings ?? this.meetings,
      error: error,
    );
  }

  factory OnlineMeetingState.initial() {
    return const OnlineMeetingState(
      isLoading: false,
      meetings: [],
      error: null,
    );
  }
}

/// =======================
/// Notifier
/// =======================
class OnlineMeetingNotifier extends StateNotifier<OnlineMeetingState> {
  final OnlineMeetingRepository repository;
  // Guard: cegah loadMeetings berjalan paralel dari timer + manual refresh
  bool _isFetching = false;

  OnlineMeetingNotifier(this.repository) : super(OnlineMeetingState.initial());

  /// 🔹 Load meetings siswa
  Future<void> loadMeetings() async {
    if (_isFetching) return; // skip jika sedang in-flight
    _isFetching = true;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final allMeetings = await repository.fetchMeetings();

      // Filter: hanya meeting hari ini dan mendatang
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final filteredMeetings = allMeetings.where((meeting) {
        if (meeting.startTime == null) {
          return true; // Tampilkan jika tidak ada tanggal
        }

        final meetingDate = DateTime(
          meeting.startTime!.year,
          meeting.startTime!.month,
          meeting.startTime!.day,
        );

        final isValid =
            meetingDate.isAtSameMomentAs(today) || meetingDate.isAfter(today);

        return isValid;
      }).toList();

      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          meetings: filteredMeetings,
        );
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          error: ErrorMessages.fromException(e),
        );
      }
    } finally {
      _isFetching = false;
    }
  }

  /// 🔹 Join meeting
  /// - hanya bisa jika status = live
  /// - return MeetingJoinResponse untuk buka Jitsi
  Future<MeetingJoinResponse> joinMeeting(int meetingId) async {
    try {
      final result = await repository.joinMeeting(meetingId);

      // Refresh list (status tetap live)
      await loadMeetings();

      return result;
    } catch (e) {
      state = state.copyWith(error: ErrorMessages.fromException(e));
      rethrow; // BIAR UI bisa show dialog/snackbar
    }
  }

  /// 🔹 Leave meeting
  Future<void> leaveMeeting(int meetingId) async {
    try {
      await repository.leaveMeeting(meetingId);
      await loadMeetings();
    } catch (e) {
      state = state.copyWith(error: ErrorMessages.fromException(e));
    }
  }

  /// 🔹 Helper: ambil meeting live (jika ada)
  OnlineMeetingModel? get liveMeeting {
    try {
      return state.meetings.firstWhere((m) => m.isLive);
    } catch (_) {
      return null;
    }
  }
}

/// =======================
/// Provider
/// =======================
final onlineMeetingProvider =
    StateNotifierProvider<OnlineMeetingNotifier, OnlineMeetingState>((ref) {
  return OnlineMeetingNotifier(
    ref.read(onlineMeetingRepositoryProvider),
  );
});
