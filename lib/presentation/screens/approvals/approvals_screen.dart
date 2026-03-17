import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../application/controllers/app_controller.dart';
import '../../../application/controllers/notification_controller.dart';
import '../../../application/controllers/request_controller.dart';
import '../../../domain/models/entities.dart';

bool _isMobileApprovalType(RequestType type) {
  return type == RequestType.leave ||
      type == RequestType.permission ||
      type == RequestType.wfa;
}

class ApprovalsScreen extends StatefulWidget {
  const ApprovalsScreen({super.key});

  @override
  State<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends State<ApprovalsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final employee = context.read<AppController>().employee;
      context.read<RequestController>().loadApprovals(employee?.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final requests = context.watch<RequestController>().approvals.where((item) => _isMobileApprovalType(item.type)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Approvals')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: const Text('Mobile approval scope'),
              subtitle: const Text(
                'Only Leave, Permission, and WFH are approved in mobile. Medical claims are handled by HR in CMS.',
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (requests.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 32),
              child: Center(child: Text('No approvals')),
            )
          else
            ...List.generate(requests.length, (i) {
              final item = requests[i];
              return Padding(
                padding: EdgeInsets.only(bottom: i == requests.length - 1 ? 0 : 6),
                child: Card(
                  child: ListTile(
                    title: Text(item.title),
                    subtitle: Text('${item.type.name} • ${item.status.name}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ApprovalDetailScreen(request: item),
                      ),
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class ApprovalDetailScreen extends StatefulWidget {
  final HrRequest request;
  const ApprovalDetailScreen({super.key, required this.request});

  @override
  State<ApprovalDetailScreen> createState() => _ApprovalDetailScreenState();
}

class _ApprovalDetailScreenState extends State<ApprovalDetailScreen> {
  final notes = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Approval Detail')),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.request.title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(widget.request.description),
                  const SizedBox(height: 8),
                  Text('Type: ${widget.request.type.name}'),
                  Text('Status: ${widget.request.status.name}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Notes', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 6),
          TextField(controller: notes, minLines: 3, maxLines: 4),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    await context.read<RequestController>().reject(
                          widget.request.id,
                          notes: notes.text,
                        );
                    if (!context.mounted) return;
                    await context.read<NotificationController>().load();
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  },
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () async {
                    await context.read<RequestController>().approve(
                          widget.request.id,
                          notes: notes.text,
                        );
                    if (!context.mounted) return;
                    await context.read<NotificationController>().load();
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  },
                  child: const Text('Accept'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
