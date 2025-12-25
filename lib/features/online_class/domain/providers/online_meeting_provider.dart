// lib/features/online_class/domain/providers/online_meeting_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/online_meeting_model.dart';
import '../../data/repository/online_meeting_repository.dart';

final onlineMeetingRepositoryProvider =
    Provider<OnlineMeetingRepository>((ref) {
  final dio = ref.read(apiClientProvider);
  return OnlineMeetingRepository(dio);
});

final onlineMeetingProvider =
    FutureProvider<List<OnlineMeetingModel>>((ref) async {
  return ref.read(onlineMeetingRepositoryProvider).fetchMeetings();
});
