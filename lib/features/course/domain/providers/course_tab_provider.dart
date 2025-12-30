import 'package:flutter_riverpod/flutter_riverpod.dart';

final courseTabProvider = StateProvider<int>((ref) => 0);
// 0 = Materi, 1 = Tugas
