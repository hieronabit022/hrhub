import 'package:flutter/material.dart';

import '../../domain/contracts/repositories.dart';
import '../../domain/models/entities.dart';

class NotificationController extends ChangeNotifier {
  final NotificationRepository _repository;
  NotificationController(this._repository);

  List<AppNotification> notifications = [];
  String employeeId = 'emp-1';

  int get unreadCount => notifications.where((e) => !e.read).length;
  List<AppNotification> get unreadNotifications => notifications.where((e) => !e.read).toList();
  List<AppNotification> get allNotificationsSorted {
    final items = [...notifications];
    items.sort((a, b) {
      if (a.read != b.read) return a.read ? 1 : -1;
      return b.createdAt.compareTo(a.createdAt);
    });
    return items;
  }

  Future<void> load([String? employee]) async {
    if (employee != null) employeeId = employee;
    notifications = await _repository.listByEmployee(employeeId);
    notifyListeners();
  }

  Future<void> markRead(String id) async {
    await _repository.markRead(id);
    await load();
  }
}
