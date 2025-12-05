import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/profile_repository.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/data/models/student_model.dart';
import '../../../../core/network/api_client.dart';

/// Provider untuk ProfileRepository
final profileRepositoryProvider = Provider((ref) {
  final apiClient = ref.read(apiClientProvider);  
  final authRepo = ref.read(authRepositoryProvider);
  return ProfileRepository(apiClient, authRepo);
});

/// Provider Future untuk ambil data profile
final profileDataProvider = FutureProvider<StudentModel>((ref) async {
  final profileRepo = ref.read(profileRepositoryProvider);
  final data = await profileRepo.getProfile();
  return StudentModel.fromJson(data);
});
