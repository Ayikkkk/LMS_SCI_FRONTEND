// lib/features/course/domain/providers/course_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repository/course_repository.dart';
import '../../data/models/assignment_model.dart';
import '../../data/models/course_material_model.dart';

// Provider untuk data daftar materi
final courseMaterialsProvider =
    FutureProvider<List<CourseMaterialModel>>((ref) async {
  final repo = ref.watch(courseRepositoryProvider);
  return repo.fetchMaterials();
});

// Provider untuk data daftar tugas
final courseAssignmentsProvider =
    FutureProvider<List<AssignmentModel>>((ref) async {
  final repo = ref.watch(courseRepositoryProvider);
  return repo.fetchAssignments();
});

// Provider untuk detail 1 tugas
final assignmentDetailProvider =
    FutureProvider.family<AssignmentModel, int>((ref, assignmentId) async {
  final repo = ref.watch(courseRepositoryProvider);
  return repo.fetchAssignmentDetail(assignmentId);
});

// Provider untuk detail 1 materi
final materialDetailProvider =
    FutureProvider.family<CourseMaterialModel, int>((ref, materialId) async {
  final repo = ref.watch(courseRepositoryProvider);
  return repo.fetchMaterialDetail(materialId);
});
