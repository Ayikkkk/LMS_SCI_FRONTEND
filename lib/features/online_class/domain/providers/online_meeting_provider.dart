// lib/features/online_class/domain/providers/online_meeting_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/online_meeting_model.dart';
import '../../data/repository/online_meeting_repository.dart';
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

  OnlineMeetingNotifier(this.repository)
      : super(OnlineMeetingState.initial());

  /// 🔹 Load meetings siswa
  Future<void> loadMeetings() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final meetings = await repository.fetchMeetings();
      state = state.copyWith(
        isLoading: false,
        meetings: meetings,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
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
      state = state.copyWith(error: e.toString());
      rethrow; // BIAR UI bisa show dialog/snackbar
    }
  }

  /// 🔹 Leave meeting
  Future<void> leaveMeeting(int meetingId) async {
    try {
      await repository.leaveMeeting(meetingId);
      await loadMeetings();
    } catch (e) {
      state = state.copyWith(error: e.toString());
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
