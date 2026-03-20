import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../domain/contracts/repositories.dart';
import '../../domain/models/entities.dart';
import '../mock/mock_seed.dart';

class MockRepositories {
  final AuthRepository authRepository;
  final EmployeeRepository employeeRepository;
  final BranchRepository branchRepository;
  final AttendanceRepository attendanceRepository;
  final RequestRepository requestRepository;
  final ProfileRepository profileRepository;
  final FeedRepository feedRepository;
  final NotificationRepository notificationRepository;

  MockRepositories({
    required this.authRepository,
    required this.employeeRepository,
    required this.branchRepository,
    required this.attendanceRepository,
    required this.requestRepository,
    required this.profileRepository,
    required this.feedRepository,
    required this.notificationRepository,
  });

  static MockRepositories fromSeed(MockSeedData seed) {
    final notificationsRepo = InMemoryNotificationRepository(seed.notifications);
    return MockRepositories(
      authRepository: MockAuthRepository(seed.currentEmployee.id),
      employeeRepository: InMemoryEmployeeRepository(seed.currentEmployee),
      branchRepository: InMemoryBranchRepository(seed.branches),
      attendanceRepository: InMemoryAttendanceRepository(
        history: seed.attendance,
        corrections: seed.corrections,
      ),
      requestRepository: InMemoryRequestRepository(seed.requests),
      profileRepository: InMemoryProfileRepository(seed.profile),
      feedRepository: InMemoryFeedRepository(seed.feeds),
      notificationRepository: notificationsRepo,
    );
  }
}

class MockAuthRepository implements AuthRepository {
  static const _sessionKey = 'workpulse_session';
  final String defaultEmployeeId;
  String _otp = '1234';

  MockAuthRepository(this.defaultEmployeeId);

  @override
  Future<String?> currentEmployeeId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sessionKey);
  }

  @override
  Future<bool> isLoggedIn() async {
    final id = await currentEmployeeId();
    return id != null;
  }

  @override
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  @override
  Future<void> persistSession(String employeeId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, employeeId);
  }

  @override
  Future<void> requestOtp(String phone) async {
    _otp = '1234';
  }

  @override
  Future<bool> verifyOtp(String phone, String otp) async {
    if (otp == _otp) {
      await persistSession(defaultEmployeeId);
      return true;
    }
    return false;
  }
}

class InMemoryEmployeeRepository implements EmployeeRepository {
  Employee currentEmployee;
  final List<Employee> _employees;

  InMemoryEmployeeRepository(this.currentEmployee, [List<Employee> employees = const []])
      : _employees = employees.isEmpty ? [currentEmployee] : employees;

  @override
  Future<Employee> getCurrentEmployee() async => currentEmployee;

  @override
  Future<List<Employee>> listTeamMembers(Employee employee) async {
    if (employee.managerId != null) {
      final sameManager = _employees
          .where((item) => item.id != employee.id && item.managerId == employee.managerId)
          .toList();
      if (sameManager.isNotEmpty) return sameManager;
    }
    final directReports = _employees
        .where((item) => item.id != employee.id && item.managerId == employee.id)
        .toList();
    if (directReports.isNotEmpty) return directReports;
    return _employees
        .where((item) => item.id != employee.id && item.department == employee.department)
        .toList();
  }
}

class InMemoryBranchRepository implements BranchRepository {
  final List<Branch> branches;

  InMemoryBranchRepository(this.branches);

  @override
  Future<List<Branch>> getBranches() async => List.unmodifiable(branches);
}

class InMemoryAttendanceRepository implements AttendanceRepository {
  final Uuid _uuid = const Uuid();
  final List<AttendanceRecord> _history;
  final List<AttendanceCorrection> _corrections;

  InMemoryAttendanceRepository({
    required List<AttendanceRecord> history,
    required List<AttendanceCorrection> corrections,
  })  : _history = [...history],
        _corrections = [...corrections];

  @override
  Future<AttendanceRecord> addRecord(
    String employeeId,
    AttendanceType type,
    DateTime timestamp,
  ) async {
    final record = AttendanceRecord(
      id: _uuid.v4(),
      employeeId: employeeId,
      timestamp: timestamp,
      type: type,
    );
    _history.insert(0, record);
    return record;
  }

  @override
  Future<AttendanceCorrection> createCorrection(
    String employeeId,
    DateTime date,
    AttendanceCorrectionType correctionType,
    String reason,
  ) async {
    final correction = AttendanceCorrection(
      id: _uuid.v4(),
      employeeId: employeeId,
      date: date,
      correctionType: correctionType,
      reason: reason,
      status: AttendanceCorrectionStatus.pending,
    );
    _corrections.insert(0, correction);
    return correction;
  }

  @override
  Future<List<AttendanceCorrection>> getCorrections(String employeeId) async {
    return _corrections.where((e) => e.employeeId == employeeId).toList();
  }

  @override
  Future<List<AttendanceRecord>> getHistory(String employeeId) async {
    return _history.where((e) => e.employeeId == employeeId).toList();
  }
}

class InMemoryRequestRepository implements RequestRepository {
  final List<HrRequest> _requests;

  InMemoryRequestRepository(List<HrRequest> requests) : _requests = [...requests];

  @override
  Future<void> cancel(String requestId) async {
    final index = _requests.indexWhere((e) => e.id == requestId);
    if (index >= 0) {
      _requests[index] = _requests[index].copyWith(status: RequestStatus.canceled);
    }
  }

  @override
  Future<HrRequest> create(HrRequest request) async {
    _requests.insert(0, request);
    return request;
  }

  @override
  Future<void> delete(String requestId) async {
    _requests.removeWhere((e) => e.id == requestId);
  }

  @override
  Future<List<HrRequest>> listByEmployee(String employeeId) async {
    return _requests.where((e) => e.employeeId == employeeId).toList();
  }

  @override
  Future<List<HrRequest>> listApprovals(String approverEmployeeId) async {
    return _requests
        .where(
          (e) =>
              e.status == RequestStatus.submitted &&
              (e.type == RequestType.leave || e.type == RequestType.permission || e.type == RequestType.wfa),
        )
        .toList();
  }

  @override
  Future<List<HrRequest>> listTeamRequestsForApprover(String approverEmployeeId) async {
    return _requests
        .where(
          (e) =>
              (e.status == RequestStatus.submitted || e.status == RequestStatus.approved) &&
              (e.type == RequestType.leave || e.type == RequestType.permission || e.type == RequestType.wfa),
        )
        .toList();
  }

  @override
  Future<HrRequest> update(HrRequest request) async {
    final index = _requests.indexWhere((e) => e.id == request.id);
    if (index >= 0) {
      _requests[index] = request;
    }
    return request;
  }

  @override
  Future<MedicalAttachment> uploadAttachment({
    required String employeeId,
    required String requestCategory,
    required String fileName,
    required List<int> bytes,
    required String contentType,
  }) async {
    return MedicalAttachment(
      id: const Uuid().v4(),
      path: 'mock://$requestCategory/$fileName',
      state: UploadState.uploaded,
    );
  }
}

class InMemoryProfileRepository implements ProfileRepository {
  Profile _profile;
  InMemoryProfileRepository(this._profile);

  @override
  Future<Profile> get(String employeeId) async => _profile;

  @override
  Future<Profile> update(Profile profile) async {
    _profile = profile;
    return _profile;
  }
}

class InMemoryFeedRepository implements FeedRepository {
  final List<FeedItem> _items;

  InMemoryFeedRepository(List<FeedItem> items) : _items = [...items];

  @override
  Future<FeedComment> addComment(String itemId, FeedComment comment) async {
    final i = _items.indexWhere((e) => e.id == itemId);
    _items[i] = _items[i].copyWith(comments: [..._items[i].comments, comment]);
    return comment;
  }

  @override
  Future<void> deleteComment(String itemId, String commentId) async {
    final i = _items.indexWhere((e) => e.id == itemId);
    final updated = _items[i].comments.where((c) => c.id != commentId).toList();
    _items[i] = _items[i].copyWith(comments: updated);
  }

  @override
  Future<FeedItem> getById(String id) async => _items.firstWhere((e) => e.id == id);

  @override
  Future<List<FeedItem>> list(FeedType type) async {
    final list = _items.where((e) => e.type == type).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<FeedItem> toggleLike(String itemId, String employeeId) async {
    final i = _items.indexWhere((e) => e.id == itemId);
    final likes = {..._items[i].likedByEmployeeIds};
    if (likes.contains(employeeId)) {
      likes.remove(employeeId);
    } else {
      likes.add(employeeId);
    }
    _items[i] = _items[i].copyWith(likedByEmployeeIds: likes);
    return _items[i];
  }

  @override
  Future<FeedComment> updateComment(String itemId, FeedComment comment) async {
    final i = _items.indexWhere((e) => e.id == itemId);
    final comments = [..._items[i].comments];
    final cIndex = comments.indexWhere((e) => e.id == comment.id);
    if (cIndex >= 0) {
      comments[cIndex] = comment;
    }
    _items[i] = _items[i].copyWith(comments: comments);
    return comment;
  }
}

class InMemoryNotificationRepository implements NotificationRepository {
  final List<AppNotification> _notifications;
  InMemoryNotificationRepository(List<AppNotification> notifications)
      : _notifications = [...notifications];

  @override
  Future<AppNotification> add(AppNotification notification) async {
    _notifications.insert(0, notification);
    return notification;
  }

  @override
  Future<List<AppNotification>> listByEmployee(String employeeId) async {
    final list = _notifications.where((e) => e.employeeId == employeeId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<void> markRead(String notificationId) async {
    final i = _notifications.indexWhere((e) => e.id == notificationId);
    if (i >= 0) {
      _notifications[i] = _notifications[i].copyWith(read: true);
    }
  }
}
