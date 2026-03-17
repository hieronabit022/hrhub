import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../application/controllers/app_controller.dart';
import '../../../application/controllers/attendance_controller.dart';
import '../../../domain/models/entities.dart';
import '../../widgets/action_dialogs.dart';
import '../../widgets/swipe_attendance_action.dart';

class AttendanceScreen extends StatefulWidget {
  final int initialTab;
  const AttendanceScreen({super.key, this.initialTab = 0});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController tabController;

  @override
  void initState() {
    super.initState();
    tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab,
    )..addListener(() {
        if (!mounted) return;
        setState(() {});
      });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final employee = context.read<AppController>().employee;
      context.read<AttendanceController>().load(
            employee: employee?.id,
            branch: employee?.branchId,
          );
    });
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<AttendanceController>();
    final summaries = _buildDailySummaries(ctrl.history, ctrl.corrections);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        bottom: TabBar(
          controller: tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
          indicatorColor: Theme.of(context).colorScheme.primary,
          tabs: const [
            Tab(text: 'Summary'),
            Tab(text: 'History'),
            Tab(text: 'Correction'),
          ],
        ),
      ),
      floatingActionButton: tabController.index == 2
          ? FloatingActionButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CorrectionFormScreen(),
                ),
              ),
              child: const Icon(Icons.add),
            )
          : null,
      body: TabBarView(
        controller: tabController,
        children: [
          _AttendanceSummaryTab(ctrl: ctrl, summaries: summaries),
          _AttendanceHistoryTab(summaries: summaries),
          _AttendanceCorrectionTab(corrections: ctrl.corrections),
        ],
      ),
    );
  }
}

class _AttendanceSummaryTab extends StatelessWidget {
  final AttendanceController ctrl;
  final List<_AttendanceDailySummary> summaries;

  const _AttendanceSummaryTab({
    required this.ctrl,
    required this.summaries,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        FutureBuilder<bool>(
          future: ctrl.isWithinOfficeRadius(),
          builder: (_, snap) => Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwipeAttendanceAction(
                    checkedIn: ctrl.checkedIn,
                    onClockIn: ctrl.clockIn,
                    onClockOut: ctrl.clockOut,
                    isWithinOfficeRadius: ctrl.isWithinOfficeRadius,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (snap.data ?? false)
                              ? const Color(0xFF16A34A)
                              : const Color(0xFF9CA3AF),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        (snap.data ?? false)
                            ? 'Office area detected'
                            : 'Not in office',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: _mini(context, 'Avg Work', _avgWork(summaries))),
            const SizedBox(width: 8),
            Expanded(child: _mini(context, 'Avg In', _avgIn(summaries))),
            const SizedBox(width: 8),
            Expanded(child: _mini(context, 'Avg Out', _avgOut(summaries))),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Recent Attendance',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        if (summaries.isEmpty)
          const _EmptyAttendanceState()
        else
          ...summaries.take(3).map(
                (summary) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _AttendanceSummaryCard(summary: summary),
                ),
              ),
      ],
    );
  }

  Widget _mini(BuildContext context, String title, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceHistoryTab extends StatelessWidget {
  final List<_AttendanceDailySummary> summaries;

  const _AttendanceHistoryTab({required this.summaries});

  @override
  Widget build(BuildContext context) {
    if (summaries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(14),
        child: _EmptyAttendanceState(),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: summaries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, index) {
        final summary = summaries[index];
        return _AttendanceSummaryCard(
          summary: summary,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AttendanceDetailScreen(summary: summary),
            ),
          ),
          onCorrection: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CorrectionFormScreen(
                initialDate: summary.date,
                initialType: summary.suggestedCorrectionType,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AttendanceCorrectionTab extends StatelessWidget {
  final List<AttendanceCorrection> corrections;

  const _AttendanceCorrectionTab({required this.corrections});

  @override
  Widget build(BuildContext context) {
    if (corrections.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(14),
        child: _EmptyAttendanceState(
          title: 'No correction requests',
          message: 'Create a correction when your clock in or clock out needs adjustment.',
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: corrections.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, index) {
        final correction = corrections[index];
        final payload = _AttendanceCorrectionPayload.tryParse(correction.reason);
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        DateFormat('dd MMM yyyy').format(correction.date),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    _StatusBadge(
                      label: _correctionStatusLabel(correction.status),
                      color: _correctionStatusColor(correction.status),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Correction Type',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _attendanceCorrectionTypeLabel(correction.correctionType),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                Text(
                  payload?.reason ?? correction.reason,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (payload != null) ...[
                  const SizedBox(height: 10),
                  _CorrectionMetaWrap(payload: payload),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class AttendanceDetailScreen extends StatelessWidget {
  final _AttendanceDailySummary summary;

  const AttendanceDetailScreen({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Detail')),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          _AttendanceSummaryCard(summary: summary),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Attendance Timeline',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 10),
                  ...summary.records.map(
                    (record) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Icon(
                            record.type == AttendanceType.checkIn
                                ? Icons.login_rounded
                                : Icons.logout_rounded,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(_attendanceTypeLabel(record.type))),
                          Text(
                            DateFormat('HH:mm').format(record.timestamp),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (summary.corrections.isNotEmpty) ...[
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Correction Requests',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 10),
                    ...summary.corrections.map(
                      (correction) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Builder(
                          builder: (context) {
                            final payload =
                                _AttendanceCorrectionPayload.tryParse(correction.reason);
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _StatusDot(
                                  color: _correctionStatusColor(correction.status),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _attendanceCorrectionTypeLabel(
                                          correction.correctionType,
                                        ),
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        payload?.reason ?? correction.reason,
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                      ),
                                      if (payload != null) ...[
                                        const SizedBox(height: 8),
                                        _CorrectionMetaWrap(payload: payload),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class CorrectionFormScreen extends StatefulWidget {
  final DateTime? initialDate;
  final AttendanceCorrectionType? initialType;

  const CorrectionFormScreen({
    super.key,
    this.initialDate,
    this.initialType,
  });

  @override
  State<CorrectionFormScreen> createState() => _CorrectionFormScreenState();
}

class _CorrectionFormScreenState extends State<CorrectionFormScreen> {
  final reason = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  late DateTime selectedDate;
  late AttendanceCorrectionType selectedType;
  TimeOfDay? checkInTime;
  TimeOfDay? checkOutTime;
  bool useAutoGps = true;
  XFile? selectedAttachment;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate ?? DateTime.now();
    selectedType = widget.initialType ?? AttendanceCorrectionType.checkIn;
  }

  @override
  void dispose() {
    reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Correction')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 120),
          children: [
            Text(
              'Attendance Date',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            OutlinedButton.icon(
              onPressed: saving ? null : _pickDate,
              icon: const Icon(Icons.calendar_month_rounded),
              label: Text(DateFormat('dd MMM yyyy').format(selectedDate)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withOpacity(0.35),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.groups_rounded,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This correction request will be sent to HR Department.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Correction Type',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _CorrectionCheckTile(
                    label: 'Check In',
                    value: _usesCheckIn(),
                    onChanged: saving ? null : (_) => _toggleCheckIn(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CorrectionCheckTile(
                    label: 'Check Out',
                    value: _usesCheckOut(),
                    onChanged: saving ? null : (_) => _toggleCheckOut(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _usesCheckIn() && _usesCheckOut()
                  ? 'Both times will be corrected.'
                  : 'Choose at least one correction type.',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'New Time',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            if (_usesCheckIn())
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OutlinedButton.icon(
                  onPressed: saving ? null : () => _pickTime(isCheckIn: true),
                  icon: const Icon(Icons.login_rounded),
                  label: Text('Check In: ${_formatPickedTime(checkInTime)}'),
                ),
              ),
            if (_usesCheckOut())
              OutlinedButton.icon(
                onPressed: saving ? null : () => _pickTime(isCheckIn: false),
                icon: const Icon(Icons.logout_rounded),
                label: Text('Check Out: ${_formatPickedTime(checkOutTime)}'),
              ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: useAutoGps,
              onChanged: saving
                  ? null
                  : (value) {
                      setState(() {
                        useAutoGps = value;
                      });
                    },
              contentPadding: EdgeInsets.zero,
              title: const Text('Location (optional auto GPS)'),
              subtitle: Text(
                useAutoGps
                    ? 'Use current device location'
                    : 'Do not include location',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Reason',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: reason,
              minLines: 3,
              maxLines: 4,
              enabled: !saving,
              decoration: InputDecoration(
                hintText: 'Explain why this attendance needs correction',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Attachment (optional)',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            OutlinedButton.icon(
              onPressed: saving ? null : _pickAttachment,
              icon: const Icon(Icons.image_outlined),
              label: Text(
                selectedAttachment == null
                    ? 'Choose Image'
                    : selectedAttachment!.name,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
          child: FilledButton(
            onPressed: saving ? null : _save,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            child: Text(saving ? 'Saving...' : 'Submit Request'),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() {
      selectedDate = picked;
    });
  }

  void _setCorrectionType(AttendanceCorrectionType type) {
    setState(() {
      selectedType = type;
      if (selectedType == AttendanceCorrectionType.checkIn) {
        checkOutTime = null;
      } else if (selectedType == AttendanceCorrectionType.checkOut) {
        checkInTime = null;
      }
    });
  }

  bool _usesCheckIn() {
    return selectedType == AttendanceCorrectionType.checkIn ||
        selectedType == AttendanceCorrectionType.both;
  }

  bool _usesCheckOut() {
    return selectedType == AttendanceCorrectionType.checkOut ||
        selectedType == AttendanceCorrectionType.both;
  }

  void _toggleCheckIn() {
    final nextCheckIn = !_usesCheckIn();
    final nextCheckOut = _usesCheckOut();
    _applyCorrectionSelection(
      checkInSelected: nextCheckIn,
      checkOutSelected: nextCheckOut,
    );
  }

  void _toggleCheckOut() {
    final nextCheckIn = _usesCheckIn();
    final nextCheckOut = !_usesCheckOut();
    _applyCorrectionSelection(
      checkInSelected: nextCheckIn,
      checkOutSelected: nextCheckOut,
    );
  }

  void _applyCorrectionSelection({
    required bool checkInSelected,
    required bool checkOutSelected,
  }) {
    setState(() {
      if (checkInSelected && checkOutSelected) {
        selectedType = AttendanceCorrectionType.both;
      } else if (checkInSelected) {
        selectedType = AttendanceCorrectionType.checkIn;
        checkOutTime = null;
      } else if (checkOutSelected) {
        selectedType = AttendanceCorrectionType.checkOut;
        checkInTime = null;
      } else {
        selectedType = AttendanceCorrectionType.checkIn;
        checkOutTime = null;
      }
    });
  }

  Future<void> _pickTime({required bool isCheckIn}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isCheckIn
          ? (checkInTime ?? const TimeOfDay(hour: 8, minute: 0))
          : (checkOutTime ?? const TimeOfDay(hour: 17, minute: 0)),
    );
    if (picked == null) return;
    setState(() {
      if (isCheckIn) {
        checkInTime = picked;
      } else {
        checkOutTime = picked;
      }
    });
  }

  Future<void> _pickAttachment() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
    );
    if (picked == null) return;
    setState(() {
      selectedAttachment = picked;
    });
  }

  Future<void> _save() async {
    if (reason.text.trim().isEmpty) {
      await showErrorDialog(
        context,
        title: 'Reason Required',
        message: 'Please add a reason for this attendance correction.',
      );
      return;
    }

    if (_usesCheckIn() && checkInTime == null) {
      await showErrorDialog(
        context,
        title: 'Check In Time Required',
        message: 'Please set the new check in time for this correction.',
      );
      return;
    }

    if (_usesCheckOut() && checkOutTime == null) {
      await showErrorDialog(
        context,
        title: 'Check Out Time Required',
        message: 'Please set the new check out time for this correction.',
      );
      return;
    }

    setState(() {
      saving = true;
    });

    try {
      final ctrl = context.read<AttendanceController>();
      final payload = _AttendanceCorrectionPayload(
        reason: reason.text.trim(),
        checkInTime: checkInTime == null ? null : _serializePickedTime(checkInTime!),
        checkOutTime: checkOutTime == null ? null : _serializePickedTime(checkOutTime!),
        location: useAutoGps
            ? '${ctrl.currentLat.toStringAsFixed(6)}, ${ctrl.currentLng.toStringAsFixed(6)}'
            : null,
        attachmentName: selectedAttachment?.name,
        submittedTo: 'HR Department',
      );
      await context.read<AttendanceController>().createCorrection(
            selectedDate,
            selectedType,
            payload.encode(),
          );
      if (!mounted) return;
      await showSuccessDialog(
        context,
        title: 'Correction Submitted',
        message:
            'Your ${_attendanceCorrectionTypeLabel(selectedType)} correction was submitted to HR Department successfully.',
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      await showErrorDialog(
        context,
        title: 'Correction Failed',
        message: error.toString(),
      );
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
  }

  String _formatPickedTime(TimeOfDay? value) {
    if (value == null) return '--:--';
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _serializePickedTime(TimeOfDay value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _AttendanceSummaryCard extends StatelessWidget {
  final _AttendanceDailySummary summary;
  final VoidCallback? onTap;
  final VoidCallback? onCorrection;

  const _AttendanceSummaryCard({
    required this.summary,
    this.onTap,
    this.onCorrection,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('EEEE, dd MMM yyyy').format(summary.date),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          summary.statusText,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(
                    label: summary.completionLabel,
                    color: summary.isComplete
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFF59E0B),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _AttendanceMetricBox(
                      label: 'Clock In',
                      value: summary.clockInLabel,
                      icon: Icons.login_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _AttendanceMetricBox(
                      label: 'Clock Out',
                      value: summary.clockOutLabel,
                      icon: Icons.logout_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _AttendanceMetricBox(
                      label: 'Work Hours',
                      value: summary.workDurationLabel,
                      icon: Icons.schedule_rounded,
                    ),
                  ),
                ],
              ),
              if (summary.corrections.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: summary.corrections
                      .map(
                        (correction) => _StatusBadge(
                          label:
                              '${_attendanceCorrectionTypeLabel(correction.correctionType)} ${_correctionStatusLabel(correction.status)}',
                          color: _correctionStatusColor(correction.status),
                        ),
                      )
                      .toList(),
                ),
              ],
              if (onCorrection != null || onTap != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (onTap != null)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onTap,
                          child: const Text('View Detail'),
                        ),
                      ),
                    if (onTap != null && onCorrection != null)
                      const SizedBox(width: 8),
                    if (onCorrection != null)
                      Expanded(
                        child: FilledButton.tonal(
                          onPressed: onCorrection,
                          child: const Text('Request Correction'),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AttendanceMetricBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _AttendanceMetricBox({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withOpacity(0.45),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _CorrectionCheckTile extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool?>? onChanged;

  const _CorrectionCheckTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: value
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).dividerColor,
          ),
          color: value
              ? Theme.of(context).colorScheme.primary.withOpacity(0.06)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Checkbox(
              value: value,
              onChanged: onChanged,
              visualDensity: VisualDensity.compact,
            ),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final Color color;

  const _StatusDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      margin: const EdgeInsets.only(top: 5),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _EmptyAttendanceState extends StatelessWidget {
  final String title;
  final String message;

  const _EmptyAttendanceState({
    this.title = 'No attendance history yet',
    this.message = 'Your attendance summary will appear here once you start clocking in and out.',
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Icon(
              Icons.event_note_rounded,
              size: 28,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceDailySummary {
  final DateTime date;
  final List<AttendanceRecord> records;
  final List<AttendanceCorrection> corrections;

  const _AttendanceDailySummary({
    required this.date,
    required this.records,
    required this.corrections,
  });

  AttendanceRecord? get checkInRecord => _recordByType(AttendanceType.checkIn);
  AttendanceRecord? get checkOutRecord => _recordByType(AttendanceType.checkOut);

  bool get isComplete => checkInRecord != null && checkOutRecord != null;

  String get clockInLabel => _timeLabel(checkInRecord?.timestamp);
  String get clockOutLabel => _timeLabel(checkOutRecord?.timestamp);

  String get workDurationLabel {
    if (checkInRecord == null || checkOutRecord == null) return '--';
    final diff = checkOutRecord!.timestamp.difference(checkInRecord!.timestamp);
    final hours = diff.inHours;
    final minutes = diff.inMinutes.remainder(60);
    return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
  }

  String get completionLabel => isComplete ? 'Complete' : 'Needs Correction';

  String get statusText {
    if (checkInRecord == null && checkOutRecord == null) {
      return 'No clock in or clock out recorded';
    }
    if (checkInRecord == null) {
      return 'Clock in is missing for this attendance date';
    }
    if (checkOutRecord == null) {
      return 'Clock out is missing for this attendance date';
    }
    return 'Clock in and clock out are recorded';
  }

  AttendanceCorrectionType get suggestedCorrectionType {
    if (checkInRecord == null && checkOutRecord == null) {
      return AttendanceCorrectionType.both;
    }
    if (checkInRecord == null) return AttendanceCorrectionType.checkIn;
    if (checkOutRecord == null) return AttendanceCorrectionType.checkOut;
    return AttendanceCorrectionType.both;
  }

  AttendanceRecord? _recordByType(AttendanceType type) {
    final filtered = records.where((record) => record.type == type).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    if (type == AttendanceType.checkIn) {
      return filtered.isEmpty ? null : filtered.first;
    }
    return filtered.isEmpty ? null : filtered.last;
  }

  static String _timeLabel(DateTime? value) {
    if (value == null) return '--';
    return DateFormat('HH:mm').format(value);
  }
}

List<_AttendanceDailySummary> _buildDailySummaries(
  List<AttendanceRecord> history,
  List<AttendanceCorrection> corrections,
) {
  final groupedHistory = <String, List<AttendanceRecord>>{};
  for (final record in history) {
    final date = DateTime(
      record.timestamp.year,
      record.timestamp.month,
      record.timestamp.day,
    );
    final key = date.toIso8601String();
    groupedHistory.putIfAbsent(key, () => []).add(record);
  }

  final groupedCorrections = <String, List<AttendanceCorrection>>{};
  for (final correction in corrections) {
    final date = DateTime(
      correction.date.year,
      correction.date.month,
      correction.date.day,
    );
    final key = date.toIso8601String();
    groupedCorrections.putIfAbsent(key, () => []).add(correction);
  }

  final keys = {...groupedHistory.keys, ...groupedCorrections.keys}.toList()
    ..sort((a, b) => DateTime.parse(b).compareTo(DateTime.parse(a)));

  return keys
      .map(
        (key) => _AttendanceDailySummary(
          date: DateTime.parse(key),
          records: (groupedHistory[key] ?? [])
            ..sort((a, b) => a.timestamp.compareTo(b.timestamp)),
          corrections: (groupedCorrections[key] ?? [])
            ..sort((a, b) => b.date.compareTo(a.date)),
        ),
      )
      .toList();
}

String _attendanceTypeLabel(AttendanceType type) {
  switch (type) {
    case AttendanceType.checkIn:
      return 'Clock In';
    case AttendanceType.checkOut:
      return 'Clock Out';
  }
}

String _attendanceCorrectionTypeLabel(AttendanceCorrectionType type) {
  switch (type) {
    case AttendanceCorrectionType.checkIn:
      return 'Check In';
    case AttendanceCorrectionType.checkOut:
      return 'Check Out';
    case AttendanceCorrectionType.both:
      return 'Both';
  }
}

String _correctionStatusLabel(AttendanceCorrectionStatus status) {
  switch (status) {
    case AttendanceCorrectionStatus.pending:
      return 'Pending';
    case AttendanceCorrectionStatus.approved:
      return 'Approved';
    case AttendanceCorrectionStatus.rejected:
      return 'Rejected';
  }
}

Color _correctionStatusColor(AttendanceCorrectionStatus status) {
  switch (status) {
    case AttendanceCorrectionStatus.pending:
      return const Color(0xFFF59E0B);
    case AttendanceCorrectionStatus.approved:
      return const Color(0xFF16A34A);
    case AttendanceCorrectionStatus.rejected:
      return const Color(0xFFDC2626);
  }
}

String _avgWork(List<_AttendanceDailySummary> summaries) {
  final complete = summaries.where((summary) => summary.isComplete).toList();
  if (complete.isEmpty) return '--';
  final totalMinutes = complete.fold<int>(
    0,
    (sum, summary) => sum +
        summary.checkOutRecord!.timestamp
            .difference(summary.checkInRecord!.timestamp)
            .inMinutes,
  );
  final average = totalMinutes ~/ complete.length;
  return _minutesToHourMinute(average);
}

String _avgIn(List<_AttendanceDailySummary> summaries) {
  final withCheckIn =
      summaries.where((summary) => summary.checkInRecord != null).toList();
  if (withCheckIn.isEmpty) return '--';
  final totalMinutes = withCheckIn.fold<int>(
    0,
    (sum, summary) => sum +
        (summary.checkInRecord!.timestamp.hour * 60 +
            summary.checkInRecord!.timestamp.minute),
  );
  return _minutesToTime(totalMinutes ~/ withCheckIn.length);
}

String _avgOut(List<_AttendanceDailySummary> summaries) {
  final withCheckOut =
      summaries.where((summary) => summary.checkOutRecord != null).toList();
  if (withCheckOut.isEmpty) return '--';
  final totalMinutes = withCheckOut.fold<int>(
    0,
    (sum, summary) => sum +
        (summary.checkOutRecord!.timestamp.hour * 60 +
            summary.checkOutRecord!.timestamp.minute),
  );
  return _minutesToTime(totalMinutes ~/ withCheckOut.length);
}

String _minutesToHourMinute(int totalMinutes) {
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
}

String _minutesToTime(int totalMinutes) {
  final normalized = totalMinutes % (24 * 60);
  final hours = normalized ~/ 60;
  final minutes = normalized % 60;
  return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
}

class _CorrectionMetaWrap extends StatelessWidget {
  final _AttendanceCorrectionPayload payload;

  const _CorrectionMetaWrap({required this.payload});

  @override
  Widget build(BuildContext context) {
    final items = <String>[
      if (payload.checkInTime != null) 'Check In: ${payload.checkInTime}',
      if (payload.checkOutTime != null) 'Check Out: ${payload.checkOutTime}',
      if (payload.location != null) 'Location: ${payload.location}',
      if (payload.attachmentName != null) 'Attachment: ${payload.attachmentName}',
      if (payload.submittedTo != null) 'Sent to: ${payload.submittedTo}',
    ];
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: items
          .map(
            (item) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withOpacity(0.4),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                item,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _AttendanceCorrectionPayload {
  final String reason;
  final String? checkInTime;
  final String? checkOutTime;
  final String? location;
  final String? attachmentName;
  final String? submittedTo;

  const _AttendanceCorrectionPayload({
    required this.reason,
    this.checkInTime,
    this.checkOutTime,
    this.location,
    this.attachmentName,
    this.submittedTo,
  });

  String encode() {
    return jsonEncode({
      'reason': reason,
      'check_in_time': checkInTime,
      'check_out_time': checkOutTime,
      'location': location,
      'attachment_name': attachmentName,
      'submitted_to': submittedTo,
    });
  }

  static _AttendanceCorrectionPayload? tryParse(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return _AttendanceCorrectionPayload(
        reason: (decoded['reason'] as String?) ?? raw,
        checkInTime: decoded['check_in_time'] as String?,
        checkOutTime: decoded['check_out_time'] as String?,
        location: decoded['location'] as String?,
        attachmentName: decoded['attachment_name'] as String?,
        submittedTo: decoded['submitted_to'] as String?,
      );
    } catch (_) {
      return null;
    }
  }
}
