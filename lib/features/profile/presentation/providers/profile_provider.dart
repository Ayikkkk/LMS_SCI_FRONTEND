// lib/features/profile/presentation/providers/profile_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/profile_repository.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/data/models/student_model.dart';

/// Provider Repository
final profileRepositoryProvider = Provider((ref) {
  final apiClient = ref.read(apiClientProvider);
  final authRepo = ref.read(authRepositoryProvider);
  return ProfileRepository(apiClient, authRepo);
});

/// FutureProvider GET profile
final profileDataProvider = FutureProvider<StudentModel>((ref) async {
  final repo = ref.read(profileRepositoryProvider);
  final raw = await repo.getProfile();

  return StudentModel.fromJson(raw);
});

/// PROVIDER GLOBAL DATA SISWA LOGIN
final studentProvider = Provider<StudentModel?>((ref) {
  final profile = ref.watch(profileDataProvider);

  return profile.when(
    data: (student) => student,
    loading: () => null,
    error: (_, __) => null,
  );
});
