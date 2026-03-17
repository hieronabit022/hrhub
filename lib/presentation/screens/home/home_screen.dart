import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../application/controllers/app_controller.dart';
import '../../../application/controllers/attendance_controller.dart';
import '../../../application/controllers/feed_controller.dart';
import '../../../application/controllers/notification_controller.dart';
import '../../../application/controllers/request_controller.dart';
import '../../../domain/models/entities.dart';
import '../all_menu/all_menu_screen.dart';
import '../approvals/approvals_screen.dart';
import '../attendance/attendance_screen.dart';
import '../feed/feed_list_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';
import '../requests/requests_screen.dart';
import '../settings/settings_screen.dart';
import '../../widgets/employee_avatar.dart';
import '../../widgets/swipe_attendance_action.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  bool _isMobileApprovalType(RequestType type) {
    return type == RequestType.leave ||
        type == RequestType.permission ||
        type == RequestType.wfa;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final employee = context.read<AppController>().employee;
      context.read<RequestController>().load(employee?.id);
      context.read<RequestController>().loadApprovals(employee?.id);
      context.read<AttendanceController>().load(employee: employee?.id, branch: employee?.branchId);
      context.read<FeedController>().loadAll(employee?.id);
      context.read<NotificationController>().load(employee?.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    final employee = app.employee;
    final requestCtrl = context.watch<RequestController>();
    final notificationCtrl = context.watch<NotificationController>();
    final latestItems = (_tab == 0
            ? requestCtrl.requests.take(3).toList()
            : requestCtrl.approvals.where((e) => _isMobileApprovalType(e.type)).take(3).toList())
        .toList();

    return Scaffold(
      body: SafeArea(
        top: true,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          children: [
            SizedBox(
              height: 46,
              child: Center(
                child: SizedBox(
                  width: 220,
                  child: Image.asset(
                    'assets/brand/logos.png',
                    fit: BoxFit.fitWidth,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Card(
              child: ListTile(
                leading: EmployeeAvatar(
                  initials: employee?.initials ?? 'HR',
                  avatarUrl: employee?.avatarUrl,
                  radius: 20,
                ),
                title: Text(
                  employee?.name ?? 'Employee',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                subtitle: Text(employee?.title ?? 'Role', style: const TextStyle(fontSize: 11)),
                trailing: IconButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                  ),
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.notifications_none_rounded),
                      if (notificationCtrl.unreadCount > 0)
                        Positioned(
                          right: -2,
                          top: -3,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Theme.of(context).colorScheme.surface, width: 1.2),
                            ),
                            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                            child: Text(
                              notificationCtrl.unreadCount > 9 ? '9+' : '${notificationCtrl.unreadCount}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  tooltip: 'Notifications',
                ),
              ),
            ),
            const SizedBox(height: 4),
            const _NewsAnnouncementSlider(),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('Quick Menu', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.8)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AllMenuScreen()),
                  ),
                  icon: const Icon(Icons.grid_view_rounded, size: 15),
                  label: const Text('All Menu'),
                ),
              ],
            ),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 0.95,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              children: [
                _QuickTile(
                  label: 'Requests',
                  icon: Icons.assignment_outlined,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RequestsScreen()),
                  ),
                ),
                _QuickTile(
                  label: 'Attendance',
                  icon: Icons.fingerprint_rounded,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AttendanceScreen()),
                  ),
                ),
                _QuickTile(
                  label: 'Approvals',
                  icon: Icons.fact_check_outlined,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ApprovalsScreen()),
                  ),
                ),
                _QuickTile(
                  label: 'Profile',
                  icon: Icons.person_outline_rounded,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  ),
                ),
                _QuickTile(
                  label: 'News',
                  icon: Icons.newspaper_rounded,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FeedListScreen.news()),
                  ),
                ),
                _QuickTile(
                  label: 'Medical Claim',
                  icon: Icons.health_and_safety_outlined,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RequestsScreen.medicalClaims()),
                  ),
                ),
                _QuickTile(
                  label: 'Announcements',
                  icon: Icons.campaign_outlined,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FeedListScreen.announcements()),
                  ),
                ),
                _QuickTile(
                  label: 'Settings',
                  icon: Icons.settings_outlined,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const _SwipeClockCard(),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  _tab == 0 ? 'Latest Requests' : 'Latest Approvals',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.8),
                ),
                const Spacer(),
                SizedBox(
                  width: 220,
                  child: SegmentedButton<int>(
                    style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      padding: WidgetStateProperty.all(
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    segments: const [
                      ButtonSegment(value: 0, label: Text('Req')),
                      ButtonSegment(value: 1, label: Text('App')),
                    ],
                    selected: {_tab},
                    onSelectionChanged: (v) => setState(() => _tab = v.first),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...latestItems.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Card(
                  child: ListTile(
                    leading: EmployeeAvatar(
                      initials: (employee?.initials ?? 'HR').substring(0, 1),
                      avatarUrl: employee?.avatarUrl,
                      radius: 16,
                    ),
                    title: Text(r.title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                    subtitle: Text(
                      '${r.type.name.toUpperCase()} • ${r.status.name.toUpperCase()}',
                      style: const TextStyle(fontSize: 10.5),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RequestsScreen()),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 70),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 0),
        padding: const EdgeInsets.fromLTRB(6, 4, 6, 0),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.light
              ? Colors.white
              : const Color(0xFF101827),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.light
                ? const Color(0xFFE7EAF2)
                : const Color(0xFF23314B),
          ),
          boxShadow: Theme.of(context).brightness == Brightness.light
              ? const [
                  BoxShadow(
                    color: Color(0x140F172A),
                    blurRadius: 22,
                    offset: Offset(0, 10),
                  ),
                ]
              : const [],
        ),
        child: SafeArea(
          top: false,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            child: NavigationBar(
              selectedIndex: 0,
              destinations: const [
                NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
                NavigationDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment_rounded), label: 'Requests'),
                NavigationDestination(icon: Icon(Icons.fingerprint), selectedIcon: Icon(Icons.fingerprint_rounded), label: 'Attendance'),
                NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Profile'),
              ],
              onDestinationSelected: (index) {
                if (index == 1) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const RequestsScreen()));
                } else if (index == 2) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceScreen()));
                } else if (index == 3) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _NewsAnnouncementSlider extends StatefulWidget {
  const _NewsAnnouncementSlider();

  @override
  State<_NewsAnnouncementSlider> createState() => _NewsAnnouncementSliderState();
}

class _NewsAnnouncementSliderState extends State<_NewsAnnouncementSlider> {
  late final PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;
  int _lastItemCount = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSlide(int itemCount) {
    if (_lastItemCount == itemCount && _timer != null) return;
    _lastItemCount = itemCount;
    _timer?.cancel();
    if (itemCount <= 1) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_pageController.hasClients) return;
      final nextPage = (_currentPage + 1) % itemCount;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final feed = context.watch<FeedController>();
    final items = [...feed.news.take(1), ...feed.announcements.take(1)];

    if (items.isEmpty) {
      return const SizedBox(
        height: 138,
        child: Card(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    _startAutoSlide(items.length);

    return SizedBox(
      height: 138,
      child: PageView(
        controller: _pageController,
        onPageChanged: (index) => _currentPage = index,
        children: items.map((item) => _banner(context, item: item)).toList(),
      ),
    );
  }

  Widget _banner(BuildContext context, {required FeedItem item}) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => FeedDetailScreen(itemId: item.id)),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: item.type == FeedType.news
                ? const [Color(0xFF2563EB), Color(0xFF7C3AED)]
                : const [Color(0xFF0F766E), Color(0xFF14B8A6)],
          ),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            _BannerArtwork(item: item),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.type == FeedType.news ? 'News Update' : 'Announcement',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 10.8,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.88), fontSize: 11.2),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _BannerArtwork extends StatelessWidget {
  final FeedItem item;

  const _BannerArtwork({required this.item});

  @override
  Widget build(BuildContext context) {
    final icon = switch (item.type) {
      FeedType.news => Icons.newspaper_rounded,
      FeedType.announcement => Icons.campaign_rounded,
      FeedType.lifeEvent => Icons.celebration_rounded,
    };

    return Container(
      width: 76,
      height: 96,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: 0.14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -8,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            left: -14,
            bottom: -18,
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 28),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    (item.coverImage ?? item.type.name).toUpperCase(),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: 9.2,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SwipeClockCard extends StatelessWidget {
  const _SwipeClockCard();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final timeText = DateFormat('HH:mm:ss').format(now);
    final dateText = DateFormat('EEEE, dd MMM yyyy').format(now);
    final attendance = context.watch<AttendanceController>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(timeText, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(dateText, style: const TextStyle(fontSize: 11)),
            const SizedBox(height: 10),
            SwipeAttendanceAction(
              checkedIn: attendance.checkedIn,
              onClockIn: attendance.clockIn,
              onClockOut: attendance.clockOut,
              isWithinOfficeRadius: attendance.isWithinOfficeRadius,
            ),
            const SizedBox(height: 10),
            FutureBuilder<bool>(
              future: attendance.isWithinOfficeRadius(),
              builder: (context, snapshot) {
                final inOffice = snapshot.data ?? false;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: inOffice ? const Color(0xFF16A34A) : const Color(0xFF9CA3AF),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      inOffice ? 'Office area detected' : 'Not in office',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickTile({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 9.2, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
