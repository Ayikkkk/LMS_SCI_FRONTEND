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

  return assignments.where((a) => !a.isSubmitted).toList()
    ..sort((a, b) {
      // Tugas tanpa deadline diletakkan di akhir
      if (a.dueDate == null && b.dueDate == null) return 0;
      if (a.dueDate == null) return 1;
      if (b.dueDate == null) return -1;
      return a.dueDate!.compareTo(b.dueDate!);
    });
});
