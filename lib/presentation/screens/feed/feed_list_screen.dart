import 'package:characters/characters.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../application/controllers/app_controller.dart';
import '../../../application/controllers/feed_controller.dart';
import '../../../domain/models/entities.dart';
import '../../widgets/action_dialogs.dart';
import '../../widgets/employee_avatar.dart';
import '../../widgets/feed_fake_image.dart';

class FeedListScreen extends StatefulWidget {
  final FeedType type;
  const FeedListScreen.news({super.key}) : type = FeedType.news;
  const FeedListScreen.announcements({super.key}) : type = FeedType.announcement;
  const FeedListScreen.lifeEvents({super.key}) : type = FeedType.lifeEvent;

  @override
  State<FeedListScreen> createState() => _FeedListScreenState();
}

class _FeedListScreenState extends State<FeedListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final employee = context.read<AppController>().employee;
      context.read<FeedController>().loadAll(employee?.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<FeedController>();
    final list = switch (widget.type) {
      FeedType.news => ctrl.news.take(10).toList(),
      FeedType.announcement => ctrl.announcements.take(5).toList(),
      FeedType.lifeEvent => ctrl.lifeEvents,
    };

    return Scaffold(
      appBar: AppBar(title: Text(_titleByType(widget.type))),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: list.length,
        separatorBuilder: (_, _) => const SizedBox(height: 6),
        itemBuilder: (_, i) {
          final item = list[i];
          if (item.type != FeedType.lifeEvent) {
            return _FeedEditorialCard(item: item);
          }
          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => FeedDetailScreen(itemId: item.id)),
            ),
            child: Card(
              color: _isCondolence(item)
                  ? Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.22)
                  : Theme.of(context).colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CoverThumb(item: item),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_isCondolence(item)) ...[
                            _FeedTypeChip(
                              label: 'Condolence',
                              color: const Color(0xFFDC2626),
                            ),
                            const SizedBox(height: 6),
                            _BereavedSummary(item: item),
                            const SizedBox(height: 8),
                          ],
                          Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.content,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.82),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.person_rounded, size: 14),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  item.author,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 10.8),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.favorite_rounded, size: 14),
                              const SizedBox(width: 3),
                              Text('${item.likedByEmployeeIds.length}', style: const TextStyle(fontSize: 10.8)),
                              const SizedBox(width: 8),
                              const Icon(Icons.mode_comment_outlined, size: 14),
                              const SizedBox(width: 3),
                              Text('${item.comments.length}', style: const TextStyle(fontSize: 10.8)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class FeedDetailScreen extends StatefulWidget {
  final String itemId;
  const FeedDetailScreen({super.key, required this.itemId});

  @override
  State<FeedDetailScreen> createState() => _FeedDetailScreenState();
}

class _FeedDetailScreenState extends State<FeedDetailScreen> {
  static const int _commentLimit = 280;
  final commentCtrl = TextEditingController();
  String? editingId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final employee = context.read<AppController>().employee;
      context.read<FeedController>().setEmployee(employee?.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final feed = context.watch<FeedController>();
    final currentEmployee = context.watch<AppController>().employee;

    return FutureBuilder<FeedItem>(
      future: feed.getById(widget.itemId),
      builder: (_, snap) {
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final item = snap.data!;
        final own = item.comments.where((e) => e.employeeId == feed.employeeId).toList();
        final isCondolence = _isCondolence(item);

        return Scaffold(
          appBar: AppBar(title: Text(item.title)),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 14),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item.type == FeedType.lifeEvent)
                          _DetailBanner(item: item, embedded: true)
                        else
                          FeedFakeImage(
                            item: item,
                            height: 230,
                            borderRadius: 18,
                          ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                        if (_isCondolence(item)) ...[
                          _FeedTypeChip(
                            label: 'Condolence',
                            color: const Color(0xFFDC2626),
                          ),
                          const SizedBox(height: 10),
                          _BereavedSummary(
                            item: item,
                            detailed: true,
                          ),
                          const SizedBox(height: 12),
                        ],
                              Text(
                                item.title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 6),
                              if (item.type == FeedType.lifeEvent)
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.relatedEmployeeName ?? 'Employee',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      DateFormat('dd MMM yyyy, HH:mm').format(item.createdAt),
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 12,
                                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                      child: Icon(
                                        item.type == FeedType.news
                                            ? Icons.newspaper_rounded
                                            : item.type == FeedType.announcement
                                                ? Icons.campaign_rounded
                                                : Icons.person,
                                        size: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        item.author,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      DateFormat('dd MMM yyyy, HH:mm').format(item.createdAt),
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 10),
                              Text(
                                item.content,
                                style: TextStyle(
                                  fontSize: 12.2,
                                  height: 1.5,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  TextButton.icon(
                                    onPressed: () => feed.toggleLike(item.id),
                                    icon: Icon(
                                      isCondolence
                                          ? (item.likedByEmployeeIds.contains(feed.employeeId)
                                              ? Icons.favorite_rounded
                                              : Icons.favorite_border_rounded)
                                          : (item.likedByEmployeeIds.contains(feed.employeeId)
                                              ? Icons.favorite_rounded
                                              : Icons.favorite_outline_rounded),
                                      size: 18,
                                    ),
                                    label: Text(
                                      isCondolence
                                          ? 'Condolences (${item.likedByEmployeeIds.length})'
                                          : '${item.likedByEmployeeIds.length}',
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Row(
                                    children: [
                                      Icon(
                                        isCondolence ? Icons.forum_outlined : Icons.mode_comment_outlined,
                                        size: 17,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${item.comments.length}',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  isCondolence ? 'Messages of Condolence' : 'Comments',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              if (isCondolence) ...[
                const SizedBox(height: 6),
                const SizedBox.shrink(),
              ],
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: commentCtrl,
                            onChanged: (_) => setState(() {}),
                            maxLength: _commentLimit,
                            maxLines: 3,
                            minLines: 1,
                            decoration: InputDecoration(
                              counterText: '',
                              hintText: editingId == null
                                  ? (isCondolence
                                      ? 'Write your condolences...'
                                      : 'Write a comment...')
                                  : (isCondolence
                                      ? 'Edit your message of condolence...'
                                      : 'Edit your comment...'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton.filledTonal(
                          onPressed: () async {
                            final text = commentCtrl.text.trim();
                            if (text.isEmpty || text.length > _commentLimit) return;
                            try {
                              if (editingId == null) {
                                await feed.addComment(item.id, text);
                              } else {
                                await feed.editComment(item.id, editingId!, text);
                                editingId = null;
                              }
                              commentCtrl.clear();
                              setState(() {});
                            } catch (error) {
                              if (!context.mounted) return;
                              await showErrorDialog(
                                context,
                                title: 'Comment Failed',
                                message: error is StateError
                                    ? error.message?.toString() ?? 'Unable to send your comment right now.'
                                    : 'Unable to send your comment right now.',
                              );
                            }
                          },
                          icon: const Icon(Icons.send_rounded, size: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${commentCtrl.text.characters.length}/$_commentLimit',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: commentCtrl.text.characters.length > _commentLimit
                              ? Theme.of(context).colorScheme.error
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  children: item.comments.map((c) {
                    final isMine = c.employeeId == feed.employeeId;
                    final commentAvatarUrl = isMine
                        ? currentEmployee?.avatarUrl
                        : c.authorAvatarUrl;
                    final commentInitials = isMine
                        ? (currentEmployee?.initials ?? c.authorInitials ?? 'Y')
                        : (c.authorInitials ?? c.employeeId.substring(0, 1).toUpperCase());
                    final commentAuthorName = isMine
                        ? (currentEmployee?.name ?? 'You')
                        : (c.authorName ?? c.employeeId);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 6),
                      color: isCondolence
                          ? Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.28)
                          : null,
                      child: ListTile(
                        leading: EmployeeAvatar(
                          initials: commentInitials,
                          avatarUrl: commentAvatarUrl,
                          radius: 14,
                        ),
                        title: Text(
                          c.content,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          isMine ? 'You' : commentAuthorName,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        trailing: isMine
                            ? Wrap(
                                spacing: 2,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_rounded, size: 18),
                                    onPressed: () {
                                      editingId = c.id;
                                      commentCtrl.text = c.content;
                                      setState(() {});
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                                    onPressed: () => feed.deleteComment(item.id, c.id),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ),
              if (own.isNotEmpty && editingId == null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    isCondolence
                        ? 'You can send one message of condolence for this post.'
                        : 'You can only have one comment per post.',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CoverThumb extends StatelessWidget {
  final FeedItem item;
  const _CoverThumb({required this.item});

  @override
  Widget build(BuildContext context) {
    final icon = switch (item.type) {
      FeedType.news => Icons.newspaper_rounded,
      FeedType.announcement => Icons.campaign_rounded,
      FeedType.lifeEvent => _isCondolence(item) ? Icons.favorite_outline_rounded : Icons.celebration_rounded,
    };
    final thumbColors = _isCondolence(item)
        ? const [Color(0xFF475569), Color(0xFF94A3B8)]
        : item.type == FeedType.news
            ? const [Color(0xFF2563EB), Color(0xFF60A5FA)]
            : item.type == FeedType.announcement
                ? const [Color(0xFF0F766E), Color(0xFF2DD4BF)]
                : const [Color(0xFF7C3AED), Color(0xFFC084FC)];

    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: thumbColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -8,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.16),
              ),
            ),
          ),
          Positioned(
            left: 10,
            bottom: 10,
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          Positioned(
            left: 10,
            right: 10,
            bottom: 10,
            child: Align(
              alignment: Alignment.bottomRight,
              child: Text(
                (item.coverImage ?? item.type.name).toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 8.6),
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedEditorialCard extends StatelessWidget {
  final FeedItem item;

  const _FeedEditorialCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => FeedDetailScreen(itemId: item.id)),
      ),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.content,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _ListMeta(
                          icon: Icons.schedule_rounded,
                          label: DateFormat('dd MMM yyyy').format(item.createdAt),
                        ),
                        _ListMeta(
                          icon: Icons.favorite_outline_rounded,
                          label: '${item.likedByEmployeeIds.length}',
                        ),
                        _ListMeta(
                          icon: Icons.mode_comment_outlined,
                          label: '${item.comments.length}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FeedFakeImage(
                item: item,
                compact: true,
                width: 116,
                height: 116,
                borderRadius: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailBanner extends StatelessWidget {
  final FeedItem item;
  final bool embedded;

  const _DetailBanner({
    required this.item,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context) {
    final icon = switch (item.type) {
      FeedType.news => Icons.newspaper_rounded,
      FeedType.announcement => Icons.campaign_rounded,
      FeedType.lifeEvent => _isCondolence(item) ? Icons.favorite_outline_rounded : Icons.celebration_rounded,
    };
    final bannerColors = _isCondolence(item)
        ? const [Color(0xFF334155), Color(0xFF64748B)]
        : item.type == FeedType.news
            ? const [Color(0xFF0C7CFF), Color(0xFF8D47FF)]
            : item.type == FeedType.announcement
                ? const [Color(0xFF0F766E), Color(0xFF14B8A6)]
                : const [Color(0xFF7C3AED), Color(0xFFEC4899)];
    return Container(
      key: const Key('news_detail_banner'),
      margin: embedded ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      height: 170,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(embedded ? 0 : 16),
        gradient: LinearGradient(
          colors: bannerColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -16,
            top: -18,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            left: -20,
            bottom: -28,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon, color: Colors.white, size: 28),
                      const Spacer(),
                      Text(
                        _isCondolence(item)
                            ? 'IN MEMORY'
                            : (item.coverImage ?? item.type.name).toUpperCase(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontWeight: FontWeight.w700,
                          fontSize: 10.6,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 88,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: Colors.white.withValues(alpha: _isCondolence(item) ? 0.1 : 0.14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -12,
                        top: -8,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.14),
                          ),
                        ),
                      ),
                      Center(
                        child: _isCondolence(item)
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  EmployeeAvatar(
                                    initials: item.relatedEmployeeInitials ??
                                        ((item.relatedEmployeeName?.isNotEmpty ?? false)
                                            ? item.relatedEmployeeName!.substring(0, 1).toUpperCase()
                                            : 'E'),
                                    avatarUrl: item.relatedEmployeeAvatarUrl,
                                    radius: 20,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    (item.relatedEmployeeName ?? 'Employee').toUpperCase(),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9.2,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ],
                              )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    EmployeeAvatar(
                                      initials: item.relatedEmployeeInitials ??
                                          ((item.relatedEmployeeName?.isNotEmpty ?? false)
                                              ? item.relatedEmployeeName!.substring(0, 1).toUpperCase()
                                              : 'E'),
                                      avatarUrl: item.relatedEmployeeAvatarUrl,
                                      radius: 20,
                                    ),
                                    const SizedBox(height: 8),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      child: Text(
                                        (item.relatedEmployeeName ?? 'Employee').toUpperCase(),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9.2,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ListMeta extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ListMeta({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

String _titleByType(FeedType type) {
  switch (type) {
    case FeedType.news:
      return 'News';
    case FeedType.announcement:
      return 'Announcements';
    case FeedType.lifeEvent:
      return 'Life Events';
  }
}

bool _isCondolence(FeedItem item) =>
    item.type == FeedType.lifeEvent && item.lifeEventCategory == LifeEventCategory.condolence;

class _FeedTypeChip extends StatelessWidget {
  final String label;
  final Color color;

  const _FeedTypeChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10.2,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _BereavedSummary extends StatelessWidget {
  final FeedItem item;
  final bool detailed;

  const _BereavedSummary({
    required this.item,
    this.detailed = false,
  });

  @override
  Widget build(BuildContext context) {
    final name = item.relatedEmployeeName ?? 'Employee';
    final initials = item.relatedEmployeeInitials ??
        (name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'E');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EmployeeAvatar(
          initials: initials,
          avatarUrl: item.relatedEmployeeAvatarUrl,
          radius: detailed ? 20 : 16,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontSize: detailed ? 12.8 : 11.8,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Bereaved employee',
                style: TextStyle(
                  fontSize: detailed ? 11 : 10.2,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Posted by ${item.author == 'People Team' ? 'HR Department' : item.author}',
                style: TextStyle(
                  fontSize: detailed ? 10.8 : 10.2,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
