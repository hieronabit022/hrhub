import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../domain/contracts/repositories.dart';
import '../../domain/models/entities.dart';

class FeedController extends ChangeNotifier {
  final FeedRepository _feedRepository;
  final Uuid _uuid = const Uuid();

  FeedController(this._feedRepository, NotificationRepository _);

  String employeeId = 'emp-1';
  List<FeedItem> news = [];
  List<FeedItem> announcements = [];
  List<FeedItem> lifeEvents = [];

  Future<void> loadAll([String? employee]) async {
    if (employee != null) employeeId = employee;
    news = await _feedRepository.list(FeedType.news);
    announcements = await _feedRepository.list(FeedType.announcement);
    lifeEvents = await _feedRepository.list(FeedType.lifeEvent);
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
}
