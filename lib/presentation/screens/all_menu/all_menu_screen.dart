import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../application/controllers/app_controller.dart';
import '../../../application/controllers/auth_controller.dart';
import '../../widgets/employee_avatar.dart';
import '../approvals/approvals_screen.dart';
import '../attendance/attendance_screen.dart';
import '../feed/feed_list_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';
import '../requests/requests_screen.dart';
import '../settings/settings_screen.dart';

class AllMenuScreen extends StatelessWidget {
  const AllMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final employee = context.watch<AppController>().employee;
    final items = [
      _MenuItem('My Requests', Icons.assignment_outlined, const RequestsScreen()),
      _MenuItem('Approvals', Icons.fact_check_outlined, const ApprovalsScreen()),
      _MenuItem('My Profile', Icons.person_outline, const ProfileScreen()),
      _MenuItem('Correction', Icons.edit_calendar_outlined, const AttendanceScreen(initialTab: 2)),
      _MenuItem('Attendance', Icons.fingerprint, const AttendanceScreen()),
      _MenuItem('News', Icons.newspaper_outlined, const FeedListScreen.news()),
      _MenuItem('Announcements', Icons.campaign_outlined, const FeedListScreen.announcements()),
      _MenuItem('Medical Claim', Icons.health_and_safety_outlined, const RequestsScreen.medicalClaims()),
      _MenuItem('Settings', Icons.settings_outlined, const SettingsScreen()),
      _MenuItem('Notifications', Icons.notifications_none, const NotificationsScreen()),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('All Menu')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Card(
              child: ListTile(
                leading: EmployeeAvatar(
                  initials: employee?.initials ?? 'HR',
                  avatarUrl: employee?.avatarUrl,
                  radius: 24,
                ),
                title: Text(employee?.name ?? 'Employee'),
                subtitle: Text(employee?.title ?? 'Role'),
                trailing: OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  ),
                  child: const Text('Edit Profile'),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemBuilder: (_, i) => ListTile(
                dense: true,
                leading: Icon(items[i].icon, size: 20),
                title: Text(items[i].label, style: const TextStyle(fontSize: 13)),
                trailing: const Icon(Icons.chevron_right, size: 18),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => items[i].page),
                ),
              ),
              separatorBuilder: (_, index) => const Divider(height: 1),
              itemCount: items.length,
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                  ),
                  onPressed: () async {
                    await context.read<AuthController>().logout();
                    if (!context.mounted) return;
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final String label;
  final IconData icon;
  final Widget page;
  _MenuItem(this.label, this.icon, this.page);
}

