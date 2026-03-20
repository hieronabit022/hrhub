# WorkPulse Mobile API Specification

This document defines the backend API and database structure required by the current WorkPulse mobile application.

The scope follows the implemented mobile features:
- OTP login
- employee profile
- attendance and attendance correction
- HR requests and approvals
- medical claim / special leave image attachments
- news, announcements, and life events
- comments, likes, and notifications
- team members and department calendar context

## 1. Architecture Scope

Recommended backend style:
- REST API with JSON
- token-based auth
- PostgreSQL or MySQL for core data
- object storage for request attachments and employee avatars

Recommended base URL:
- `https://api.your-domain.com/api/v1`

Recommended auth flow:
- request OTP
- verify OTP
- return access token + current employee profile

Current app is using Supabase-style REST, but the production API should expose stable business endpoints rather than direct table access.

## 2. Core Modules

Modules required by the mobile app:
- Authentication
- Employee / Profile
- Branch / Office Radius
- Attendance
- Attendance Correction
- Requests
- Approvals
- Team Members
- Feed
- Feed Comments
- Feed Likes
- Notifications
- File Upload

## 3. Enums

### Request Type
- `leave`
- `permission`
- `wfa`
- `medicalClaim`

### Leave Category
- `annual`
- `special`

### Request Status
- `draft`
- `submitted`
- `approved`
- `rejected`
- `canceled`

### Attendance Type
- `checkIn`
- `checkOut`

### Attendance Work Mode
- `office`
- `wfa`
- `businessTrip`

### Attendance Correction Status
- `pending`
- `approved`
- `rejected`

### Attendance Correction Type
- `checkIn`
- `checkOut`
- `both`

### Feed Type
- `news`
- `announcement`
- `lifeEvent`

### Life Event Category
- `birthday`
- `marriage`
- `birth`
- `condolence`

### Notification Category
- `request`
- `approval`
- `attendance`
- `feed`
- `lifeEvent`
- `system`

## 4. Required Tables

### 4.1 `branches`

Stores office location and radius for attendance validation.

| Column | Type | Required | Notes |
|---|---|---:|---|
| id | uuid / text | yes | primary key |
| code | varchar(50) | yes | optional business code |
| name | varchar(150) | yes | branch name |
| latitude | decimal(10,7) | yes | office latitude |
| longitude | decimal(10,7) | yes | office longitude |
| radius_meters | integer | yes | attendance radius |
| address | text | no | office address |
| is_active | boolean | yes | default true |
| created_at | timestamptz | yes | |
| updated_at | timestamptz | yes | |

### 4.2 `employees`

Stores employee identity used across attendance, requests, approvals, comments, and life events.

| Column | Type | Required | Notes |
|---|---|---:|---|
| id | uuid / text | yes | primary key |
| employee_no | varchar(50) | no | employee number |
| name | varchar(150) | yes | |
| title | varchar(150) | yes | current title |
| department | varchar(150) | yes | department name |
| branch_id | fk -> branches.id | yes | current branch |
| manager_id | fk -> employees.id | no | direct manager |
| initials | varchar(10) | yes | used for avatar fallback |
| phone | varchar(30) | yes | unique login identifier |
| personal_email | varchar(150) | no | can duplicate profile if desired |
| avatar_url | text | no | public image URL |
| employment_status | varchar(50) | no | permanent / contract / etc |
| is_active | boolean | yes | default true |
| created_at | timestamptz | yes | |
| updated_at | timestamptz | yes | |

### 4.3 `profiles`

Stores editable employee profile data exposed in mobile.

| Column | Type | Required | Notes |
|---|---|---:|---|
| employee_id | fk -> employees.id | yes | primary key |
| personal_email | varchar(150) | yes | read-only in app |
| emergency_contact | varchar(150) | yes | editable |
| address | text | yes | editable |
| employment_status | varchar(50) | yes | display |
| job_title | varchar(150) | yes | display |
| department | varchar(150) | yes | display |
| phone | varchar(30) | yes | display / optional editable by business policy |
| updated_at | timestamptz | yes | |

### 4.4 `attendance_records`

Stores check in / check out events.

| Column | Type | Required | Notes |
|---|---|---:|---|
| id | uuid / text | yes | primary key |
| employee_id | fk -> employees.id | yes | |
| timestamp | timestamptz | yes | actual record time |
| type | enum AttendanceType | yes | checkIn / checkOut |
| work_mode | enum AttendanceWorkMode | no | office / wfa / businessTrip |
| branch_id | fk -> branches.id | no | office context |
| latitude | decimal(10,7) | no | captured GPS |
| longitude | decimal(10,7) | no | captured GPS |
| note | text | no | optional |
| created_at | timestamptz | yes | |

### 4.5 `attendance_daily_summaries`

Recommended summary table or materialized view for fast history rendering.

| Column | Type | Required | Notes |
|---|---|---:|---|
| id | uuid | yes | primary key |
| employee_id | fk -> employees.id | yes | |
| attendance_date | date | yes | unique with employee_id |
| check_in_at | timestamptz | no | |
| check_out_at | timestamptz | no | |
| work_minutes | integer | no | |
| status | varchar(30) | yes | complete / missingCheckIn / missingCheckOut |
| work_mode | enum AttendanceWorkMode | no | |
| created_at | timestamptz | yes | |
| updated_at | timestamptz | yes | |

### 4.6 `attendance_corrections`

Stores correction requests sent to HR Department.

| Column | Type | Required | Notes |
|---|---|---:|---|
| id | uuid / text | yes | primary key |
| employee_id | fk -> employees.id | yes | requester |
| date | date | yes | attendance date being corrected |
| correction_type | enum AttendanceCorrectionType | yes | checkIn / checkOut / both |
| new_check_in_time | time | no | required when type includes checkIn |
| new_check_out_time | time | no | required when type includes checkOut |
| use_device_location | boolean | yes | default false |
| latitude | decimal(10,7) | no | optional GPS |
| longitude | decimal(10,7) | no | optional GPS |
| reason | text | yes | |
| attachment_url | text | no | optional image |
| submitted_to_role | varchar(50) | yes | default `HR Department` |
| status | enum AttendanceCorrectionStatus | yes | pending / approved / rejected |
| reviewed_by | fk -> employees.id | no | HR reviewer |
| reviewed_at | timestamptz | no | |
| review_note | text | no | |
| created_at | timestamptz | yes | |
| updated_at | timestamptz | yes | |

### 4.7 `requests`

Stores employee leave / permission / WFA / medical claim requests.

| Column | Type | Required | Notes |
|---|---|---:|---|
| id | uuid / text | yes | primary key |
| employee_id | fk -> employees.id | yes | requester |
| approver_employee_id | fk -> employees.id | no | manager/leader approver |
| type | enum RequestType | yes | |
| leave_category | enum LeaveCategory | no | only for leave |
| title | varchar(200) | yes | |
| description | text | yes | |
| amount | decimal(14,2) | no | medical claim amount |
| start_date | date | no | leave / permission / WFA start |
| end_date | date | no | leave / permission / WFA end |
| status | enum RequestStatus | yes | |
| attachments_json | jsonb | yes | list of uploaded images |
| created_at | timestamptz | yes | |
| updated_at | timestamptz | yes | |
| submitted_at | timestamptz | no | |
| decided_at | timestamptz | no | |
| decision_note | text | no | |

`attachments_json` shape:

```json
[
  {
    "id": "uuid",
    "path": "https://.../attachment.jpg",
    "state": "uploaded"
  }
]
```

### 4.8 `request_status_logs`

Recommended for audit trail.

| Column | Type | Required | Notes |
|---|---|---:|---|
| id | uuid | yes | primary key |
| request_id | fk -> requests.id | yes | |
| from_status | varchar(30) | no | |
| to_status | varchar(30) | yes | |
| acted_by | fk -> employees.id | yes | requester / approver / HR |
| note | text | no | |
| created_at | timestamptz | yes | |

### 4.9 `feed_items`

Stores news, announcements, and life events.

| Column | Type | Required | Notes |
|---|---|---:|---|
| id | uuid / text | yes | primary key |
| type | enum FeedType | yes | news / announcement / lifeEvent |
| title | varchar(200) | yes | |
| content | text | yes | body content |
| author | varchar(150) | yes | display publisher |
| cover_image | text | no | label or media URL |
| image_url | text | no | recommended actual hero image |
| created_at | timestamptz | yes | publish date |
| published_at | timestamptz | no | optional |
| is_published | boolean | yes | default true |
| life_event_category | enum LifeEventCategory | no | only when type = lifeEvent |
| related_employee_id | fk -> employees.id | no | recommended replacement for name-only relation |
| related_employee_name | varchar(150) | no | legacy / convenience |
| created_by_employee_id | fk -> employees.id | no | HR or comms publisher |
| created_at_audit | timestamptz | yes | audit |
| updated_at | timestamptz | yes | |

### 4.10 `feed_comments`

Stores one comment per employee per post in the current app behavior.

| Column | Type | Required | Notes |
|---|---|---:|---|
| id | uuid / text | yes | primary key |
| item_id | fk -> feed_items.id | yes | |
| employee_id | fk -> employees.id | yes | |
| content | varchar(280) | yes | current app limit |
| created_at | timestamptz | yes | |
| updated_at | timestamptz | no | |

Recommended unique constraint:
- `(item_id, employee_id)`

### 4.11 `feed_likes`

Stores likes / condolences reaction count.

| Column | Type | Required | Notes |
|---|---|---:|---|
| item_id | fk -> feed_items.id | yes | |
| employee_id | fk -> employees.id | yes | |
| created_at | timestamptz | yes | |

Primary key:
- `(item_id, employee_id)`

### 4.12 `notifications`

Stores all user-facing notifications.

| Column | Type | Required | Notes |
|---|---|---:|---|
| id | uuid / text | yes | primary key |
| employee_id | fk -> employees.id | yes | receiver |
| category | enum NotificationCategory | yes | recommended |
| title | varchar(200) | yes | |
| body | text | yes | |
| detail | text | no | extra summary |
| deep_link | varchar(255) | yes | app navigation target |
| avatar_label | varchar(10) | no | fallback visual |
| image_url | text | no | optional |
| is_read | boolean | yes | default false |
| created_at | timestamptz | yes | |
| read_at | timestamptz | no | |

### 4.13 `notification_dispatch_logs`

Recommended to avoid duplicate notification creation.

| Column | Type | Required | Notes |
|---|---|---:|---|
| id | uuid | yes | primary key |
| source_type | varchar(50) | yes | request / feed / lifeEvent / approval |
| source_id | varchar(100) | yes | source record id |
| employee_id | fk -> employees.id | yes | receiver |
| notification_id | fk -> notifications.id | yes | |
| created_at | timestamptz | yes | |

Unique constraint:
- `(source_type, source_id, employee_id)`

## 5. Storage Buckets

### 5.1 `request-attachments`
- used by special leave and medical claim
- image only for current mobile scope

Recommended path:
- `employees/{employeeId}/{requestType}/{uuid}.jpg`

### 5.2 `avatars`
- optional if avatars are managed by storage

Recommended path:
- `employees/{employeeId}.jpg`

## 6. API Specification

## 6.1 Authentication

### POST `/auth/request-otp`

Request:

```json
{
  "phone": "081234567890"
}
```

Response:

```json
{
  "success": true,
  "message": "OTP sent",
  "otp_expires_in_seconds": 300
}
```

### POST `/auth/verify-otp`

Request:

```json
{
  "phone": "081234567890",
  "otp": "1234"
}
```

Response:

```json
{
  "success": true,
  "access_token": "jwt-or-session-token",
  "token_type": "Bearer",
  "employee": {
    "id": "emp-1",
    "name": "Alya Rahman",
    "title": "Senior Product Designer",
    "department": "Product Design",
    "branch_id": "br-jkt",
    "manager_id": "emp-2",
    "initials": "AR",
    "phone": "081234567890",
    "avatar_url": "https://..."
  }
}
```

### POST `/auth/logout`

Request:

```json
{}
```

Response:

```json
{
  "success": true
}
```

## 6.2 Employee / Profile

### GET `/me`

Returns current authenticated employee summary.

### GET `/me/profile`

Response:

```json
{
  "employee_id": "emp-1",
  "personal_email": "alya.rahman@mail.com",
  "emergency_contact": "Bima Prakoso",
  "address": "Jl. Sudirman No. 88, Jakarta",
  "employment_status": "Permanent",
  "job_title": "Senior Product Designer",
  "department": "Product Design",
  "phone": "081234567890"
}
```

### PATCH `/me/profile`

Request:

```json
{
  "address": "Jl. Baru No. 10, Jakarta",
  "emergency_contact": "Nadia Putri"
}
```

Response:

```json
{
  "success": true,
  "data": {
    "employee_id": "emp-1",
    "personal_email": "alya.rahman@mail.com",
    "emergency_contact": "Nadia Putri",
    "address": "Jl. Baru No. 10, Jakarta",
    "employment_status": "Permanent",
    "job_title": "Senior Product Designer",
    "department": "Product Design",
    "phone": "081234567890"
  }
}
```

## 6.3 Branches

### GET `/branches`

Returns office branches with coordinates and radius.

## 6.4 Attendance

### GET `/attendance/history`

Query:
- `from`
- `to`

Response:

```json
{
  "records": [
    {
      "id": "att-1",
      "timestamp": "2026-03-20T01:05:00Z",
      "type": "checkIn",
      "work_mode": "office"
    }
  ],
  "daily_summaries": [
    {
      "attendance_date": "2026-03-20",
      "check_in_at": "2026-03-20T01:05:00Z",
      "check_out_at": "2026-03-20T10:05:00Z",
      "work_minutes": 540,
      "status": "complete",
      "work_mode": "office"
    }
  ]
}
```

### POST `/attendance/check-in`

Request:

```json
{
  "timestamp": "2026-03-20T01:05:00Z",
  "latitude": -6.2,
  "longitude": 106.8,
  "work_mode": "office"
}
```

### POST `/attendance/check-out`

Request:

```json
{
  "timestamp": "2026-03-20T10:05:00Z",
  "latitude": -6.2,
  "longitude": 106.8,
  "work_mode": "office"
}
```

### POST `/attendance/corrections`

Request:

```json
{
  "date": "2026-03-20",
  "correction_type": "both",
  "new_check_in_time": "08:00",
  "new_check_out_time": "17:00",
  "use_device_location": true,
  "latitude": -6.2,
  "longitude": 106.8,
  "reason": "Forgot to clock in and clock out during client visit.",
  "attachment_url": "https://..."
}
```

Response:

```json
{
  "success": true,
  "data": {
    "id": "cor-1",
    "status": "pending",
    "submitted_to_role": "HR Department"
  }
}
```

### GET `/attendance/corrections`

Returns current employee correction requests.

## 6.5 Requests

### GET `/requests`

Query:
- `status`
- `type`
- `page`
- `limit`

### POST `/requests`

Request example: annual leave

```json
{
  "type": "leave",
  "leave_category": "annual",
  "title": "Annual Leave",
  "description": "Family event",
  "start_date": "2026-03-25",
  "end_date": "2026-03-27",
  "attachments": []
}
```

Request example: special leave

```json
{
  "type": "leave",
  "leave_category": "special",
  "title": "Marriage Leave",
  "description": "Marriage ceremony",
  "start_date": "2026-04-01",
  "end_date": "2026-04-03",
  "attachments": [
    {
      "id": "file-1",
      "path": "https://..."
    }
  ]
}
```

Request example: medical claim

```json
{
  "type": "medicalClaim",
  "title": "Medical Claim Request",
  "description": "Medicine and consultation",
  "amount": 500000,
  "attachments": [
    {
      "id": "file-1",
      "path": "https://..."
    }
  ]
}
```

### GET `/requests/{requestId}`

### PATCH `/requests/{requestId}`

Editable only when status is `draft` or `submitted`.

### POST `/requests/{requestId}/submit`

Changes status from `draft` to `submitted`.

### POST `/requests/{requestId}/cancel`

Changes status to `canceled`.

### DELETE `/requests/{requestId}`

Allowed when still draft or by business rule.

## 6.6 Approvals

Scope in mobile:
- only `leave`
- `permission`
- `wfa`

Medical claim approval is by HR in CMS, not in mobile approvals.

### GET `/approvals`

Returns approvals for current leader / manager.

Response should enrich requester information:

```json
[
  {
    "id": "req-1",
    "employee_id": "emp-3",
    "requester_name": "Citra Lestari",
    "requester_department": "Product Design",
    "requester_initials": "CL",
    "requester_avatar_url": "https://...",
    "type": "leave",
    "status": "submitted",
    "title": "Annual Leave",
    "description": "Family trip",
    "created_at": "2026-03-20T03:00:00Z"
  }
]
```

### GET `/approvals/team-context`

Used so approver can see other team members in same scope who already have leave / WFA / permission.

Query:
- `scope=manager|department`

### POST `/approvals/{requestId}/approve`

Request:

```json
{
  "note": "Approved"
}
```

### POST `/approvals/{requestId}/reject`

Request:

```json
{
  "note": "Team capacity is not enough for this date."
}
```

## 6.7 Team Members

### GET `/team/members`

Recommended logic:
- same manager group first
- if current employee is a manager: direct reports
- fallback same department

Response:

```json
[
  {
    "id": "emp-2",
    "name": "Bima Prakoso",
    "title": "Engineering Manager",
    "department": "Engineering",
    "avatar_url": "https://..."
  }
]
```

### GET `/team/calendar`

Department scope calendar.

Query:
- `department`
- `date`

Response:

```json
{
  "date": "2026-03-20",
  "department": "Product Design",
  "items": [
    {
      "employee_id": "emp-4",
      "employee_name": "Nadia Putri",
      "employee_avatar_url": "https://...",
      "request_type": "wfa",
      "status": "approved",
      "start_date": "2026-03-20",
      "end_date": "2026-03-20"
    }
  ]
}
```

## 6.8 File Upload

### POST `/uploads/request-image`

Multipart or binary upload.

Request:
- image file only
- server should compress/normalize optionally if needed

Response:

```json
{
  "id": "file-1",
  "url": "https://cdn.../employees/emp-1/medicalClaim/file-1.jpg",
  "mime_type": "image/jpeg",
  "size": 842312
}
```

## 6.9 Feed

### GET `/feeds`

Query:
- `type=news|announcement|lifeEvent`
- `page`
- `limit`

### GET `/feeds/{feedId}`

Returns one feed item with:
- comments
- like count
- commenter basic employee info
- related employee info for life events

### POST `/feeds/{feedId}/comments`

Request:

```json
{
  "content": "Congratulations!"
}
```

Business rule:
- current app allows only one comment per employee per post
- max length `280`

### PATCH `/feeds/{feedId}/comments/{commentId}`

### DELETE `/feeds/{feedId}/comments/{commentId}`

### POST `/feeds/{feedId}/like`

Toggle like or support explicit actions:
- `POST /like`
- `DELETE /like`

## 6.10 Notifications

### GET `/notifications`

Query:
- `unread_only=true|false`
- `page`
- `limit`

Current mobile behavior:
- bell page shows unread only
- all notifications page shows unread first, then newest

### POST `/notifications/{notificationId}/read`

Marks a notification as read.

### Notification deep links required

Supported deep links:
- `/feed/{feedId}`
- `/life-events/{feedId}`
- `/requests/{requestId}`
- `/approvals/{requestId}`
- `/profile`

## 7. Notification Rules

The backend should create notifications for:
- request submitted
- request approved
- request rejected
- request canceled where relevant
- news published
- announcement published
- birthday published
- birth published
- wedding published
- condolence published

The backend should not create notifications for:
- feed comments

## 8. Recommended Indexes

### `employees`
- index on `manager_id`
- index on `department`
- unique on `phone`

### `attendance_records`
- index on `(employee_id, timestamp desc)`

### `attendance_corrections`
- index on `(employee_id, date desc)`
- index on `status`

### `requests`
- index on `(employee_id, created_at desc)`
- index on `(approver_employee_id, status, created_at desc)`
- index on `(type, status)`
- index on `(department if denormalized, start_date, end_date)` if calendar is heavy

### `feed_items`
- index on `(type, created_at desc)`
- index on `(life_event_category, created_at desc)`

### `feed_comments`
- index on `(item_id, created_at asc)`
- unique on `(item_id, employee_id)` if one comment per employee is enforced

### `notifications`
- index on `(employee_id, is_read, created_at desc)`

## 9. Recommended Improvements Over Current Supabase Prototype

Current prototype works, but production API should improve these parts:

1. Use `related_employee_id` in `feed_items`
- current prototype often resolves related employee by name
- production should use foreign key

2. Add explicit request dates and amount
- current prototype relies heavily on `description`
- production should store `start_date`, `end_date`, and `amount`

3. Add attendance daily summary
- mobile correction/history is easier and faster with daily summaries

4. Add correction structured columns
- current prototype packs extra info into reason in some flows
- production should store new times, GPS flag, and attachment separately

5. Add notification dispatch log
- prevents duplicate notifications

6. Separate employee master and editable profile
- keep master data stable from HRIS/CMS
- profile handles mobile-editable fields

7. Add auth/session proper token handling
- current fake OTP is acceptable only for testing

## 10. Minimal MVP Table Set

If backend wants the smallest production-capable set first, minimum tables are:
- `branches`
- `employees`
- `profiles`
- `attendance_records`
- `attendance_corrections`
- `requests`
- `feed_items`
- `feed_comments`
- `feed_likes`
- `notifications`

Recommended but optional in phase 1:
- `attendance_daily_summaries`
- `request_status_logs`
- `notification_dispatch_logs`

## 11. Recommended Delivery Order

Suggested backend delivery order:

1. Auth + employees + profiles
2. Branches + attendance
3. Requests + upload
4. Approvals + team context
5. Feed + comments + likes
6. Notifications
7. Calendar + summary optimization

## 12. Open Business Decisions

These should be confirmed before final backend implementation:

1. Is `phone` editable in mobile or read-only?
2. Is comment rule exactly one comment per employee per post?
3. Should medical claim amount always be numeric and stored separately?
4. Should life events be visible company-wide or filtered by department/branch?
5. Should WFA and Business Trip both be stored in attendance records?
6. Who approves attendance correction in CMS: HR only or also branch admin?
7. Should request date ranges be mandatory for leave / permission / WFA?

## 13. Suggested API Response Envelope

Recommended standard response:

```json
{
  "success": true,
  "message": "OK",
  "data": {}
}
```

Recommended error response:

```json
{
  "success": false,
  "message": "Validation failed",
  "errors": {
    "phone": ["Phone number is required"]
  }
}
```

## 14. File References

This spec is based on the current mobile implementation and prototype schema in:
- [schema.sql](C:/Users/hieronimus.nabit/Data/my-project/Ai-flutter/workpulse-api/supabase/schema.sql)
- [repositories.dart](C:/Users/hieronimus.nabit/Data/my-project/Ai-flutter/hrhub/lib/domain/contracts/repositories.dart)
- [supabase_repositories.dart](C:/Users/hieronimus.nabit/Data/my-project/Ai-flutter/hrhub/lib/data/repositories/supabase_repositories.dart)
