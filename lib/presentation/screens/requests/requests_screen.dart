import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../application/controllers/app_controller.dart';
import '../../../application/controllers/notification_controller.dart';
import '../../../application/controllers/request_controller.dart';
import '../../../domain/models/entities.dart';
import '../../widgets/action_dialogs.dart';

enum RequestFlowType { annualLeave, specialLeave, wfh, permission, medicalClaim }

class RequestsScreen extends StatefulWidget {
  final RequestType? filterType;
  final String? titleOverride;

  const RequestsScreen({
    super.key,
    this.filterType,
    this.titleOverride,
  });

  const RequestsScreen.medicalClaims({super.key})
      : filterType = RequestType.medicalClaim,
        titleOverride = 'Medical Claims';

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final employee = context.read<AppController>().employee;
      context.read<RequestController>().load(employee?.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<RequestController>();
    final items = widget.filterType == null
        ? ctrl.requests
        : ctrl.requests.where((r) => r.type == widget.filterType).toList();
    final isMedicalClaimList = widget.filterType == RequestType.medicalClaim;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.titleOverride ?? 'My Requests'),
        actions: [
          if (isMedicalClaimList)
            IconButton(
              onPressed: () => _openForm(context, RequestFlowType.medicalClaim),
              icon: const Icon(Icons.add_rounded),
              tooltip: 'New Medical Claim',
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (!isMedicalClaimList)
            GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 2.2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: [
                _RequestMenuCard(
                  title: 'Annual Leave',
                  icon: Icons.beach_access_rounded,
                  onTap: () => _openForm(context, RequestFlowType.annualLeave),
                ),
                _RequestMenuCard(
                  title: 'Special Leave',
                  icon: Icons.assignment_turned_in_outlined,
                  onTap: () => _openForm(context, RequestFlowType.specialLeave),
                ),
                _RequestMenuCard(
                  title: 'WFH / WFA',
                  icon: Icons.laptop_mac_rounded,
                  onTap: () => _openForm(context, RequestFlowType.wfh),
                ),
                _RequestMenuCard(
                  title: 'Permission',
                  icon: Icons.badge_rounded,
                  onTap: () => _openForm(context, RequestFlowType.permission),
                ),
              ],
            ),
          const SizedBox(height: 12),
          Text(
            isMedicalClaimList ? 'Medical Claim History' : 'Recent Requests',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ...items.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Card(
                child: ListTile(
                leading: CircleAvatar(
                  radius: 16,
                  child: Icon(_requestIcon(r.type), size: 15),
                ),
                title: Text(
                  r.title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.2),
                ),
                subtitle: Text(
                  '${_typeLabel(r.type, leaveCategory: r.leaveCategory)} • ${r.status.name.toUpperCase()}',
                  style: const TextStyle(fontSize: 10.6),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => RequestDetailScreen(request: r)),
                  ),
                ),
              ),
            ),
          ),
          if (isMedicalClaimList)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _openForm(context, RequestFlowType.medicalClaim),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Create Medical Claim'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _openForm(BuildContext context, RequestFlowType flow) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RequestFormScreen(flow: flow),
      ),
    );
  }
}

class _RequestMenuCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  const _RequestMenuCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Row(
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RequestFormScreen extends StatefulWidget {
  final RequestFlowType flow;
  final HrRequest? initialRequest;

  const RequestFormScreen({
    super.key,
    required this.flow,
    this.initialRequest,
  });

  @override
  State<RequestFormScreen> createState() => _RequestFormScreenState();
}

class _RequestFormScreenState extends State<RequestFormScreen> {
  static const int _maxUploadBytes = 1200 * 1024;
  static const int _maxImageDimension = 1600;
  final _rupiahFormat = NumberFormat.decimalPattern('id_ID');
  final _picker = ImagePicker();
  final title = TextEditingController();
  final desc = TextEditingController();
  final locationCtrl = TextEditingController();
  final purposeCtrl = TextEditingController();
  final amountCtrl = TextEditingController();

  LeaveCategory leaveCategory = LeaveCategory.annual;
  DateTime? startDate;
  DateTime? endDate;
  TimeOfDay? startTime;
  TimeOfDay? endTime;

  List<MedicalAttachment> attachments = [];
  bool _isDragging = false;
  bool _uploadingAttachments = false;

  RequestType get _type => switch (widget.flow) {
        RequestFlowType.annualLeave => RequestType.leave,
        RequestFlowType.specialLeave => RequestType.leave,
        RequestFlowType.wfh => RequestType.wfa,
        RequestFlowType.permission => RequestType.permission,
        RequestFlowType.medicalClaim => RequestType.medicalClaim,
      };

  LeaveCategory get _defaultLeaveCategory => switch (widget.flow) {
        RequestFlowType.specialLeave => LeaveCategory.special,
        _ => LeaveCategory.annual,
      };

  @override
  void initState() {
    super.initState();
    final existing = widget.initialRequest;
    if (existing != null) {
      title.text = existing.title;
      desc.text = existing.description;
      attachments = [...existing.attachments];
      if (existing.type == RequestType.leave) {
        leaveCategory = existing.leaveCategory ?? _defaultLeaveCategory;
      }
      if (existing.type == RequestType.medicalClaim) {
        final amountMatch = RegExp(r'Amount:\s*Rp\s*([0-9\.\,]+)').firstMatch(existing.description);
        if (amountMatch != null) {
          amountCtrl.text = amountMatch.group(1) ?? '';
        }
      }
    } else {
      title.text = '${_flowTitle(widget.flow)} Request';
      if (_type == RequestType.leave) {
        leaveCategory = _defaultLeaveCategory;
      }
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      initialDate: isStart ? (startDate ?? now) : (endDate ?? startDate ?? now),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        startDate = picked;
        if (endDate != null && endDate!.isBefore(startDate!)) {
          endDate = startDate;
        }
      } else {
        endDate = picked;
      }
    });
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime:
          isStart ? (startTime ?? const TimeOfDay(hour: 8, minute: 30)) : (endTime ?? const TimeOfDay(hour: 17, minute: 30)),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        startTime = picked;
      } else {
        endTime = picked;
      }
    });
  }

  Future<void> _pickAndUploadAttachments() async {
    if (_uploadingAttachments || attachments.length >= 6) return;
    final available = 6 - attachments.length;
    final selected = await _picker.pickMultiImage(imageQuality: 85);
    if (selected.isEmpty) return;

    final picked = selected.take(available).toList();
    if (picked.isEmpty) return;

    setState(() => _uploadingAttachments = true);
    try {
      for (final file in picked) {
        final tempId = const Uuid().v4();
        final uploadingItem = MedicalAttachment(
          id: tempId,
          path: file.name,
          state: UploadState.uploading,
        );
        setState(() {
          attachments = [...attachments, uploadingItem];
        });

        try {
          final prepared = await _prepareUploadImage(file);
          final uploaded = await context.read<RequestController>().uploadAttachment(
                requestCategory: _attachmentCategory,
                fileName: prepared.fileName,
                bytes: prepared.bytes,
                contentType: prepared.contentType,
              );
          setState(() {
            attachments = attachments.map((item) {
              return item.id == tempId ? uploaded : item;
            }).toList();
          });
        } catch (_) {
          setState(() {
            attachments = attachments.map((item) {
              return item.id == tempId
                  ? item.copyWith(state: UploadState.failed)
                  : item;
            }).toList();
          });
        }
      }
    } finally {
      if (mounted) {
        setState(() => _uploadingAttachments = false);
      }
    }
  }

  Future<void> _retryAttachment(String id) async {
    final retry = await showRetryDialog(
      context,
      title: 'Upload failed',
      message: 'Please select the image again to retry upload.',
    );
    if (!retry) return;
    setState(() {
      attachments = attachments.where((e) => e.id != id).toList();
    });
    await _pickAndUploadAttachments();
  }

  Future<void> _save() async {
    if (_type == RequestType.medicalClaim && attachments.isEmpty) {
      await showErrorDialog(
        context,
        title: 'Save failed',
        message: 'Medical claim requires at least 1 image attachment.',
      );
      return;
    }

    if (_type == RequestType.leave && leaveCategory == LeaveCategory.special && attachments.isEmpty) {
      await showErrorDialog(
        context,
        title: 'Save failed',
        message: 'Special leave requires at least 1 supporting document.',
      );
      return;
    }

    final controller = context.read<RequestController>();
    final requestTitle = title.text.trim().isEmpty
        ? '${_flowTitle(widget.flow)} Request'
        : title.text.trim();
    final existing = widget.initialRequest;
    final requestDescription = existing == null
        ? _buildDescription(DateFormat('dd MMM yyyy'))
        : (desc.text.trim().isEmpty ? existing.description : desc.text.trim());

    if (existing == null) {
      await controller.create(
        type: _type,
        leaveCategory: _type == RequestType.leave ? leaveCategory : null,
        title: requestTitle,
        description: requestDescription,
        attachments: attachments,
      );
    } else {
      final updated = existing.copyWith(
        title: requestTitle,
        description: requestDescription,
        leaveCategory: _type == RequestType.leave ? leaveCategory : existing.leaveCategory,
        attachments: attachments,
        status: existing.status,
      );
      await controller.updateDraft(updated);
    }
    if (!mounted) return;
    await context.read<NotificationController>().load();

    if (!mounted) return;
    await showSuccessDialog(
      context,
      title: 'Success',
      message: existing == null
          ? 'Request saved successfully.'
          : 'Request updated successfully.',
    );
    if (!mounted) return;
    Navigator.pop(context, existing == null ? null : existing.copyWith(
      title: requestTitle,
      description: requestDescription,
      leaveCategory: _type == RequestType.leave ? leaveCategory : existing.leaveCategory,
      attachments: attachments,
      status: existing.status,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initialRequest == null
              ? 'Create ${_flowTitle(widget.flow)}'
              : 'Edit ${_flowTitle(widget.flow)}',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          _sectionLabel('Title'),
          const SizedBox(height: 6),
          TextField(controller: title),
          const SizedBox(height: 10),
          _sectionLabel('Reason / Description'),
          const SizedBox(height: 6),
          TextField(controller: desc, minLines: 3, maxLines: 5),
          const SizedBox(height: 10),
          if (_type == RequestType.leave && (widget.flow != RequestFlowType.annualLeave && widget.flow != RequestFlowType.specialLeave)) ...[
            _sectionLabel('Leave Type'),
            const SizedBox(height: 6),
            DropdownButtonFormField<LeaveCategory>(
              value: leaveCategory,
              items: const [
                DropdownMenuItem(value: LeaveCategory.annual, child: Text('Annual Leave')),
                DropdownMenuItem(value: LeaveCategory.special, child: Text('Special Leave')),
              ],
              onChanged: (v) => setState(() => leaveCategory = v ?? LeaveCategory.annual),
            ),
            const SizedBox(height: 10),
          ],
          if (_type == RequestType.leave || _type == RequestType.wfa) ...[
            _sectionLabel(_type == RequestType.leave ? 'Leave Period' : 'WFH/WFA Date'),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(isStart: true),
                    icon: const Icon(Icons.date_range_rounded, size: 18),
                    label: Text(startDate == null ? 'Start Date' : dateFmt.format(startDate!)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(isStart: false),
                    icon: const Icon(Icons.event_available_rounded, size: 18),
                    label: Text(endDate == null ? 'End Date' : dateFmt.format(endDate!)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          if (_type == RequestType.permission) ...[
            _sectionLabel('Permission Time'),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickTime(isStart: true),
                    icon: const Icon(Icons.schedule_rounded, size: 18),
                    label: Text(startTime == null ? 'Start Time' : startTime!.format(context)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickTime(isStart: false),
                    icon: const Icon(Icons.timelapse_rounded, size: 18),
                    label: Text(endTime == null ? 'End Time' : endTime!.format(context)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          if (_type == RequestType.wfa) ...[
            _sectionLabel('WFH/WFA Location'),
            const SizedBox(height: 6),
            TextField(controller: locationCtrl),
            const SizedBox(height: 10),
          ],
          if (_type == RequestType.permission) ...[
            _sectionLabel('Permission Purpose'),
            const SizedBox(height: 6),
            TextField(controller: purposeCtrl),
            const SizedBox(height: 10),
          ],
          if (_type == RequestType.medicalClaim) ...[
            _sectionLabel('Claim Amount'),
            const SizedBox(height: 6),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [_RupiahInputFormatter()],
              decoration: const InputDecoration(prefixText: 'Rp '),
            ),
            const SizedBox(height: 10),
          ],
          if (_type == RequestType.medicalClaim || (_type == RequestType.leave && leaveCategory == LeaveCategory.special)) ...[
            _sectionLabel(_type == RequestType.medicalClaim
                ? 'Claim Attachments (min 1, max 6)'
                : 'Special Leave Documents (required, min 1, max 6)'),
            const SizedBox(height: 8),
            _buildDropZone(context),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('${attachments.length}/6 files', style: const TextStyle(fontSize: 12)),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: attachments.map((a) {
                final color = switch (a.state) {
                  UploadState.uploading => Colors.orange,
                  UploadState.uploaded => Colors.green,
                  UploadState.failed => Colors.red,
                };
                return Container(
                  width: 156,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _AttachmentThumbnail(
                        attachment: a,
                        height: 64,
                        onTap: () => _openAttachmentViewer(context, a),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        a.path.split('/').last,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.circle, size: 8, color: color),
                          const SizedBox(width: 4),
                          Text(a.state.name, style: const TextStyle(fontSize: 10)),
                          const Spacer(),
                          if (a.state == UploadState.failed)
                            GestureDetector(
                              onTap: () => _retryAttachment(a.id),
                              child: const Icon(Icons.refresh_rounded, size: 16),
                            ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () async {
                              final retry = await showRetryDialog(
                                context,
                                title: 'Remove document?',
                                message: 'Are you sure you want to remove this document?',
                                retryText: 'Remove',
                                cancelText: 'Cancel',
                              );
                              if (!retry) return;
                              setState(() {
                                attachments = context.read<RequestController>().removeAttachment(attachments, a.id);
                              });
                              if (!mounted) return;
                              await showSuccessDialog(
                                context,
                                title: 'Success',
                                message: 'Document removed successfully.',
                              );
                            },
                            child: const Icon(Icons.delete_outline_rounded, size: 16),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _uploadingAttachments ? null : _save,
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: Text(widget.initialRequest == null ? 'Save Request' : 'Update Request'),
            ),
          ),
        ],
      ),
    );
  }

  String _buildDescription(DateFormat dateFmt) {
    final raw = desc.text.trim();
    if (_type == RequestType.leave) {
      final d1 = startDate == null ? '-' : dateFmt.format(startDate!);
      final d2 = endDate == null ? '-' : dateFmt.format(endDate!);
      final leaveLabel = leaveCategory == LeaveCategory.special ? 'Special Leave' : 'Annual Leave';
      return '$raw\nJenis: $leaveLabel\nPeriode: $d1 - $d2';
    }
    if (_type == RequestType.wfa) {
      final d1 = startDate == null ? '-' : dateFmt.format(startDate!);
      final d2 = endDate == null ? '-' : dateFmt.format(endDate!);
      return '$raw\nLokasi: ${locationCtrl.text.trim()}\nTanggal: $d1 - $d2';
    }
    if (_type == RequestType.permission) {
      final t1 = startTime?.format(context) ?? '-';
      final t2 = endTime?.format(context) ?? '-';
      return '$raw\nTujuan: ${purposeCtrl.text.trim()}\nWaktu: $t1 - $t2';
    }
    if (_type == RequestType.medicalClaim) {
      final normalizedAmount = amountCtrl.text.trim().isEmpty
          ? '0'
          : amountCtrl.text.trim();
      return '$raw\nAmount: Rp $normalizedAmount\nAttachments: ${attachments.length} file';
    }
    return raw;
  }

  Widget _buildDropZone(BuildContext context) {
    final borderColor = _isDragging
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).dividerColor;

    final zone = GestureDetector(
      onTap: attachments.length >= 6 || _uploadingAttachments
          ? null
          : _pickAndUploadAttachments,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
          color: _isDragging
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)
              : Theme.of(context).colorScheme.surfaceContainerLowest,
        ),
        child: Column(
          children: [
            const Icon(Icons.cloud_upload_outlined, size: 24),
            const SizedBox(height: 8),
            Text(
              attachments.length >= 6
                  ? 'Maximum 6 files reached'
                  : (_uploadingAttachments
                      ? 'Uploading attachments...'
                      : 'Tap to upload images'),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            const Text(
              'Images only • Preview available after drop',
              style: TextStyle(fontSize: 10.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

    return zone;
  }

  String get _attachmentCategory {
    if (_type == RequestType.medicalClaim) return 'medical-claim';
    if (_type == RequestType.leave && leaveCategory == LeaveCategory.special) {
      return 'special-leave';
    }
    return 'request';
  }

  String _contentTypeForFile(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }

  Future<_PreparedUploadImage> _prepareUploadImage(XFile file) async {
    final originalBytes = await file.readAsBytes();
    final decoded = img.decodeImage(originalBytes);
    if (decoded == null) {
      return _PreparedUploadImage(
        bytes: originalBytes,
        fileName: file.name,
        contentType: _contentTypeForFile(file.name),
      );
    }

    img.Image working = decoded;
    if (working.width > _maxImageDimension || working.height > _maxImageDimension) {
      working = img.copyResize(
        working,
        width: working.width >= working.height ? _maxImageDimension : null,
        height: working.height > working.width ? _maxImageDimension : null,
        interpolation: img.Interpolation.average,
      );
    }

    Uint8List outputBytes = Uint8List.fromList(img.encodeJpg(working, quality: 90));
    if (originalBytes.length > _maxUploadBytes || outputBytes.length > _maxUploadBytes) {
      for (var quality = 82; quality >= 35; quality -= 7) {
        outputBytes = Uint8List.fromList(img.encodeJpg(working, quality: quality));
        if (outputBytes.length <= _maxUploadBytes) {
          break;
        }
      }
    }

    if (outputBytes.length > _maxUploadBytes) {
      var resized = working;
      while (outputBytes.length > _maxUploadBytes &&
          resized.width > 640 &&
          resized.height > 640) {
        resized = img.copyResize(
          resized,
          width: (resized.width * 0.85).round(),
          height: (resized.height * 0.85).round(),
          interpolation: img.Interpolation.average,
        );
        outputBytes = Uint8List.fromList(img.encodeJpg(resized, quality: 70));
      }
    }

    final baseName = file.name.contains('.')
        ? file.name.substring(0, file.name.lastIndexOf('.'))
        : file.name;

    return _PreparedUploadImage(
      bytes: outputBytes,
      fileName: '$baseName.jpg',
      contentType: 'image/jpeg',
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      );
}

class RequestDetailScreen extends StatelessWidget {
  final HrRequest request;
  const RequestDetailScreen({super.key, required this.request});

  bool get _canEdit =>
      request.status == RequestStatus.draft || request.status == RequestStatus.submitted;

  bool get _supportsAttachments =>
      request.type == RequestType.medicalClaim ||
      (request.type == RequestType.leave && request.leaveCategory == LeaveCategory.special);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request Detail')),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(radius: 16, child: Icon(_requestIcon(request.type), size: 16)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          request.title,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    request.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.94),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Status: ${request.status.name.toUpperCase()}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  if (request.type == RequestType.leave && request.leaveCategory != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Category: ${request.leaveCategory == LeaveCategory.special ? 'Special Leave' : 'Annual Leave'}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                  const SizedBox(height: 8),
                  if (request.attachments.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: request.attachments
                          .map(
                            (e) => _RequestAttachmentCard(
                              attachment: e,
                              onTap: () => _openAttachmentViewer(context, e),
                            ),
                          )
                          .toList(),
                    ),
                ],
              ),
            ),
          ),
          if (_canEdit && _supportsAttachments) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  final updated = await Navigator.push<HrRequest>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RequestFormScreen(
                        flow: _flowFromRequest(request),
                        initialRequest: request,
                      ),
                    ),
                  );
                  if (!context.mounted || updated == null) return;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RequestDetailScreen(request: updated),
                    ),
                  );
                },
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit Request'),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await context.read<RequestController>().cancel(request.id);
                    if (!context.mounted) return;
                    await context.read<NotificationController>().load();
                    if (!context.mounted) return;
                    await showSuccessDialog(
                      context,
                      title: 'Success',
                      message: 'Request cancelled successfully.',
                    );
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final ok = await showRetryDialog(
                      context,
                      title: 'Delete request?',
                      message: 'This request will be permanently deleted.',
                      retryText: 'Delete',
                      cancelText: 'Cancel',
                    );
                    if (!ok) return;
                    await context.read<RequestController>().delete(request.id);
                    if (!context.mounted) return;
                    await showSuccessDialog(
                      context,
                      title: 'Success',
                      message: 'Request deleted successfully.',
                    );
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Delete'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AttachmentThumbnail extends StatelessWidget {
  final MedicalAttachment attachment;
  final double height;
  final VoidCallback onTap;

  const _AttachmentThumbnail({
    required this.attachment,
    required this.height,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isNetwork = attachment.path.startsWith('http');
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: isNetwork ? onTap : null,
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: isNetwork
                ? Image.network(
                    attachment.path,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.broken_image_outlined, size: 22),
                    ),
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return const Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                  )
                : const Center(child: Icon(Icons.image_rounded, size: 22)),
          ),
        ),
      ),
    );
  }
}

class _RequestAttachmentCard extends StatelessWidget {
  final MedicalAttachment attachment;
  final VoidCallback onTap;

  const _RequestAttachmentCard({
    required this.attachment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AttachmentThumbnail(
            attachment: attachment,
            height: 88,
            onTap: onTap,
          ),
          const SizedBox(height: 6),
          Text(
            attachment.path.split('/').last,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10.8, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

void _openAttachmentViewer(BuildContext context, MedicalAttachment attachment) {
  if (!attachment.path.startsWith('http')) return;
  showDialog<void>(
    context: context,
    builder: (_) => Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          InteractiveViewer(
            minScale: 0.8,
            maxScale: 4,
            child: AspectRatio(
              aspectRatio: 1,
              child: Image.network(
                attachment.path,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image_outlined, size: 36),
                ),
              ),
            ),
          ),
          Positioned(
            right: 8,
            top: 8,
            child: IconButton.filledTonal(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded),
            ),
          ),
        ],
      ),
    ),
  );
}

RequestFlowType _flowFromRequest(HrRequest request) {
  switch (request.type) {
    case RequestType.leave:
      return request.leaveCategory == LeaveCategory.special
          ? RequestFlowType.specialLeave
          : RequestFlowType.annualLeave;
    case RequestType.permission:
      return RequestFlowType.permission;
    case RequestType.wfa:
      return RequestFlowType.wfh;
    case RequestType.medicalClaim:
      return RequestFlowType.medicalClaim;
  }
}

class _PreparedUploadImage {
  final Uint8List bytes;
  final String fileName;
  final String contentType;

  const _PreparedUploadImage({
    required this.bytes,
    required this.fileName,
    required this.contentType,
  });
}

class _RupiahInputFormatter extends TextInputFormatter {
  final NumberFormat _format = NumberFormat.decimalPattern('id_ID');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final formatted = _format.format(int.parse(digits));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

String _flowTitle(RequestFlowType type) {
  switch (type) {
    case RequestFlowType.annualLeave:
      return 'Annual Leave';
    case RequestFlowType.specialLeave:
      return 'Special Leave';
    case RequestFlowType.wfh:
      return 'WFH / WFA';
    case RequestFlowType.permission:
      return 'Permission';
    case RequestFlowType.medicalClaim:
      return 'Medical Claim';
  }
}

String _typeLabel(RequestType type, {LeaveCategory? leaveCategory}) {
  switch (type) {
    case RequestType.leave:
      if (leaveCategory == LeaveCategory.special) return 'Special Leave';
      return 'Annual Leave';
    case RequestType.permission:
      return 'Permission';
    case RequestType.wfa:
      return 'WFH/WFA';
    case RequestType.medicalClaim:
      return 'Medical Claim';
  }
}

IconData _requestIcon(RequestType type) {
  switch (type) {
    case RequestType.leave:
      return Icons.beach_access_rounded;
    case RequestType.permission:
      return Icons.badge_rounded;
    case RequestType.wfa:
      return Icons.laptop_mac_rounded;
    case RequestType.medicalClaim:
      return Icons.health_and_safety_rounded;
  }
}
