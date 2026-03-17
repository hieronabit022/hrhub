import 'package:flutter_test/flutter_test.dart';
import 'package:workpulse/application/controllers/attendance_controller.dart';
import 'package:workpulse/application/controllers/feed_controller.dart';
import 'package:workpulse/application/controllers/notification_controller.dart';
import 'package:workpulse/application/controllers/profile_controller.dart';
import 'package:workpulse/application/controllers/request_controller.dart';
import 'package:workpulse/data/mock/mock_seed.dart';
import 'package:workpulse/data/repositories/mock_repositories.dart';
import 'package:workpulse/domain/models/entities.dart';

void main() {
group('WorkPulse save/edit/delete logic tests', () {
    late InMemoryRequestRepository requestRepo;
    late InMemoryNotificationRepository notificationRepo;
    late InMemoryAttendanceRepository attendanceRepo;
    late InMemoryProfileRepository profileRepo;
    late InMemoryFeedRepository feedRepo;

    late RequestController requestController;
    late AttendanceController attendanceController;
    late ProfileController profileController;
    late FeedController feedController;
    late NotificationController notificationController;

    setUp(() {
      final seed = MockSeed.build();
      requestRepo = InMemoryRequestRepository(seed.requests);
      notificationRepo = InMemoryNotificationRepository(seed.notifications);
      attendanceRepo = InMemoryAttendanceRepository(
        history: seed.attendance,
        corrections: seed.corrections,
      );
      profileRepo = InMemoryProfileRepository(seed.profile);
      feedRepo = InMemoryFeedRepository(seed.feeds);

      requestController = RequestController(requestRepo, notificationRepo);
      attendanceController = AttendanceController(attendanceRepo, InMemoryBranchRepository(seed.branches));
      profileController = ProfileController(profileRepo, notificationRepo);
      feedController = FeedController(feedRepo, notificationRepo);
      notificationController = NotificationController(notificationRepo);
    });

    test('create request + notification', () async {
      await requestController.load('emp-1');
      final before = requestController.requests.length;

      await requestController.create(
        type: RequestType.leave,
        title: 'Annual Leave',
        description: 'Family trip',
      );

      expect(requestController.requests.length, greaterThan(before));

      await notificationController.load('emp-1');
      expect(
        notificationController.notifications.any((n) => n.title.contains('Request Created')),
        isTrue,
      );
    });

    test('create attendance correction', () async {
      await attendanceController.load(employee: 'emp-1', branch: 'br-1');
      final before = attendanceController.corrections.length;

      await attendanceController.createCorrection(
        DateTime(2026, 3, 1),
        'Forgot check in',
      );

      expect(attendanceController.corrections.length, before + 1);
    });

    test('profile update personal/contact', () async {
      await profileController.load('emp-1');
      final p = profileController.profile!;
      final oldEmail = p.personalEmail;

      await profileController.updatePersonal(
      email: 'new.email@workpulse.local',
        address: p.address,
      );
      await profileController.updateContact(
        phone: '0811111111',
        emergencyContact: 'Budi',
      );

      expect(profileController.profile!.personalEmail, isNot(oldEmail));
      expect(profileController.profile!.phone, '0811111111');
      expect(profileController.profile!.emergencyContact, 'Budi');
    });

    test('comment edit/delete existing own comment and like toggle', () async {
      await feedController.loadAll('emp-1');
      final item = feedController.news.first;

      final myComment = item.comments.firstWhere((c) => c.employeeId == 'emp-1');

      await feedController.editComment(item.id, myComment.id, 'Updated comment');
      final afterEdit = await feedController.getById(item.id);
      expect(
        afterEdit.comments.firstWhere((c) => c.id == myComment.id).content,
        'Updated comment',
      );

      await feedController.deleteComment(item.id, myComment.id);
      final afterDelete = await feedController.getById(item.id);
      expect(afterDelete.comments.any((c) => c.id == myComment.id), isFalse);

      final beforeLike = afterDelete.likedByEmployeeIds.contains('emp-1');
      await feedController.toggleLike(item.id);
      final afterLikeItem = await feedController.getById(item.id);
      expect(afterLikeItem.likedByEmployeeIds.contains('emp-1'), isNot(beforeLike));
    });

    test('create comment on feed item without own comment', () async {
      await feedController.loadAll('emp-1');
      final target = feedController.announcements.first;

      final beforeCount = target.comments.length;
      await feedController.addComment(target.id, 'Thanks for the update');

      final updated = await feedController.getById(target.id);
      expect(updated.comments.length, beforeCount + 1);
      expect(
        updated.comments.any((c) => c.employeeId == 'emp-1' && c.content == 'Thanks for the update'),
        isTrue,
      );
    });

    test('request delete and remove attachment local state', () async {
      final attachments = [
        const MedicalAttachment(
          id: 'm1',
          path: 'mock/a.jpg',
          state: UploadState.uploaded,
        ),
        const MedicalAttachment(
          id: 'm2',
          path: 'mock/b.jpg',
          state: UploadState.uploaded,
        ),
      ];

      final updated = requestController.removeAttachment(attachments, 'm1');
      expect(updated.length, 1);
      expect(updated.first.id, 'm2');

      await requestController.load('emp-1');
      await requestController.create(
        type: RequestType.permission,
        title: 'Errand',
        description: 'Short permit',
      );
      final createdId = requestController.requests.first.id;
      await requestController.delete(createdId);
      expect(requestController.requests.any((r) => r.id == createdId), isFalse);
    });

    test('notification mark as read', () async {
      await notificationController.load('emp-1');
      final target = notificationController.notifications.first;
      expect(target.read, isFalse);

      await notificationController.markRead(target.id);
      final updated = notificationController.notifications.firstWhere((n) => n.id == target.id);
      expect(updated.read, isTrue);
    });

    test('wfo/wfa label logic returns expected enum-like value', () async {
      await attendanceController.load(employee: 'emp-1', branch: 'br-1');
      final label = await attendanceController.wfoWfaLabel();
      expect(label == 'WFO' || label == 'WFA', isTrue);
    });
  });
}
