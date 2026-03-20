import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../domain/contracts/repositories.dart';
import '../../domain/models/entities.dart';

class FeedController extends ChangeNotifier {
  final FeedRepository _feedRepository;
  final NotificationRepository _notificationRepository;
  final Uuid _uuid = const Uuid();

  FeedController(this._feedRepository, this._notificationRepository);

  String employeeId = 'emp-1';
  List<FeedItem> news = [];
  List<FeedItem> announcements = [];
  List<FeedItem> lifeEvents = [];

  Future<void> loadAll([String? employee]) async {
    if (employee != null) employeeId = employee;
    news = await _feedRepository.list(FeedType.news);
    announcements = await _feedRepository.list(FeedType.announcement);
    lifeEvents = await _feedRepository.list(FeedType.lifeEvent);
    await _syncFeedNotifications();
    notifyListeners();
  }

  Future<FeedItem> getById(String id) async => _feedRepository.getById(id);

  Future<void> toggleLike(String itemId) async {
    await _feedRepository.toggleLike(itemId, employeeId);
    await loadAll();
  }

  Future<void> addComment(String itemId, String text) async {
    final existing = await _feedRepository.getById(itemId);
    final hasOwn = existing.comments.any((e) => e.employeeId == employeeId);
    if (hasOwn) {
      throw StateError('You already commented on this post.');
    }
    await _feedRepository.addComment(
      itemId,
      FeedComment(
        id: _uuid.v4(),
        itemId: itemId,
        employeeId: employeeId,
        content: text,
        createdAt: DateTime.now(),
      ),
    );
    await loadAll();
  }

  void setEmployee(String? employee) {
    if (employee == null || employee.isEmpty) return;
    employeeId = employee;
    notifyListeners();
  }

  Future<void> editComment(
    String itemId,
    String commentId,
    String text,
  ) async {
    final item = await _feedRepository.getById(itemId);
    final comment = item.comments.firstWhere((e) => e.id == commentId);
    await _feedRepository.updateComment(itemId, comment.copyWith(content: text));
    await loadAll();
  }

  Future<void> deleteComment(String itemId, String commentId) async {
    await _feedRepository.deleteComment(itemId, commentId);
    await loadAll();
  }

  Future<void> _syncFeedNotifications() async {
    if (employeeId.isEmpty) return;
    final existing = await _notificationRepository.listByEmployee(employeeId);
    final existingLinks = existing.map((e) => e.deepLink).toSet();
    final feedItems = [...news, ...announcements, ...lifeEvents];

    for (final item in feedItems) {
      final deepLink = item.type == FeedType.lifeEvent ? '/life-events/${item.id}' : '/feed/${item.id}';
      if (existingLinks.contains(deepLink)) continue;
      await _notificationRepository.add(
        AppNotification(
          id: 'notif-${_uuid.v4()}',
          employeeId: employeeId,
          title: _notificationTitle(item),
          body: _notificationBody(item),
          deepLink: deepLink,
          createdAt: item.createdAt,
          avatarLabel: _notificationAvatarLabel(item),
          detail: item.type == FeedType.lifeEvent
              ? 'Category: ${_lifeEventLabel(item)}'
              : item.type == FeedType.news
                  ? 'Category: News'
                  : 'Category: Announcement',
        ),
      );
      existingLinks.add(deepLink);
    }
  }

  String _notificationTitle(FeedItem item) {
    if (item.type == FeedType.news) return 'News Update';
    if (item.type == FeedType.announcement) return 'Announcement';
    return switch (item.lifeEventCategory) {
      LifeEventCategory.birthday => 'Birthday Celebration',
      LifeEventCategory.birth => 'Birth Announcement',
      LifeEventCategory.marriage => 'Wedding Announcement',
      LifeEventCategory.condolence => 'Condolence Notice',
      null => 'Life Event',
    };
  }

  String _notificationBody(FeedItem item) {
    if (item.type != FeedType.lifeEvent) return item.title;
    final relatedName = item.relatedEmployeeName ?? 'Employee';
    return switch (item.lifeEventCategory) {
      LifeEventCategory.birthday => '$relatedName is celebrating a birthday.',
      LifeEventCategory.birth => '$relatedName and family are welcoming a new baby.',
      LifeEventCategory.marriage => '$relatedName is celebrating a wedding event.',
      LifeEventCategory.condolence => 'Condolence support for $relatedName and family.',
      null => item.title,
    };
  }

  String _notificationAvatarLabel(FeedItem item) {
    if (item.type == FeedType.news) return 'NW';
    if (item.type == FeedType.announcement) return 'AN';
    return switch (item.lifeEventCategory) {
      LifeEventCategory.birthday => 'BD',
      LifeEventCategory.birth => 'BR',
      LifeEventCategory.marriage => 'WD',
      LifeEventCategory.condolence => 'CD',
      null => 'EV',
    };
  }

  String _lifeEventLabel(FeedItem item) {
    return switch (item.lifeEventCategory) {
      LifeEventCategory.birthday => 'Birthday',
      LifeEventCategory.birth => 'Birth',
      LifeEventCategory.marriage => 'Wedding',
      LifeEventCategory.condolence => 'Condolence',
      null => 'Life Event',
    };
  }
}
