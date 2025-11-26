// Provider untuk data Dashboard
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/dashboard_model.dart';
import '../../data/repository/home_repository.dart';

// Provider yang akan digunakan di DashboardContent
final dashboardDataProvider = FutureProvider<DashboardModel>((ref) async {
  final repo = ref.watch(homeRepositoryProvider);
  return repo.fetchDashboardData();
});