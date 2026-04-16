// Provider untuk data Dashboard
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/dashboard_model.dart';
import '../../data/repository/home_repository.dart';

// Provider yang akan digunakan di DashboardContent
final dashboardDataProvider = FutureProvider<DashboardModel>((ref) async {
  final repo = ref.watch(homeRepositoryProvider);
  return repo.fetchDashboardData();
});

// Provider untuk data assignments (tugas siswa)
final dashboardAssignmentsProvider = FutureProvider((ref) async {
  final repo = ref.watch(homeRepositoryProvider);
  final assignments = await repo.fetchAssignments();

  final now = DateTime.now();

  return assignments
      .where((a) => !a.isSubmitted && a.dueDate.isAfter(now))
      .toList()
    ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
});
