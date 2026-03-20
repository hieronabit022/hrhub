import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../application/controllers/app_controller.dart';
import '../../../application/controllers/request_controller.dart';
import '../../../application/controllers/team_controller.dart';
import '../../../domain/models/entities.dart';
import '../../widgets/employee_avatar.dart';

class TeamMembersScreen extends StatefulWidget {
  const TeamMembersScreen({super.key});

  @override
  State<TeamMembersScreen> createState() => _TeamMembersScreenState();
}

class _TeamMembersScreenState extends State<TeamMembersScreen> {
  int _filter = 0;
  int _view = 0;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final employee = context.read<AppController>().employee;
      context.read<TeamController>().load(employee);
      context.read<RequestController>().loadTeamApprovalContext(employee?.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentEmployee = context.watch<AppController>().employee;
    final team = context.watch<TeamController>();
    final requestCtrl = context.watch<RequestController>();
    final availabilityMap = _buildAvailabilityMap(requestCtrl.teamApprovalContext);
    final departmentRequests = requestCtrl.teamApprovalContext
        .where(
          (item) =>
              item.requesterDepartment == currentEmployee?.department &&
              _isCalendarRequestType(item.type),
        )
        .toList();
    final calendarItems = departmentRequests.where((item) {
      final date = DateTime(
        item.createdAt.year,
        item.createdAt.month,
        item.createdAt.day,
      );
      final selected = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );
      return date == selected;
    }).toList();

    final filteredMembers = team.members.where((member) {
      final status = availabilityMap[member.id];
      switch (_filter) {
        case 1:
          return status?.type == RequestType.leave;
        case 2:
          return status?.type == RequestType.wfa;
        case 3:
          return status?.type == RequestType.permission;
        default:
          return true;
      }
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Team Members')),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.groups_rounded),
              title: const Text('Team Scope'),
              subtitle: Text(
                'Team members use your existing team scope. Team calendar uses department scope: ${currentEmployee?.department ?? '-'}',
              ),
            ),
          ),
          const SizedBox(height: 10),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Members')),
              ButtonSegment(value: 1, label: Text('Calendar')),
            ],
            selected: {_view},
            onSelectionChanged: (selection) {
              setState(() {
                _view = selection.first;
              });
            },
          ),
          const SizedBox(height: 10),
          if (_view == 1)
            _DepartmentCalendarCard(
              selectedDate: _selectedDate,
              onDateChanged: (date) {
                setState(() {
                  _selectedDate = date;
                });
              },
              items: calendarItems,
              departmentLabel: currentEmployee?.department ?? 'Department',
            )
          else ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('All')),
                ButtonSegment(value: 1, label: Text('On Leave')),
                ButtonSegment(value: 2, label: Text('WFH')),
                ButtonSegment(value: 3, label: Text('Permission')),
              ],
              selected: {_filter},
              onSelectionChanged: (selection) {
                setState(() {
                  _filter = selection.first;
                });
              },
            ),
          ),
          const SizedBox(height: 10),
          if (team.loading)
            const Padding(
              padding: EdgeInsets.only(top: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (filteredMembers.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 32),
              child: Center(child: Text('No team members found')),
            )
          else
            ...filteredMembers.map(
              (member) {
                final status = availabilityMap[member.id];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    child: ListTile(
                      leading: EmployeeAvatar(
                        initials: member.initials,
                        avatarUrl: member.avatarUrl,
                        radius: 22,
                      ),
                      title: Row(
                        children: [
                          Expanded(child: Text(member.name)),
                          if (status != null)
                            _AvailabilityBadge(
                              label: status.label,
                              color: status.color,
                            ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(member.title),
                            const SizedBox(height: 2),
                            Text(
                              member.department,
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (status != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                '${status.request.title} • ${status.request.status.name}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      trailing: Text(
                        member.phone,
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

Map<String, _TeamAvailabilityStatus> _buildAvailabilityMap(List<HrRequest> requests) {
  final sorted = [...requests]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  final map = <String, _TeamAvailabilityStatus>{};
  for (final request in sorted) {
    if (map.containsKey(request.employeeId)) continue;
    final status = _statusFromRequest(request);
    if (status == null) continue;
    map[request.employeeId] = status;
  }
  return map;
}

_TeamAvailabilityStatus? _statusFromRequest(HrRequest request) {
  switch (request.type) {
    case RequestType.leave:
      return _TeamAvailabilityStatus(
        type: request.type,
        label: 'On Leave',
        color: const Color(0xFFDC2626),
        request: request,
      );
    case RequestType.wfa:
      return _TeamAvailabilityStatus(
        type: request.type,
        label: 'WFH',
        color: const Color(0xFF2563EB),
        request: request,
      );
    case RequestType.permission:
      return _TeamAvailabilityStatus(
        type: request.type,
        label: 'Permission',
        color: const Color(0xFFF59E0B),
        request: request,
      );
    case RequestType.medicalClaim:
      return null;
  }
}

class _TeamAvailabilityStatus {
  final RequestType type;
  final String label;
  final Color color;
  final HrRequest request;

  const _TeamAvailabilityStatus({
    required this.type,
    required this.label,
    required this.color,
    required this.request,
  });
}

class _AvailabilityBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _AvailabilityBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _DepartmentCalendarCard extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  final List<HrRequest> items;
  final String departmentLabel;

  const _DepartmentCalendarCard({
    required this.selectedDate,
    required this.onDateChanged,
    required this.items,
    required this.departmentLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$departmentLabel Calendar',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Shows leave, permission, and WFH requests within the same department.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                CalendarDatePicker(
                  initialDate: selectedDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 180)),
                  lastDate: DateTime.now().add(const Duration(days: 180)),
                  onDateChanged: onDateChanged,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (items.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Center(
                child: Text('No department requests on the selected date.'),
              ),
            ),
          )
        else
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: ListTile(
                  leading: EmployeeAvatar(
                    initials: item.requesterInitials ?? 'TM',
                    avatarUrl: item.requesterAvatarUrl,
                    radius: 20,
                  ),
                  title: Text(item.requesterName ?? 'Team Member'),
                  subtitle: Text('${item.title} • ${item.type.name} • ${item.status.name}'),
                  trailing: _AvailabilityBadge(
                    label: _calendarStatusLabel(item.type),
                    color: _calendarStatusColor(item.type),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

bool _isCalendarRequestType(RequestType type) {
  return type == RequestType.leave ||
      type == RequestType.permission ||
      type == RequestType.wfa;
}

String _calendarStatusLabel(RequestType type) {
  switch (type) {
    case RequestType.leave:
      return 'On Leave';
    case RequestType.permission:
      return 'Permission';
    case RequestType.wfa:
      return 'WFH';
    case RequestType.medicalClaim:
      return 'Other';
  }
}

Color _calendarStatusColor(RequestType type) {
  switch (type) {
    case RequestType.leave:
      return const Color(0xFFDC2626);
    case RequestType.permission:
      return const Color(0xFFF59E0B);
    case RequestType.wfa:
      return const Color(0xFF2563EB);
    case RequestType.medicalClaim:
      return const Color(0xFF6B7280);
  }
}
