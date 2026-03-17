import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'application/controllers/app_controller.dart';
import 'application/controllers/attendance_controller.dart';
import 'application/controllers/auth_controller.dart';
import 'application/controllers/feed_controller.dart';
import 'application/controllers/notification_controller.dart';
import 'application/controllers/profile_controller.dart';
import 'application/controllers/request_controller.dart';
import 'application/controllers/theme_controller.dart';
import 'data/repositories/supabase_repositories.dart';
import 'presentation/app/workpulse_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final client = SupabaseRestClient();
  final authRepository = SupabaseAuthRepository(client);
  final employeeRepository = SupabaseEmployeeRepository(client, authRepository);
  final branchRepository = SupabaseBranchRepository(client);
  final attendanceRepository = SupabaseAttendanceRepository(client);
  final requestRepository = SupabaseRequestRepository(client);
  final profileRepository = SupabaseProfileRepository(client);
  final feedRepository = SupabaseFeedRepository(client);
  final notificationRepository = SupabaseNotificationRepository(client);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeController()),
        ChangeNotifierProvider(create: (_) => AuthController(authRepository)),
        ChangeNotifierProvider(create: (_) => AppController(employeeRepository)),
        ChangeNotifierProvider(
          create: (_) => AttendanceController(
            attendanceRepository,
            branchRepository,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => RequestController(
            requestRepository,
            notificationRepository,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ProfileController(
            profileRepository,
            notificationRepository,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => FeedController(
            feedRepository,
            notificationRepository,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationController(notificationRepository),
        ),
      ],
      child: const WorkPulseApp(),
    ),
  );
}
