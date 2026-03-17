import '../../domain/models/entities.dart';

class MockSeedData {
  final Employee currentEmployee;
  final List<Branch> branches;
  final List<AttendanceRecord> attendance;
  final List<AttendanceCorrection> corrections;
  final List<HrRequest> requests;
  final Profile profile;
  final List<FeedItem> feeds;
  final List<AppNotification> notifications;

  MockSeedData({
    required this.currentEmployee,
    required this.branches,
    required this.attendance,
    required this.corrections,
    required this.requests,
    required this.profile,
    required this.feeds,
    required this.notifications,
  });
}

class MockSeed {
  static MockSeedData build() {
    const employee = Employee(
      id: 'emp-1',
      name: 'Alya Rahman',
      title: 'Senior Product Designer',
      department: 'Product Design',
      branchId: 'br-1',
      initials: 'AR',
      phone: '082113777878',
      avatarUrl: null,
    );

    final branches = [
      const Branch(
        id: 'br-1',
        name: 'Jakarta HQ',
        latitude: -6.200000,
        longitude: 106.816666,
        radiusMeters: 300,
      ),
      const Branch(
        id: 'br-2',
        name: 'Bandung Hub',
        latitude: -6.914744,
        longitude: 107.609810,
        radiusMeters: 250,
      ),
    ];

    final attendance = [
      AttendanceRecord(
        id: 'att-1',
        employeeId: employee.id,
        timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 8)),
        type: AttendanceType.checkIn,
      ),
      AttendanceRecord(
        id: 'att-2',
        employeeId: employee.id,
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        type: AttendanceType.checkOut,
      ),
    ];

    final corrections = [
      AttendanceCorrection(
        id: 'cor-1',
        employeeId: employee.id,
        date: DateTime.now().subtract(const Duration(days: 2)),
        correctionType: AttendanceCorrectionType.checkOut,
        reason: 'Forgot to check out after client call.',
        status: AttendanceCorrectionStatus.pending,
      ),
    ];

    final requests = [
      HrRequest(
        id: 'req-1',
        employeeId: employee.id,
        type: RequestType.leave,
        title: 'Annual Leave',
        description: 'Family event leave for 2 days.',
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
        status: RequestStatus.submitted,
      ),
      HrRequest(
        id: 'req-2',
        employeeId: employee.id,
        type: RequestType.medicalClaim,
        title: 'Dental Treatment Claim',
        description: 'Claim for dental treatment receipt.',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        status: RequestStatus.draft,
        attachments: const [
          MedicalAttachment(
            id: 'med-1',
            path: 'receipt_1.jpg',
            state: UploadState.uploaded,
          ),
        ],
      ),
    ];

    final profile = Profile(
      employeeId: employee.id,
      personalEmail: 'alya.rahman@mail.com',
      emergencyContact: 'Budi Rahman (Spouse)',
      address: 'Jl. Sudirman No. 88, Jakarta',
      employmentStatus: 'Permanent',
      jobTitle: 'Senior Product Designer',
      department: 'Product Design',
      phone: '081234567890',
    );

    final feeds = [
      FeedItem(
        id: 'news-1',
        type: FeedType.news,
        title: 'WorkPulse Mobile Launch',
        content: 'Today we launched the WorkPulse mobile-first app for all internal teams.',
        author: 'Corporate Communications',
        coverImage: 'launch',
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        likedByEmployeeIds: const {'emp-1'},
        comments: [
          FeedComment(
            id: 'com-1',
            itemId: 'news-1',
            employeeId: 'emp-1',
            content: 'Excited to use this daily!',
            createdAt: DateTime.now().subtract(const Duration(hours: 5)),
            authorName: 'Alya Rahman',
            authorInitials: 'AR',
          ),
        ],
      ),
      FeedItem(
        id: 'ann-1',
        type: FeedType.announcement,
        title: 'Office Maintenance Schedule',
        content: 'Jakarta HQ floor 12 maintenance this Friday at 18:00.',
        author: 'HR Operations',
        coverImage: 'maintenance',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      FeedItem(
        id: 'life-1',
        type: FeedType.lifeEvent,
        title: 'Happy Birthday, Rizky!',
        content: 'Wishing Rizky from Engineering a joyful birthday.',
        author: 'People Team',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        lifeEventCategory: LifeEventCategory.birthday,
        relatedEmployeeName: 'Rizky Pratama',
        relatedEmployeeInitials: 'R',
      ),
      FeedItem(
        id: 'life-2',
        type: FeedType.lifeEvent,
        title: 'Congratulations on Your Marriage, Nabila',
        content: 'Wishing Nabila from Finance a beautiful married life.',
        author: 'People Team',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        lifeEventCategory: LifeEventCategory.marriage,
        relatedEmployeeName: 'Nabila Putri',
        relatedEmployeeInitials: 'N',
      ),
      FeedItem(
        id: 'life-3',
        type: FeedType.lifeEvent,
        title: 'Welcome Baby Aiden',
        content: 'Congratulations to Fajar and family on the birth of baby Aiden.',
        author: 'People Team',
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
        lifeEventCategory: LifeEventCategory.birth,
        relatedEmployeeName: 'Fajar Mahendra',
        relatedEmployeeInitials: 'F',
      ),
      FeedItem(
        id: 'life-4',
        type: FeedType.lifeEvent,
        title: 'Condolences for the Family of Dimas',
        content: 'Our deepest condolences to Dimas and family. We are with you.',
        author: 'People Team',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        lifeEventCategory: LifeEventCategory.condolence,
        relatedEmployeeName: 'Dimas Saputra',
        relatedEmployeeInitials: 'DS',
      ),
    ];

    final notifications = [
      AppNotification(
        id: 'not-1',
        employeeId: employee.id,
        title: 'Request Submitted',
        body: 'Your annual leave request has been submitted.',
        deepLink: '/requests/req-1',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        avatarLabel: 'HR',
        detail: 'Category: Request • Status: Submitted • Ref: req-1',
      ),
      AppNotification(
        id: 'not-2',
        employeeId: employee.id,
        title: 'Approval Required',
        body: 'A request is waiting for your approval review.',
        deepLink: '/approvals/req-1',
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        avatarLabel: 'AP',
        detail: 'Category: Approval • Status: Pending • Ref: req-1',
      ),
      AppNotification(
        id: 'not-3',
        employeeId: employee.id,
        title: 'Medical Claim Approved',
        body: 'Your dental treatment claim has been approved.',
        deepLink: '/requests/req-2',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        avatarLabel: 'MC',
        detail: 'Category: Medical Claim • Status: Approved • Ref: req-2',
      ),
      AppNotification(
        id: 'not-4',
        employeeId: employee.id,
        title: 'News Update',
        body: 'WorkPulse Mobile Launch is now available to read.',
        deepLink: '/feed/news-1',
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        avatarLabel: 'NW',
        detail: 'Category: News • Ref: news-1',
      ),
      AppNotification(
        id: 'not-5',
        employeeId: employee.id,
        title: 'Announcement',
        body: 'Office Maintenance Schedule has been published.',
        deepLink: '/feed/ann-1',
        createdAt: DateTime.now().subtract(const Duration(hours: 7)),
        avatarLabel: 'AN',
        detail: 'Category: Announcement • Ref: ann-1',
      ),
      AppNotification(
        id: 'not-6',
        employeeId: employee.id,
        title: 'Life Event: Birthday',
        body: 'Rizky Pratama is celebrating a birthday today.',
        deepLink: '/life-events/life-1',
        createdAt: DateTime.now().subtract(const Duration(hours: 8)),
        avatarLabel: 'RP',
        detail: 'Category: Event • Related Employee: Rizky Pratama',
      ),
      AppNotification(
        id: 'not-7',
        employeeId: employee.id,
        title: 'Life Event: Marriage',
        body: 'Nabila Putri shared happy marriage news.',
        deepLink: '/life-events/life-2',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        avatarLabel: 'NP',
        detail: 'Category: Event • Related Employee: Nabila Putri',
      ),
      AppNotification(
        id: 'not-8',
        employeeId: employee.id,
        title: 'Life Event: Birth',
        body: 'Fajar Mahendra welcomed a newborn baby.',
        deepLink: '/life-events/life-3',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        avatarLabel: 'FM',
        detail: 'Category: Event • Related Employee: Fajar Mahendra',
      ),
      AppNotification(
        id: 'not-9',
        employeeId: employee.id,
        title: 'Life Event: Condolence',
        body: 'Condolence support for Dimas Saputra and family.',
        deepLink: '/life-events/life-4',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        avatarLabel: 'DS',
        detail: 'Category: Event • Related Employee: Dimas Saputra',
      ),
    ];

    return MockSeedData(
      currentEmployee: employee,
      branches: branches,
      attendance: attendance,
      corrections: corrections,
      requests: requests,
      profile: profile,
      feeds: feeds,
      notifications: notifications,
    );
  }
}
