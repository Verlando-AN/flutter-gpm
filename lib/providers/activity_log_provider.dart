import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/activity_log_model.dart';
import '../repositories/activity_log_repository.dart';

final activityLogRepositoryProvider = Provider<ActivityLogRepository>((ref) {
  return ActivityLogRepository();
});

final activityLogsProvider = FutureProvider<List<ActivityLogModel>>((
  ref,
) async {
  final repository = ref.read(activityLogRepositoryProvider);

  return repository.getLogs();
});
