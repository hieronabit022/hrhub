import '../models/entities.dart';

abstract class AuthRepository {
  Future<void> requestOtp(String phone);
  Future<bool> verifyOtp(String phone, String otp);
  Future<bool> isLoggedIn();
  Future<void> persistSession(String employeeId);
  Future<void> clearSession();
  Future<String?> currentEmployeeId();
}

abstract class EmployeeRepository {
  Future<Employee> getCurrentEmployee();
  Future<List<Employee>> listTeamMembers(Employee employee);
}

abstract class BranchRepository {
  Future<List<Branch>> getBranches();
}

abstract class AttendanceRepository {
  Future<List<AttendanceRecord>> getHistory(String employeeId);
  Future<AttendanceRecord> addRecord(
    String employeeId,
    AttendanceType type,
    DateTime timestamp,
  );
  Future<List<AttendanceCorrection>> getCorrections(String employeeId);
  Future<AttendanceCorrection> createCorrection(
    String employeeId,
    DateTime date,
    AttendanceCorrectionType correctionType,
    String reason,
  );
}

abstract class RequestRepository {
  Future<List<HrRequest>> listByEmployee(String employeeId);
  Future<List<HrRequest>> listApprovals(String approverEmployeeId);
  Future<List<HrRequest>> listTeamRequestsForApprover(String approverEmployeeId);
  Future<HrRequest> create(HrRequest request);
  Future<HrRequest> update(HrRequest request);
  Future<void> delete(String requestId);
  Future<void> cancel(String requestId);
  Future<MedicalAttachment> uploadAttachment({
    required String employeeId,
    required String requestCategory,
    required String fileName,
    required List<int> bytes,
    required String contentType,
  });
}

abstract class ProfileRepository {
  Future<Profile> get(String employeeId);
  Future<Profile> update(Profile profile);
}

abstract class FeedRepository {
  Future<List<FeedItem>> list(FeedType type);
  Future<FeedItem> getById(String id);
  Future<FeedComment> addComment(String itemId, FeedComment comment);
  Future<FeedComment> updateComment(String itemId, FeedComment comment);
  Future<void> deleteComment(String itemId, String commentId);
  Future<FeedItem> toggleLike(String itemId, String employeeId);
}

abstract class NotificationRepository {
  Future<List<AppNotification>> listByEmployee(String employeeId);
  Future<AppNotification> add(AppNotification notification);
  Future<void> markRead(String notificationId);
}
