import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../domain/contracts/repositories.dart';
import '../../domain/models/entities.dart';

class RequestController extends ChangeNotifier {
  final RequestRepository _requestRepository;
  final NotificationRepository _notificationRepository;
  final Uuid _uuid = const Uuid();

  RequestController(this._requestRepository, this._notificationRepository);

  List<HrRequest> requests = [];
  List<HrRequest> approvals = [];
  String employeeId = 'emp-1';

  Future<void> load([String? employee]) async {
    if (employee != null) employeeId = employee;
    requests = await _requestRepository.listByEmployee(employeeId);
    notifyListeners();
  }

  Future<void> loadApprovals([String? employee]) async {
    if (employee != null) employeeId = employee;
    approvals = await _requestRepository.listApprovals(employeeId);
    notifyListeners();
  }

  Future<void> create({
    required RequestType type,
    LeaveCategory? leaveCategory,
    required String title,
    required String description,
    List<MedicalAttachment> attachments = const [],
  }) async {
    final request = HrRequest(
      id: _uuid.v4(),
      employeeId: employeeId,
      type: type,
      leaveCategory: leaveCategory,
      title: title,
      description: description,
      createdAt: DateTime.now(),
      status: RequestStatus.submitted,
      attachments: attachments,
    );
    await _requestRepository.create(request);
    await _notificationRepository.add(
      AppNotification(
        id: _uuid.v4(),
        employeeId: employeeId,
        title: type == RequestType.medicalClaim ? 'Medical Claim Submitted' : 'Request Submitted',
        body: '$title has been submitted successfully.',
        deepLink: '/requests/${request.id}',
        createdAt: DateTime.now(),
        detail: 'Status: ${request.status.name.toUpperCase()}',
      ),
    );
    await load();
    await loadApprovals();
  }

  Future<void> cancel(String id) async {
    await _requestRepository.cancel(id);
    final request = (await _requestRepository.listByEmployee(employeeId)).firstWhere((e) => e.id == id);
    await _notificationRepository.add(
      AppNotification(
        id: _uuid.v4(),
        employeeId: employeeId,
        title: 'Request Status Updated',
        body: '${request.title} has been canceled.',
        deepLink: '/requests/${request.id}',
        createdAt: DateTime.now(),
        detail: 'Status: ${request.status.name.toUpperCase()}',
      ),
    );
    await load();
    await loadApprovals();
  }

  Future<void> delete(String id) async {
    await _requestRepository.delete(id);
    await load();
    await loadApprovals();
  }

  Future<void> updateDraft(HrRequest request) async {
    await _requestRepository.update(request);
    await load();
    await loadApprovals();
  }

  Future<MedicalAttachment> uploadAttachment({
    required String requestCategory,
    required String fileName,
    required List<int> bytes,
    required String contentType,
  }) {
    return _requestRepository.uploadAttachment(
      employeeId: employeeId,
      requestCategory: requestCategory,
      fileName: fileName,
      bytes: bytes,
      contentType: contentType,
    );
  }

  Future<void> approve(String id, {String? notes}) async {
    final request = await _findRequestForAction(id);
    if (request == null) return;
    final updated = request.copyWith(status: RequestStatus.approved);
    await _requestRepository.update(updated);
    await _notificationRepository.add(
      AppNotification(
        id: _uuid.v4(),
        employeeId: updated.employeeId,
        title: updated.type == RequestType.medicalClaim ? 'Medical Claim Approved' : 'Approval Completed',
        body: '${updated.title} has been approved.',
        deepLink: '/requests/${updated.id}',
        createdAt: DateTime.now(),
        detail: 'Status: ${updated.status.name.toUpperCase()}${(notes ?? '').trim().isEmpty ? '' : ' • Notes: ${notes!.trim()}'}',
      ),
    );
    await load();
    await loadApprovals();
  }

  Future<void> reject(String id, {String? notes}) async {
    final request = await _findRequestForAction(id);
    if (request == null) return;
    final updated = request.copyWith(status: RequestStatus.rejected);
    await _requestRepository.update(updated);
    await _notificationRepository.add(
      AppNotification(
        id: _uuid.v4(),
        employeeId: updated.employeeId,
        title: updated.type == RequestType.medicalClaim ? 'Medical Claim Rejected' : 'Approval Completed',
        body: '${updated.title} has been rejected.',
        deepLink: '/requests/${updated.id}',
        createdAt: DateTime.now(),
        detail: 'Status: ${updated.status.name.toUpperCase()}${(notes ?? '').trim().isEmpty ? '' : ' • Notes: ${notes!.trim()}'}',
      ),
    );
    await load();
    await loadApprovals();
  }

  List<MedicalAttachment> removeAttachment(
    List<MedicalAttachment> items,
    String id,
  ) {
    final updated = items.where((e) => e.id != id).toList();
    notifyListeners();
    return updated;
  }

  Future<HrRequest?> _findRequestForAction(String id) async {
    for (final item in approvals) {
      if (item.id == id) return item;
    }
    for (final item in requests) {
      if (item.id == id) return item;
    }
    final remoteApprovals = await _requestRepository.listApprovals(employeeId);
    for (final item in remoteApprovals) {
      if (item.id == id) return item;
    }
    return null;
  }
}
