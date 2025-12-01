import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/profile_repository.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/data/models/student_model.dart';
import '../../../../core/network/api_client.dart';

/// Provider untuk ProfileRepository
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final authRepo = ref.read(authRepositoryProvider);
  return ProfileRepository(dio, authRepo);
});

/// Provider untuk mengambil data profile (FutureProvider)
final profileDataProvider = FutureProvider<StudentModel>((ref) async {
  final repo = ref.read(profileRepositoryProvider);

  final data = await repo.getProfile();

  return StudentModel.fromJson(data);
});
