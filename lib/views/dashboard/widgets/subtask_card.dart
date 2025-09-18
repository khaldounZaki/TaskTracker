import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../data/models/subtask_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../utils/theme.dart';

class SubtaskCard extends StatefulWidget {
  final SubtaskModel subtask;
  final VoidCallback? onComplete;

  const SubtaskCard({super.key, required this.subtask, this.onComplete});

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
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => _expanded = !_expanded),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF3E5F5), Color(0xFFE1BEE7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppTheme.shadow.withOpacity(0.15),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Description + Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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
                ],
              ),
              const SizedBox(height: 6),

              // From → To with current user highlight
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
                  const Text(' → ', style: TextStyle(color: AppTheme.subtitle)),
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

              // Expanded content
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'Result: ${widget.subtask.result.isEmpty ? "N/A" : widget.subtask.result}',
                      style: const TextStyle(color: AppTheme.subtitle),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Created: ${_formatDate(widget.subtask.createdAt)}',
                            style: const TextStyle(
                              color: AppTheme.subtitle,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Completed: ${widget.subtask.completedAt != null ? _formatDate(widget.subtask.completedAt) : "Not yet"}',
                            style: const TextStyle(
                              color: AppTheme.subtitle,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (widget.subtask.status == 'pending' &&
                        widget.subtask.toUser == currentUid)
                      SizedBox(
                        width: double.infinity,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: AppTheme.buttonGradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextButton(
                            onPressed: widget.onComplete,
                            child: const Text(
                              'Mark Done',
                              style: TextStyle(
                                color: AppTheme.buttonText,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      )
                    else if (widget.subtask.status == 'done')
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.check, color: Colors.green),
                        ),
                      ),
                  ],
                ),
                crossFadeState: _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 250),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
