import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/course.dart';
import '../models/attendance_record.dart';
import '../models/note.dart';
import '../providers/chat_attendance_providers.dart';
import 'note_editor.dart';

/// Class detail screen showing course information and attendance tracking
class ClassDetailScreen extends ConsumerStatefulWidget {
  final Course course;

  const ClassDetailScreen({super.key, required this.course});

  @override
  ConsumerState<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends ConsumerState<ClassDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.course.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Navigate to edit course
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'delete':
                  _showDeleteConfirmation();
                  break;
                case 'notifications':
                  _toggleNotifications();
                  break;
                case 'debug':
                  _addSampleData();
                  break;
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'notifications',
                    child: Row(
                      children: [
                        Icon(Icons.notifications),
                        SizedBox(width: 8),
                        Text('Toggle Notifications'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'debug',
                    child: Row(
                      children: [
                        Icon(Icons.bug_report, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('Add Sample Data'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete Course'),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course info card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Course Information',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _InfoRow(
                      icon: Icons.book,
                      label: 'Course',
                      value: widget.course.name,
                    ),
                    const SizedBox(height: 8),

                    _InfoRow(
                      icon: Icons.access_time,
                      label: 'Times',
                      value: widget.course.times,
                    ),
                    const SizedBox(height: 8),

                    if (widget.course.location.isNotEmpty) ...[
                      _InfoRow(
                        icon: Icons.location_on,
                        label: 'Location',
                        value: widget.course.location,
                      ),
                      const SizedBox(height: 8),
                    ],

                    _InfoRow(
                      icon: Icons.calendar_today,
                      label: 'Days',
                      value: widget.course.days
                          .map(
                            (day) =>
                                day.substring(0, 1).toUpperCase() +
                                day.substring(1),
                          )
                          .join(', '),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Attendance section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Attendance',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: _markAttendance,
                          tooltip: 'Mark Attendance',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Attendance stats
                    Consumer(
                      builder: (context, ref, child) {
                        final statsAsync = ref.watch(
                          courseAttendanceStatsProvider(widget.course.id),
                        );

                        return statsAsync.when(
                          data:
                              (stats) => LayoutBuilder(
                                builder: (context, constraints) {
                                  // Use column on narrow screens
                                  if (constraints.maxWidth < 300) {
                                    return Column(
                                      children: [
                                        _AttendanceStatCard(
                                          title: 'Present',
                                          count: stats.present,
                                          color: Colors.green,
                                        ),
                                        const SizedBox(height: 8),
                                        _AttendanceStatCard(
                                          title: 'Absent',
                                          count: stats.absent,
                                          color: Colors.red,
                                        ),
                                        const SizedBox(height: 8),
                                        _AttendanceStatCard(
                                          title: 'Rate',
                                          count: stats.attendanceRate.round(),
                                          color: Colors.blue,
                                          suffix: '%',
                                        ),
                                      ],
                                    );
                                  }

                                  // Use row on wider screens
                                  return IntrinsicHeight(
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: _AttendanceStatCard(
                                            title: 'Present',
                                            count: stats.present,
                                            color: Colors.green,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: _AttendanceStatCard(
                                            title: 'Absent',
                                            count: stats.absent,
                                            color: Colors.red,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: _AttendanceStatCard(
                                            title: 'Rate',
                                            count: stats.attendanceRate.round(),
                                            color: Colors.blue,
                                            suffix: '%',
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                          loading:
                              () => Row(
                                children: [
                                  Expanded(
                                    child: Card(
                                      child: Container(
                                        height: 80,
                                        child: const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Card(
                                      child: Container(
                                        height: 80,
                                        child: const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Card(
                                      child: Container(
                                        height: 80,
                                        child: const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          error:
                              (error, stack) => Row(
                                children: [
                                  Expanded(
                                    child: _AttendanceStatCard(
                                      title: 'Present',
                                      count: 0,
                                      color: Colors.green,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: _AttendanceStatCard(
                                      title: 'Absent',
                                      count: 0,
                                      color: Colors.red,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: _AttendanceStatCard(
                                      title: 'Rate',
                                      count: 0,
                                      color: Colors.blue,
                                      suffix: '%',
                                    ),
                                  ),
                                ],
                              ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // Recent attendance
                    Text(
                      'Recent Attendance',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Recent attendance records
                    Consumer(
                      builder: (context, ref, child) {
                        final attendanceAsync = ref.watch(
                          courseAttendanceProvider(widget.course.id),
                        );

                        return attendanceAsync.when(
                          data: (records) {
                            if (records.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.event_note,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'No attendance records yet',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(color: Colors.grey[600]),
                                    ),
                                    const SizedBox(height: 8),
                                    TextButton.icon(
                                      onPressed: _markAttendance,
                                      icon: const Icon(Icons.add),
                                      label: const Text(
                                        'Mark First Attendance',
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount:
                                  records.length > 5 ? 5 : records.length,
                              separatorBuilder:
                                  (context, index) => const Divider(),
                              itemBuilder: (context, index) {
                                final record = records[index];
                                return ListTile(
                                  leading: Icon(
                                    record.status.icon,
                                    color: record.status.color,
                                  ),
                                  title: Text(
                                    '${record.date.day}/${record.date.month}/${record.date.year}',
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(record.status.displayName),
                                      if (record.notes?.isNotEmpty == true)
                                        Text(
                                          record.notes!,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall?.copyWith(
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed:
                                        () => _editAttendanceRecord(record),
                                  ),
                                  contentPadding: EdgeInsets.zero,
                                );
                              },
                            );
                          },
                          loading:
                              () => const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(24),
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                          error:
                              (error, stack) => Container(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      size: 48,
                                      color: Colors.red[400],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Error loading attendance',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(color: Colors.red[600]),
                                    ),
                                    const SizedBox(height: 8),
                                    TextButton(
                                      onPressed:
                                          () => ref.refresh(
                                            courseAttendanceProvider(
                                              widget.course.id,
                                            ),
                                          ),
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Notes section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Course Notes',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add Note'),
                          onPressed: () async {
                            final result = await Navigator.of(
                              context,
                            ).push<Note>(
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        NoteEditor(courseId: widget.course.id),
                              ),
                            );
                            if (result != null) {
                              // Note was created - could show confirmation or refresh notes
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Note created successfully!'),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // TODO: Replace with actual notes from provider
                    const Text('No notes yet. Add your first note!'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _markAttendance() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Mark Attendance'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Mark your attendance for today:'),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _AttendanceOptionCard(
                      status: AttendanceStatus.present,
                      onTap: () {
                        Navigator.of(context).pop();
                        _markAttendanceStatus(AttendanceStatus.present);
                      },
                    ),
                    _AttendanceOptionCard(
                      status: AttendanceStatus.absent,
                      onTap: () {
                        Navigator.of(context).pop();
                        _markAttendanceStatus(AttendanceStatus.absent);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _AttendanceOptionCard(
                      status: AttendanceStatus.late,
                      onTap: () {
                        Navigator.of(context).pop();
                        _markAttendanceStatus(AttendanceStatus.late);
                      },
                    ),
                    _AttendanceOptionCard(
                      status: AttendanceStatus.excused,
                      onTap: () {
                        Navigator.of(context).pop();
                        _markAttendanceStatus(AttendanceStatus.excused);
                      },
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }

  Future<void> _markAttendanceStatus(AttendanceStatus status) async {
    try {
      final attendanceActions = ref.read(attendanceActionsProvider);
      await attendanceActions.markAttendance(
        courseId: widget.course.id,
        courseName: widget.course.name,
        status: status,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Marked as ${status.displayName.toLowerCase()}'),
            backgroundColor: status.color,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error marking attendance: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _editAttendanceRecord(AttendanceRecord record) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Attendance'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Edit attendance for ${record.date.day}/${record.date.month}/${record.date.year}',
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _AttendanceOptionCard(
                      status: AttendanceStatus.present,
                      isSelected: record.status == AttendanceStatus.present,
                      onTap: () {
                        Navigator.of(context).pop();
                        _updateAttendanceStatus(
                          record,
                          AttendanceStatus.present,
                        );
                      },
                    ),
                    _AttendanceOptionCard(
                      status: AttendanceStatus.absent,
                      isSelected: record.status == AttendanceStatus.absent,
                      onTap: () {
                        Navigator.of(context).pop();
                        _updateAttendanceStatus(
                          record,
                          AttendanceStatus.absent,
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _AttendanceOptionCard(
                      status: AttendanceStatus.late,
                      isSelected: record.status == AttendanceStatus.late,
                      onTap: () {
                        Navigator.of(context).pop();
                        _updateAttendanceStatus(record, AttendanceStatus.late);
                      },
                    ),
                    _AttendanceOptionCard(
                      status: AttendanceStatus.excused,
                      isSelected: record.status == AttendanceStatus.excused,
                      onTap: () {
                        Navigator.of(context).pop();
                        _updateAttendanceStatus(
                          record,
                          AttendanceStatus.excused,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _deleteAttendanceRecord(record);
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _updateAttendanceStatus(
    AttendanceRecord record,
    AttendanceStatus newStatus,
  ) async {
    try {
      final attendanceActions = ref.read(attendanceActionsProvider);
      await attendanceActions.updateAttendance(record.id, newStatus);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Updated to ${newStatus.displayName.toLowerCase()}'),
            backgroundColor: newStatus.color,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating attendance: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteAttendanceRecord(AttendanceRecord record) async {
    try {
      final attendanceActions = ref.read(attendanceActionsProvider);
      await attendanceActions.deleteAttendance(record.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attendance record deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting attendance: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Debug helper to add sample attendance data
  Future<void> _addSampleData() async {
    try {
      final attendanceActions = ref.read(attendanceActionsProvider);

      // Add some sample attendance records
      await attendanceActions.markAttendance(
        courseId: widget.course.id,
        courseName: widget.course.name,
        status: AttendanceStatus.present,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sample attendance data added!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding sample data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleNotifications() {
    // TODO: Implement notification toggle
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Notifications toggled')));
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Course'),
            content: Text(
              'Are you sure you want to delete "${widget.course.name}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _deleteCourse();
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  void _deleteCourse() {
    // TODO: Implement course deletion
    Navigator.of(context).pop();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Course deleted')));
  }
}

/// Info row widget for displaying course details
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).primaryColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Attendance statistics card
class _AttendanceStatCard extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final String suffix;

  const _AttendanceStatCard({
    required this.title,
    required this.count,
    required this.color,
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            '$count$suffix',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget for attendance option selection
class _AttendanceOptionCard extends StatelessWidget {
  final AttendanceStatus status;
  final bool isSelected;
  final VoidCallback onTap;

  const _AttendanceOptionCard({
    required this.status,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: isSelected ? status.color : status.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: status.color, width: isSelected ? 2 : 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              status.icon,
              color: isSelected ? Colors.white : status.color,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              status.displayName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isSelected ? Colors.white : status.color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
