import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../application/controllers/app_controller.dart';
import '../../../application/controllers/notification_controller.dart';
import '../../../domain/models/entities.dart';
import '../approvals/approvals_screen.dart';
import '../feed/feed_list_screen.dart';
import '../requests/requests_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final employee = context.read<AppController>().employee;
      context.read<NotificationController>().load(employee?.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<NotificationController>();
    final unread = ctrl.unreadNotifications;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AllNotificationsScreen()),
            ),
            child: const Text('Show All'),
          ),
        ],
      ),
      body: unread.isEmpty
          ? const Center(
              child: Text('No unread notifications'),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: unread.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (_, i) {
                final n = unread[i];
                return _NotificationCard(
                  notification: n,
                  trailing: TextButton(
                    onPressed: () => ctrl.markRead(n.id),
                    child: const Text('Mark read'),
                  ),
                  onTap: () async {
                    await ctrl.markRead(n.id);
                    if (!context.mounted) return;
                    _openTarget(context, n);
                  },
                );
              },
            ),
    );
  }
}

class AllNotificationsScreen extends StatefulWidget {
  const AllNotificationsScreen({super.key});

  @override
  State<AllNotificationsScreen> createState() => _AllNotificationsScreenState();
}

class _AllNotificationsScreenState extends State<AllNotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final employee = context.read<AppController>().employee;
      context.read<NotificationController>().load(employee?.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<NotificationController>();
    final items = ctrl.allNotificationsSorted;

    return Scaffold(
      appBar: AppBar(title: const Text('All Notifications')),
      body: items.isEmpty
          ? const Center(child: Text('No notifications yet'))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (_, i) {
                final n = items[i];
                return _NotificationCard(
                  notification: n,
                  trailing: n.read
                      ? Icon(
                          Icons.done_all,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : TextButton(
                          onPressed: () => ctrl.markRead(n.id),
                          child: const Text('Mark read'),
                        ),
                  onTap: () async {
                    if (!n.read) {
                      await ctrl.markRead(n.id);
                    }
                    if (!context.mounted) return;
                    _openTarget(context, n);
                  },
                );
              },
            ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final Widget trailing;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: notification.read
          ? null
          : Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.16),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  (notification.avatarLabel?.isNotEmpty ?? false) ? notification.avatarLabel! : 'HR',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9),
                      ),
                    ),
                    if ((notification.detail ?? '').isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        notification.detail!,
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      DateFormat('dd MMM yyyy, HH:mm').format(notification.createdAt),
                      style: TextStyle(
                        fontSize: 10.8,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

void _openDetail(BuildContext context, AppNotification n) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => NotificationDetailScreen(notification: n),
    ),
  );
}

void _openTarget(BuildContext context, AppNotification n) {
  final path = n.deepLink;
  if (path.startsWith('/feed/')) {
    final itemId = path.substring('/feed/'.length);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FeedDetailScreen(itemId: itemId)),
    );
    return;
  }
  if (path.startsWith('/life-events/')) {
    final itemId = path.substring('/life-events/'.length);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FeedDetailScreen(itemId: itemId)),
    );
    return;
  }
  if (path.startsWith('/approvals/')) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ApprovalsScreen()),
    );
    return;
  }
  if (path.startsWith('/requests/')) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RequestsScreen()),
    );
    return;
  }
  _openDetail(context, n);
}

class NotificationDetailScreen extends StatelessWidget {
  final AppNotification notification;
  const NotificationDetailScreen({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Detail')),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: Text(
                          (notification.avatarLabel?.isNotEmpty ?? false) ? notification.avatarLabel! : 'HR',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    notification.body,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  if ((notification.detail ?? '').isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      notification.detail!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    'Created: ${DateFormat('dd MMM yyyy, HH:mm').format(notification.createdAt)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
