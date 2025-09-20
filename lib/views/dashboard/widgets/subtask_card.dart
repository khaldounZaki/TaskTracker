import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../data/models/subtask_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../utils/theme.dart';
import '../../tasks/subtask_detail_page.dart';

class SubtaskCard extends StatefulWidget {
  final String taskId; // ✅ parent task ID
  final SubtaskModel subtask;
  final VoidCallback? onComplete;

  const SubtaskCard({
    super.key,
    required this.taskId,
    required this.subtask,
    this.onComplete,
  });

  @override
  State<SubtaskCard> createState() => _SubtaskCardState();
}

class _SubtaskCardState extends State<SubtaskCard> {
  bool _expanded = false;

  Stream<AppUser?> _streamUser(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? AppUser.fromDoc(doc) : null);
  }

  String _formatDate(dynamic ts) {
    if (ts == null) return "N/A";
    if (ts is Timestamp)
      return DateFormat('yyyy-MM-dd HH:mm').format(ts.toDate());
    if (ts is DateTime) return DateFormat('yyyy-MM-dd HH:mm').format(ts);
    return "Invalid date";
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'done':
        return Colors.green;
      case 'pending':
        return AppTheme.button;
      default:
        return AppTheme.subtitle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final currentUid = auth.currentUser?.uid;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 3,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SubtaskDetailPage(
                  taskId: widget.taskId,
                  subtask: widget.subtask,
                  onComplete: widget.onComplete,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- HEADER: description + status + expand button ---
                Row(
                  children: [
                    Icon(
                      widget.subtask.status == "done"
                          ? Icons.check_circle
                          : Icons.pending_actions,
                      color: _statusColor(widget.subtask.status),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.subtask.description,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.title,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor(widget.subtask.status),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.subtask.status.toUpperCase(),
                        style: const TextStyle(
                          color: AppTheme.buttonText,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: AppTheme.subtitle,
                      ),
                      onPressed: () => setState(() => _expanded = !_expanded),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // --- FROM → TO row with current user highlight ---
                Row(
                  children: [
                    StreamBuilder<AppUser?>(
                      stream: _streamUser(widget.subtask.fromUser),
                      builder: (context, snapshot) {
                        String fromName = snapshot.hasData
                            ? snapshot.data!.name
                            : 'Unknown';
                        bool isCurrent = widget.subtask.fromUser == currentUid;
                        return Flexible(
                          child: Text(
                            'From: $fromName',
                            style: TextStyle(
                              color: isCurrent
                                  ? AppTheme.button
                                  : AppTheme.subtitle,
                              fontWeight: isCurrent
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      },
                    ),
                    const Text(
                      ' → ',
                      style: TextStyle(color: AppTheme.subtitle),
                    ),
                    StreamBuilder<AppUser?>(
                      stream: _streamUser(widget.subtask.toUser),
                      builder: (context, snapshot) {
                        String toName = snapshot.hasData
                            ? snapshot.data!.name
                            : 'Unknown';
                        bool isCurrent = widget.subtask.toUser == currentUid;
                        return Flexible(
                          child: Text(
                            'To: $toName',
                            style: TextStyle(
                              color: isCurrent
                                  ? AppTheme.button
                                  : AppTheme.subtitle,
                              fontWeight: isCurrent
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      },
                    ),
                  ],
                ),

                // --- EXPANDABLE AREA ---
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  child: _expanded
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Text(
                              "Result: ${widget.subtask.result.isEmpty ? "N/A" : widget.subtask.result}",
                              style: const TextStyle(color: AppTheme.subtitle),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Created: ${_formatDate(widget.subtask.createdAt)}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.subtitle,
                              ),
                            ),
                            Text(
                              "Completed: ${widget.subtask.completedAt != null ? _formatDate(widget.subtask.completedAt) : "Not yet"}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.subtitle,
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (widget.subtask.status == 'pending' &&
                                widget.subtask.toUser == currentUid)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.button,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: widget.onComplete,
                                  child: const Text(
                                    "Mark Done",
                                    style: TextStyle(
                                      color: AppTheme.buttonText,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
