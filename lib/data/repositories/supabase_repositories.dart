import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../core/config/supabase_config.dart';
import '../../domain/contracts/repositories.dart';
import '../../domain/models/entities.dart';

class SupabaseRestClient {
  final http.Client _client;

  SupabaseRestClient([http.Client? client]) : _client = client ?? http.Client();

  Uri _uri(String table, [Map<String, String>? query]) {
    return Uri.parse('${SupabaseConfig.restBaseUrl}/$table').replace(queryParameters: query);
  }

  Future<dynamic> get(String table, {Map<String, String>? query}) async {
    final response = await _client.get(_uri(table, query), headers: SupabaseConfig.headers);
    _ensureSuccess(response);
    return jsonDecode(response.body);
  }

  Future<dynamic> post(String table, Map<String, dynamic> body) async {
    final response = await _client.post(
      _uri(table),
      headers: {
        ...SupabaseConfig.headers,
        'Prefer': 'return=representation',
      },
      body: jsonEncode(body),
    );
    _ensureSuccess(response);
    return jsonDecode(response.body);
  }

  Future<dynamic> patch(String table, Map<String, dynamic> body, {required Map<String, String> query}) async {
    final response = await _client.patch(
      _uri(table, query),
      headers: {
        ...SupabaseConfig.headers,
        'Prefer': 'return=representation',
      },
      body: jsonEncode(body),
    );
    _ensureSuccess(response);
    return response.body.isEmpty ? [] : jsonDecode(response.body);
  }

  Future<void> delete(String table, {required Map<String, String> query}) async {
    final response = await _client.delete(_uri(table, query), headers: SupabaseConfig.headers);
    _ensureSuccess(response);
  }

  Future<void> uploadObject({
    required String bucket,
    required String objectPath,
    required List<int> bytes,
    required String contentType,
  }) async {
    final response = await _client.post(
      Uri.parse('${SupabaseConfig.storageBaseUrl}/object/$bucket/$objectPath'),
      headers: {
        ...SupabaseConfig.headers,
        'Content-Type': contentType,
        'x-upsert': 'true',
      },
      body: bytes,
    );
    _ensureSuccess(response);
  }

  String publicObjectUrl({
    required String bucket,
    required String objectPath,
  }) {
    return '${SupabaseConfig.storageBaseUrl}/object/public/$bucket/$objectPath';
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw Exception('Supabase request failed: ${response.statusCode} ${response.body}');
  }
}

class SupabaseAuthRepository implements AuthRepository {
  static const _sessionKey = 'workpulse_session';
  final SupabaseRestClient _client;

  SupabaseAuthRepository(this._client);

  @override
  Future<String?> currentEmployeeId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sessionKey);
  }

  @override
  Future<bool> isLoggedIn() async => (await currentEmployeeId()) != null;

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
    await _client.get(
      'profiles',
      query: {
        'select': 'employee_id',
        'phone': 'eq.$phone',
        'limit': '1',
      },
    );
  }

  @override
  Future<bool> verifyOtp(String phone, String otp) async {
    if (otp != '1234') return false;
    final rows = await _client.get(
      'profiles',
      query: {
        'select': 'employee_id',
        'phone': 'eq.$phone',
        'limit': '1',
      },
    ) as List<dynamic>;
    if (rows.isEmpty) return false;
    await persistSession(rows.first['employee_id'] as String);
    return true;
  }
}

class SupabaseEmployeeRepository implements EmployeeRepository {
  final SupabaseRestClient _client;
  final AuthRepository _authRepository;

  SupabaseEmployeeRepository(this._client, this._authRepository);

  @override
  Future<Employee> getCurrentEmployee() async {
    final employeeId = await _authRepository.currentEmployeeId();
    if (employeeId == null) {
      throw StateError('No active employee session');
    }
    final rows = await _client.get(
      'employees',
      query: {
        'select': 'id,name,title,department,branch_id,initials,phone,avatar_url',
        'id': 'eq.$employeeId',
        'limit': '1',
      },
    ) as List<dynamic>;
    final row = rows.first;
    return Employee(
      id: row['id'] as String,
      name: row['name'] as String,
      title: row['title'] as String,
      department: row['department'] as String,
      branchId: row['branch_id'] as String,
      initials: row['initials'] as String,
      phone: row['phone'] as String,
      avatarUrl: row['avatar_url'] as String?,
    );
  }
}

class SupabaseBranchRepository implements BranchRepository {
  final SupabaseRestClient _client;

  SupabaseBranchRepository(this._client);

  @override
  Future<List<Branch>> getBranches() async {
    final rows = await _client.get(
      'branches',
      query: {'select': 'id,name,latitude,longitude,radius_meters'},
    ) as List<dynamic>;
    return rows
        .map(
          (row) => Branch(
            id: row['id'] as String,
            name: row['name'] as String,
            latitude: (row['latitude'] as num).toDouble(),
            longitude: (row['longitude'] as num).toDouble(),
            radiusMeters: (row['radius_meters'] as num).toDouble(),
          ),
        )
        .toList();
  }
}

class SupabaseAttendanceRepository implements AttendanceRepository {
  final SupabaseRestClient _client;

  SupabaseAttendanceRepository(this._client);

  @override
  Future<AttendanceRecord> addRecord(String employeeId, AttendanceType type, DateTime timestamp) async {
    final id = 'att-${DateTime.now().millisecondsSinceEpoch}';
    final rows = await _client.post('attendance_records', {
      'id': id,
      'employee_id': employeeId,
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
      'work_mode': null,
    }) as List<dynamic>;
    return _toAttendanceRecord(rows.first as Map<String, dynamic>);
  }

  @override
  Future<AttendanceCorrection> createCorrection(
    String employeeId,
    DateTime date,
    AttendanceCorrectionType correctionType,
    String reason,
  ) async {
    final id = 'cor-${DateTime.now().millisecondsSinceEpoch}';
    final rows = await _client.post('attendance_corrections', {
      'id': id,
      'employee_id': employeeId,
      'date': date.toIso8601String(),
      'correction_type': correctionType.name,
      'reason': reason,
      'status': AttendanceCorrectionStatus.pending.name,
    }) as List<dynamic>;
    return _toAttendanceCorrection(rows.first as Map<String, dynamic>);
  }

  @override
  Future<List<AttendanceCorrection>> getCorrections(String employeeId) async {
    final rows = await _client.get(
      'attendance_corrections',
      query: {
        'select': 'id,employee_id,date,correction_type,reason,status',
        'employee_id': 'eq.$employeeId',
        'order': 'date.desc',
      },
    ) as List<dynamic>;
    return rows.map((row) => _toAttendanceCorrection(row as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<AttendanceRecord>> getHistory(String employeeId) async {
    final rows = await _client.get(
      'attendance_records',
      query: {
        'select': 'id,employee_id,timestamp,type',
        'employee_id': 'eq.$employeeId',
        'order': 'timestamp.desc',
      },
    ) as List<dynamic>;
    return rows.map((row) => _toAttendanceRecord(row as Map<String, dynamic>)).toList();
  }

  AttendanceRecord _toAttendanceRecord(Map<String, dynamic> row) {
    return AttendanceRecord(
      id: row['id'] as String,
      employeeId: row['employee_id'] as String,
      timestamp: DateTime.parse(row['timestamp'] as String),
      type: _attendanceTypeFromString(row['type'] as String),
    );
  }

  AttendanceCorrection _toAttendanceCorrection(Map<String, dynamic> row) {
    return AttendanceCorrection(
      id: row['id'] as String,
      employeeId: row['employee_id'] as String,
      date: DateTime.parse(row['date'] as String),
      correctionType: _attendanceCorrectionTypeFromString(
        (row['correction_type'] as String?) ??
            _inferCorrectionType(row['reason'] as String).name,
      ),
      reason: row['reason'] as String,
      status: _attendanceCorrectionStatusFromString(row['status'] as String),
    );
  }
}

class SupabaseRequestRepository implements RequestRepository {
  final SupabaseRestClient _client;
  final Uuid _uuid = const Uuid();

  SupabaseRequestRepository(this._client);

  @override
  Future<void> cancel(String requestId) async {
    await patchStatus(requestId, RequestStatus.canceled);
  }

  @override
  Future<HrRequest> create(HrRequest request) async {
    final approverEmployeeId = await _lookupApproverEmployeeId(request.employeeId);
    final rows = await _client.post('requests', {
      ..._requestToMap(request),
      'approver_employee_id': approverEmployeeId,
    }) as List<dynamic>;
    return _toRequest(rows.first as Map<String, dynamic>);
  }

  @override
  Future<void> delete(String requestId) async {
    await _client.delete('requests', query: {'id': 'eq.$requestId'});
  }

  @override
  Future<List<HrRequest>> listByEmployee(String employeeId) async {
    final rows = await _client.get(
      'requests',
      query: {
        'select': '*',
        'employee_id': 'eq.$employeeId',
        'order': 'created_at.desc',
      },
    ) as List<dynamic>;
    return rows.map((row) => _toRequest(row as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<HrRequest>> listApprovals(String approverEmployeeId) async {
    final rows = await _client.get(
      'requests',
      query: {
        'select': '*',
        'approver_employee_id': 'eq.$approverEmployeeId',
        'status': 'eq.submitted',
        'type': 'in.(leave,permission,wfa)',
        'order': 'created_at.desc',
      },
    ) as List<dynamic>;
    return rows.map((row) => _toRequest(row as Map<String, dynamic>)).toList();
  }

  @override
  Future<HrRequest> update(HrRequest request) async {
    final rows = await _client.patch(
      'requests',
      _requestToMap(request),
      query: {'id': 'eq.${request.id}'},
    ) as List<dynamic>;
    return _toRequest(rows.first as Map<String, dynamic>);
  }

  @override
  Future<MedicalAttachment> uploadAttachment({
    required String employeeId,
    required String requestCategory,
    required String fileName,
    required List<int> bytes,
    required String contentType,
  }) async {
    final attachmentId = _uuid.v4();
    final extension = _fileExtension(fileName);
    final safeCategory = requestCategory.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final objectPath = 'employees/$employeeId/$safeCategory/$attachmentId$extension';
    await _client.uploadObject(
      bucket: SupabaseConfig.requestAttachmentBucket,
      objectPath: objectPath,
      bytes: bytes,
      contentType: contentType,
    );
    return MedicalAttachment(
      id: attachmentId,
      path: _client.publicObjectUrl(
        bucket: SupabaseConfig.requestAttachmentBucket,
        objectPath: objectPath,
      ),
      state: UploadState.uploaded,
    );
  }

  Future<void> patchStatus(String requestId, RequestStatus status) async {
    await _client.patch('requests', {'status': status.name}, query: {'id': 'eq.$requestId'});
  }

  Future<String?> _lookupApproverEmployeeId(String employeeId) async {
    final rows = await _client.get(
      'employees',
      query: {
        'select': 'manager_id',
        'id': 'eq.$employeeId',
        'limit': '1',
      },
    ) as List<dynamic>;
    if (rows.isEmpty) return null;
    return rows.first['manager_id'] as String?;
  }

  Map<String, dynamic> _requestToMap(HrRequest request) {
    return {
      'id': request.id,
      'employee_id': request.employeeId,
      'type': request.type.name,
      'leave_category': request.leaveCategory?.name,
      'title': request.title,
      'description': request.description,
      'created_at': request.createdAt.toIso8601String(),
      'status': request.status.name,
      'attachments_json': request.attachments
          .map((e) => {'id': e.id, 'path': e.path, 'state': e.state.name})
          .toList(),
    };
  }

  HrRequest _toRequest(Map<String, dynamic> row) {
    final attachments = (row['attachments_json'] as List<dynamic>? ?? const [])
        .map(
          (e) => MedicalAttachment(
            id: e['id'] as String,
            path: e['path'] as String,
            state: _uploadStateFromString(e['state'] as String),
          ),
        )
        .toList();

    return HrRequest(
      id: row['id'] as String,
      employeeId: row['employee_id'] as String,
      type: _requestTypeFromString(row['type'] as String),
      leaveCategory: row['leave_category'] == null ? null : _leaveCategoryFromString(row['leave_category'] as String),
      title: row['title'] as String,
      description: row['description'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
      status: _requestStatusFromString(row['status'] as String),
      attachments: attachments,
    );
  }
}

String _fileExtension(String fileName) {
  final index = fileName.lastIndexOf('.');
  if (index < 0) return '';
  return fileName.substring(index);
}

class SupabaseProfileRepository implements ProfileRepository {
  final SupabaseRestClient _client;

  SupabaseProfileRepository(this._client);

  @override
  Future<Profile> get(String employeeId) async {
    final rows = await _client.get(
      'profiles',
      query: {
        'select': '*',
        'employee_id': 'eq.$employeeId',
        'limit': '1',
      },
    ) as List<dynamic>;
    return _toProfile(rows.first as Map<String, dynamic>);
  }

  @override
  Future<Profile> update(Profile profile) async {
    final rows = await _client.patch(
      'profiles',
      {
        'personal_email': profile.personalEmail,
        'emergency_contact': profile.emergencyContact,
        'address': profile.address,
        'phone': profile.phone,
      },
      query: {'employee_id': 'eq.${profile.employeeId}'},
    ) as List<dynamic>;
    return _toProfile(rows.first as Map<String, dynamic>);
  }

  Profile _toProfile(Map<String, dynamic> row) {
    return Profile(
      employeeId: row['employee_id'] as String,
      personalEmail: row['personal_email'] as String,
      emergencyContact: row['emergency_contact'] as String,
      address: row['address'] as String,
      employmentStatus: row['employment_status'] as String,
      jobTitle: row['job_title'] as String,
      department: row['department'] as String,
      phone: row['phone'] as String,
    );
  }
}

class SupabaseFeedRepository implements FeedRepository {
  final SupabaseRestClient _client;

  SupabaseFeedRepository(this._client);

  @override
  Future<FeedComment> addComment(String itemId, FeedComment comment) async {
    final rows = await _client.post('feed_comments', {
      'id': comment.id,
      'item_id': itemId,
      'employee_id': comment.employeeId,
      'content': comment.content,
      'created_at': comment.createdAt.toIso8601String(),
    }) as List<dynamic>;
    return _toComment(rows.first as Map<String, dynamic>);
  }

  @override
  Future<void> deleteComment(String itemId, String commentId) async {
    await _client.delete('feed_comments', query: {'id': 'eq.$commentId'});
  }

  @override
  Future<FeedItem> getById(String id) async {
    final rows = await _client.get(
      'feed_items',
      query: {
        'select': '*',
        'id': 'eq.$id',
        'limit': '1',
      },
    ) as List<dynamic>;
    return _enrichItem(rows.first as Map<String, dynamic>);
  }

  @override
  Future<List<FeedItem>> list(FeedType type) async {
    final rows = await _client.get(
      'feed_items',
      query: {
        'select': '*',
        'type': 'eq.${_feedTypeToString(type)}',
        'order': 'created_at.desc',
      },
    ) as List<dynamic>;
    return Future.wait(rows.map((row) => _enrichItem(row as Map<String, dynamic>)));
  }

  @override
  Future<FeedItem> toggleLike(String itemId, String employeeId) async {
    final rows = await _client.get(
      'feed_likes',
      query: {
        'select': 'item_id,employee_id',
        'item_id': 'eq.$itemId',
        'employee_id': 'eq.$employeeId',
      },
    ) as List<dynamic>;
    if (rows.isNotEmpty) {
      await _client.delete(
        'feed_likes',
        query: {
          'item_id': 'eq.$itemId',
          'employee_id': 'eq.$employeeId',
        },
      );
    } else {
      await _client.post('feed_likes', {
        'item_id': itemId,
        'employee_id': employeeId,
      });
    }
    return getById(itemId);
  }

  @override
  Future<FeedComment> updateComment(String itemId, FeedComment comment) async {
    final rows = await _client.patch(
      'feed_comments',
      {'content': comment.content},
      query: {'id': 'eq.${comment.id}'},
    ) as List<dynamic>;
    return _toComment(rows.first as Map<String, dynamic>);
  }

  Future<FeedItem> _enrichItem(Map<String, dynamic> row) async {
    final commentsRows = await _client.get(
      'feed_comments',
      query: {
        'select': 'id,item_id,employee_id,content,created_at',
        'item_id': 'eq.${row['id']}',
        'order': 'created_at.asc',
      },
    ) as List<dynamic>;
    final likesRows = await _client.get(
      'feed_likes',
      query: {
        'select': 'employee_id',
        'item_id': 'eq.${row['id']}',
      },
    ) as List<dynamic>;
    final commentEmployeeIds = commentsRows
        .map((e) => (e as Map<String, dynamic>)['employee_id'] as String)
        .toSet()
        .toList();
    final employeeRows = commentEmployeeIds.isEmpty
        ? const <dynamic>[]
        : await _client.get(
            'employees',
            query: {
              'select': 'id,name,initials,avatar_url',
              'id': 'in.(${commentEmployeeIds.join(',')})',
            },
          ) as List<dynamic>;
    final employeeMap = <String, Map<String, dynamic>>{
      for (final row in employeeRows) (row as Map<String, dynamic>)['id'] as String: row,
    };
    Map<String, dynamic>? relatedEmployeeRow;
    final relatedEmployeeName = row['related_employee_name'] as String?;
    if (relatedEmployeeName != null && relatedEmployeeName.isNotEmpty) {
      final relatedRows = await _client.get(
        'employees',
        query: {
          'select': 'id,name,initials,avatar_url',
          'name': 'eq.$relatedEmployeeName',
          'limit': '1',
        },
      ) as List<dynamic>;
      if (relatedRows.isNotEmpty) {
        relatedEmployeeRow = relatedRows.first as Map<String, dynamic>;
      }
    }

    return FeedItem(
      id: row['id'] as String,
      type: _feedTypeFromString(row['type'] as String),
      title: row['title'] as String,
      content: row['content'] as String,
      author: row['author'] as String,
      coverImage: row['cover_image'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      lifeEventCategory: row['life_event_category'] == null
          ? null
          : _lifeEventCategoryFromString(row['life_event_category'] as String),
      relatedEmployeeName: relatedEmployeeName,
      relatedEmployeeAvatarUrl: relatedEmployeeRow?['avatar_url'] as String?,
      relatedEmployeeInitials: relatedEmployeeRow?['initials'] as String?,
      comments: commentsRows
          .map((e) => _toComment(
                e as Map<String, dynamic>,
                employeeMap[(e)['employee_id'] as String],
              ))
          .toList(),
      likedByEmployeeIds: likesRows.map((e) => (e as Map<String, dynamic>)['employee_id'] as String).toSet(),
    );
  }

  FeedComment _toComment(
    Map<String, dynamic> row, [
    Map<String, dynamic>? employeeRow,
  ]) {
    return FeedComment(
      id: row['id'] as String,
      itemId: row['item_id'] as String,
      employeeId: row['employee_id'] as String,
      content: row['content'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
      authorName: employeeRow?['name'] as String?,
      authorInitials: employeeRow?['initials'] as String?,
      authorAvatarUrl: employeeRow?['avatar_url'] as String?,
    );
  }
}

class SupabaseNotificationRepository implements NotificationRepository {
  final SupabaseRestClient _client;

  SupabaseNotificationRepository(this._client);

  @override
  Future<AppNotification> add(AppNotification notification) async {
    final rows = await _client.post('notifications', {
      'id': notification.id,
      'employee_id': notification.employeeId,
      'title': notification.title,
      'body': notification.body,
      'deep_link': notification.deepLink,
      'created_at': notification.createdAt.toIso8601String(),
      'is_read': notification.read,
      'avatar_label': notification.avatarLabel,
      'detail': notification.detail,
    }) as List<dynamic>;
    return _toNotification(rows.first as Map<String, dynamic>);
  }

  @override
  Future<List<AppNotification>> listByEmployee(String employeeId) async {
    final rows = await _client.get(
      'notifications',
      query: {
        'select': '*',
        'employee_id': 'eq.$employeeId',
        'order': 'is_read.asc,created_at.desc',
      },
    ) as List<dynamic>;
    return rows.map((row) => _toNotification(row as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> markRead(String notificationId) async {
    await _client.patch('notifications', {'is_read': true}, query: {'id': 'eq.$notificationId'});
  }

  AppNotification _toNotification(Map<String, dynamic> row) {
    return AppNotification(
      id: row['id'] as String,
      employeeId: row['employee_id'] as String,
      title: row['title'] as String,
      body: row['body'] as String,
      deepLink: row['deep_link'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
      read: row['is_read'] as bool? ?? false,
      avatarLabel: row['avatar_label'] as String?,
      detail: row['detail'] as String?,
    );
  }
}

RequestType _requestTypeFromString(String value) {
  return RequestType.values.firstWhere((e) => e.name == value);
}

LeaveCategory _leaveCategoryFromString(String value) {
  return LeaveCategory.values.firstWhere((e) => e.name == value);
}

RequestStatus _requestStatusFromString(String value) {
  return RequestStatus.values.firstWhere((e) => e.name == value);
}

AttendanceType _attendanceTypeFromString(String value) {
  return AttendanceType.values.firstWhere((e) => e.name == value);
}

AttendanceCorrectionStatus _attendanceCorrectionStatusFromString(String value) {
  return AttendanceCorrectionStatus.values.firstWhere((e) => e.name == value);
}

AttendanceCorrectionType _attendanceCorrectionTypeFromString(String value) {
  return AttendanceCorrectionType.values.firstWhere((e) => e.name == value);
}

AttendanceCorrectionType _inferCorrectionType(String reason) {
  final normalized = reason.toLowerCase();
  if (normalized.contains('both')) {
    return AttendanceCorrectionType.both;
  }
  if (normalized.contains('check out') || normalized.contains('clock out')) {
    return AttendanceCorrectionType.checkOut;
  }
  return AttendanceCorrectionType.checkIn;
}

UploadState _uploadStateFromString(String value) {
  return UploadState.values.firstWhere((e) => e.name == value);
}

FeedType _feedTypeFromString(String value) {
  switch (value) {
    case 'news':
      return FeedType.news;
    case 'announcement':
      return FeedType.announcement;
    default:
      return FeedType.lifeEvent;
  }
}

String _feedTypeToString(FeedType type) {
  switch (type) {
    case FeedType.news:
      return 'news';
    case FeedType.announcement:
      return 'announcement';
    case FeedType.lifeEvent:
      return 'lifeEvent';
  }
}

LifeEventCategory _lifeEventCategoryFromString(String value) {
  return LifeEventCategory.values.firstWhere((e) => e.name == value);
}
