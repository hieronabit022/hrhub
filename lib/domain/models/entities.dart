enum RequestType { leave, permission, wfa, medicalClaim }

enum LeaveCategory { annual, special }

enum RequestStatus { draft, submitted, approved, rejected, canceled }

enum AttendanceType { checkIn, checkOut }

enum AttendanceCorrectionStatus { pending, approved, rejected }

enum AttendanceCorrectionType { checkIn, checkOut, both }

enum UploadState { uploading, uploaded, failed }

enum FeedType { news, announcement, lifeEvent }

enum LifeEventCategory { birthday, marriage, birth, condolence }

class Employee {
  final String id;
  final String name;
  final String title;
  final String department;
  final String branchId;
  final String? managerId;
  final String initials;
  final String phone;
  final String? avatarUrl;

  const Employee({
    required this.id,
    required this.name,
    required this.title,
    required this.department,
    required this.branchId,
    this.managerId,
    required this.initials,
    required this.phone,
    this.avatarUrl,
  });
}

class Branch {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;

  const Branch({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
  });
}

class AttendanceRecord {
  final String id;
  final String employeeId;
  final DateTime timestamp;
  final AttendanceType type;

  const AttendanceRecord({
    required this.id,
    required this.employeeId,
    required this.timestamp,
    required this.type,
  });
}

class AttendanceCorrection {
  final String id;
  final String employeeId;
  final DateTime date;
  final AttendanceCorrectionType correctionType;
  final String reason;
  final AttendanceCorrectionStatus status;

  const AttendanceCorrection({
    required this.id,
    required this.employeeId,
    required this.date,
    required this.correctionType,
    required this.reason,
    required this.status,
  });

  AttendanceCorrection copyWith({
    AttendanceCorrectionType? correctionType,
    String? reason,
    AttendanceCorrectionStatus? status,
  }) {
    return AttendanceCorrection(
      id: id,
      employeeId: employeeId,
      date: date,
      correctionType: correctionType ?? this.correctionType,
      reason: reason ?? this.reason,
      status: status ?? this.status,
    );
  }
}

class MedicalAttachment {
  final String id;
  final String path;
  final UploadState state;

  const MedicalAttachment({
    required this.id,
    required this.path,
    required this.state,
  });

  MedicalAttachment copyWith({UploadState? state}) {
    return MedicalAttachment(
      id: id,
      path: path,
      state: state ?? this.state,
    );
  }
}

class HrRequest {
  final String id;
  final String employeeId;
  final RequestType type;
  final LeaveCategory? leaveCategory;
  final String title;
  final String description;
  final DateTime createdAt;
  final RequestStatus status;
  final List<MedicalAttachment> attachments;
  final String? requesterName;
  final String? requesterDepartment;
  final String? requesterInitials;
  final String? requesterAvatarUrl;

  const HrRequest({
    required this.id,
    required this.employeeId,
    required this.type,
    this.leaveCategory,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.status,
    this.attachments = const [],
    this.requesterName,
    this.requesterDepartment,
    this.requesterInitials,
    this.requesterAvatarUrl,
  });

  HrRequest copyWith({
    String? title,
    String? description,
    RequestStatus? status,
    LeaveCategory? leaveCategory,
    List<MedicalAttachment>? attachments,
    String? requesterName,
    String? requesterDepartment,
    String? requesterInitials,
    String? requesterAvatarUrl,
  }) {
    return HrRequest(
      id: id,
      employeeId: employeeId,
      type: type,
      leaveCategory: leaveCategory ?? this.leaveCategory,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt,
      status: status ?? this.status,
      attachments: attachments ?? this.attachments,
      requesterName: requesterName ?? this.requesterName,
      requesterDepartment: requesterDepartment ?? this.requesterDepartment,
      requesterInitials: requesterInitials ?? this.requesterInitials,
      requesterAvatarUrl: requesterAvatarUrl ?? this.requesterAvatarUrl,
    );
  }
}

class Profile {
  final String employeeId;
  final String personalEmail;
  final String emergencyContact;
  final String address;
  final String employmentStatus;
  final String jobTitle;
  final String department;
  final String phone;

  const Profile({
    required this.employeeId,
    required this.personalEmail,
    required this.emergencyContact,
    required this.address,
    required this.employmentStatus,
    required this.jobTitle,
    required this.department,
    required this.phone,
  });

  Profile copyWith({
    String? personalEmail,
    String? emergencyContact,
    String? address,
    String? phone,
  }) {
    return Profile(
      employeeId: employeeId,
      personalEmail: personalEmail ?? this.personalEmail,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      address: address ?? this.address,
      employmentStatus: employmentStatus,
      jobTitle: jobTitle,
      department: department,
      phone: phone ?? this.phone,
    );
  }
}

class FeedComment {
  final String id;
  final String itemId;
  final String employeeId;
  final String content;
  final DateTime createdAt;
  final String? authorName;
  final String? authorInitials;
  final String? authorAvatarUrl;

  const FeedComment({
    required this.id,
    required this.itemId,
    required this.employeeId,
    required this.content,
    required this.createdAt,
    this.authorName,
    this.authorInitials,
    this.authorAvatarUrl,
  });

  FeedComment copyWith({String? content}) {
    return FeedComment(
      id: id,
      itemId: itemId,
      employeeId: employeeId,
      content: content ?? this.content,
      createdAt: createdAt,
      authorName: authorName,
      authorInitials: authorInitials,
      authorAvatarUrl: authorAvatarUrl,
    );
  }
}

class FeedItem {
  final String id;
  final FeedType type;
  final String title;
  final String content;
  final String author;
  final String? coverImage;
  final DateTime createdAt;
  final Set<String> likedByEmployeeIds;
  final List<FeedComment> comments;
  final LifeEventCategory? lifeEventCategory;
  final String? relatedEmployeeName;
  final String? relatedEmployeeAvatarUrl;
  final String? relatedEmployeeInitials;

  const FeedItem({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    required this.author,
    required this.createdAt,
    this.coverImage,
    this.likedByEmployeeIds = const {},
    this.comments = const [],
    this.lifeEventCategory,
    this.relatedEmployeeName,
    this.relatedEmployeeAvatarUrl,
    this.relatedEmployeeInitials,
  });

  FeedItem copyWith({
    Set<String>? likedByEmployeeIds,
    List<FeedComment>? comments,
  }) {
    return FeedItem(
      id: id,
      type: type,
      title: title,
      content: content,
      author: author,
      createdAt: createdAt,
      coverImage: coverImage,
      likedByEmployeeIds: likedByEmployeeIds ?? this.likedByEmployeeIds,
      comments: comments ?? this.comments,
      lifeEventCategory: lifeEventCategory,
      relatedEmployeeName: relatedEmployeeName,
      relatedEmployeeAvatarUrl: relatedEmployeeAvatarUrl,
      relatedEmployeeInitials: relatedEmployeeInitials,
    );
  }
}

class AppNotification {
  final String id;
  final String employeeId;
  final String title;
  final String body;
  final String deepLink;
  final DateTime createdAt;
  final bool read;
  final String? avatarLabel;
  final String? detail;

  const AppNotification({
    required this.id,
    required this.employeeId,
    required this.title,
    required this.body,
    required this.deepLink,
    required this.createdAt,
    this.read = false,
    this.avatarLabel,
    this.detail,
  });

  AppNotification copyWith({bool? read, String? avatarLabel, String? detail}) {
    return AppNotification(
      id: id,
      employeeId: employeeId,
      title: title,
      body: body,
      deepLink: deepLink,
      createdAt: createdAt,
      read: read ?? this.read,
      avatarLabel: avatarLabel ?? this.avatarLabel,
      detail: detail ?? this.detail,
    );
  }
}
