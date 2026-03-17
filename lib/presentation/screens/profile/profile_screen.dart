import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../application/controllers/app_controller.dart';
import '../../../application/controllers/profile_controller.dart';
import '../../../application/controllers/request_controller.dart';
import '../../../domain/models/entities.dart';
import '../../widgets/employee_avatar.dart';
import '../../widgets/action_dialogs.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  static const int _medicalClaimAllowance = 12000000;
  late TabController tabController;
  final email = TextEditingController();
  final address = TextEditingController();
  final phone = TextEditingController();
  final emergency = TextEditingController();

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final employee = context.read<AppController>().employee;
      await context.read<ProfileController>().load(employee?.id);
      await context.read<RequestController>().load(employee?.id);
      final p = context.read<ProfileController>().profile;
      if (p != null) {
        email.text = p.personalEmail;
        address.text = p.address;
        phone.text = p.phone;
        emergency.text = p.emergencyContact;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final employee = context.watch<AppController>().employee;
    final p = context.watch<ProfileController>().profile;
    final requests = context.watch<RequestController>().requests;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: EmployeeAvatar(
                initials: employee?.initials ?? 'HR',
                avatarUrl: employee?.avatarUrl,
                radius: 16,
              ),
            ),
          ),
        ],
      ),
      body: p == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 6, 14, 4),
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 2.15,
                    children: [
                      _ProfileMetricCard(
                        label: 'Annual Leave Left',
                        value: '${_annualLeaveLeft(requests)} Days',
                        icon: Icons.beach_access_rounded,
                        accent: const Color(0xFF2563EB),
                      ),
                      _ProfileMetricCard(
                        label: 'Medical Claims Left',
                        value: _formatRupiah(_medicalClaimsLeft(requests)),
                        icon: Icons.health_and_safety_rounded,
                        accent: const Color(0xFF0F766E),
                      ),
                    ],
                  ),
                ),
                TabBar(
                  controller: tabController,
                  labelColor: Theme.of(context).colorScheme.primary,
                  unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
                  indicatorColor: Theme.of(context).colorScheme.primary,
                  tabs: const [
                    Tab(text: 'Personal'),
                    Tab(text: 'Employment'),
                    Tab(text: 'Contact'),
                  ],
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.45),
                ),
                Expanded(
                  child: TabBarView(
                    controller: tabController,
                    children: [
                      ListView(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                        children: [
                          Text(
                            'Personal Email',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: email,
                            readOnly: true,
                            decoration: const InputDecoration(
                              suffixIcon: Icon(Icons.lock_outline_rounded, size: 18),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Address',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(controller: address, minLines: 2, maxLines: 3),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: () async {
                                try {
                                  await context.read<ProfileController>().updatePersonal(
                                        email: p.personalEmail,
                                        address: address.text,
                                      );
                                  if (!context.mounted) return;
                                  await showSuccessDialog(
                                    context,
                                    title: 'Profile Updated',
                                    message: 'Your personal information was updated successfully.',
                                  );
                                } catch (error) {
                                  if (!context.mounted) return;
                                  await showErrorDialog(
                                    context,
                                    title: 'Update Failed',
                                    message: 'Failed to update personal information. Please try again.',
                                  );
                                }
                              },
                              child: const Text('Save Personal'),
                            ),
                          ),
                        ],
                      ),
                      ListView(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                        children: [
                          Card(
                            child: ListTile(
                              title: Text(p.jobTitle),
                              subtitle: Text('${p.department} • ${p.employmentStatus}'),
                            ),
                          ),
                        ],
                      ),
                      ListView(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                        children: [
                          Text(
                            'Phone',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: phone,
                            readOnly: true,
                            decoration: const InputDecoration(
                              suffixIcon: Icon(Icons.lock_outline_rounded, size: 18),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Emergency Contact',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(controller: emergency),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: () async {
                                try {
                                  await context.read<ProfileController>().updateContact(
                                        phone: p.phone,
                                        emergencyContact: emergency.text,
                                      );
                                  if (!context.mounted) return;
                                  await showSuccessDialog(
                                    context,
                                    title: 'Profile Updated',
                                    message: 'Your contact information was updated successfully.',
                                  );
                                } catch (error) {
                                  if (!context.mounted) return;
                                  await showErrorDialog(
                                    context,
                                    title: 'Update Failed',
                                    message: 'Failed to update contact information. Please try again.',
                                  );
                                }
                              },
                              child: const Text('Save Contact'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  int _annualLeaveLeft(List<HrRequest> requests) {
    const annualAllowance = 12;
    final used = requests
        .where(
          (item) =>
              item.type == RequestType.leave &&
              item.leaveCategory != LeaveCategory.special &&
              item.status != RequestStatus.rejected &&
              item.status != RequestStatus.canceled,
        )
        .length;
    return annualAllowance - used;
  }

  int _medicalClaimsLeft(List<HrRequest> requests) {
    final used = requests
        .where(
          (item) =>
              item.type == RequestType.medicalClaim &&
              item.status != RequestStatus.rejected &&
              item.status != RequestStatus.canceled,
        )
        .fold<int>(0, (total, item) => total + _extractMedicalClaimAmount(item.description));
    return _medicalClaimAllowance - used;
  }

  int _extractMedicalClaimAmount(String description) {
    final match = RegExp(r'Amount:\s*Rp\s*([0-9\.\,]+)', caseSensitive: false).firstMatch(description);
    if (match == null) return 0;
    final raw = (match.group(1) ?? '').replaceAll('.', '').replaceAll(',', '');
    return int.tryParse(raw) ?? 0;
  }

  String _formatRupiah(int amount) {
    final formatter = NumberFormat.decimalPattern('id_ID');
    return 'Rp ${formatter.format(amount)}';
  }
}

class _ProfileMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  const _ProfileMetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final isNegative = value.trim().startsWith('-');
    final valueColor = isNegative ? Colors.redAccent : Theme.of(context).colorScheme.onSurface;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: accent),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: valueColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
