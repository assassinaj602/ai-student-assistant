import 'package:flutter/material.dart';

/// Attendance record model for tracking class attendance
class AttendanceRecord {
  final String id;
  final String userId;
  final String courseId;
  final String courseName;
  final DateTime date;
  final AttendanceStatus status;
  final String? notes;

  const AttendanceRecord({
    required this.id,
    required this.userId,
    required this.courseId,
    required this.courseName,
    required this.date,
    required this.status,
    this.notes,
  });

  /// Create AttendanceRecord from Firestore document data
  factory AttendanceRecord.fromMap(Map<String, dynamic> map, String id) {
    return AttendanceRecord(
      id: id,
      userId: map['userId'] as String,
      courseId: map['courseId'] as String,
      courseName: map['courseName'] as String,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      status: AttendanceStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => AttendanceStatus.absent,
      ),
      notes: map['notes'] as String?,
    );
  }

  /// Convert AttendanceRecord to Firestore document data
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'courseId': courseId,
      'courseName': courseName,
      'date': date.millisecondsSinceEpoch,
      'status': status.name,
      'notes': notes,
    };
  }

  /// Create a copy of AttendanceRecord with updated fields
  AttendanceRecord copyWith({
    String? id,
    String? userId,
    String? courseId,
    String? courseName,
    DateTime? date,
    AttendanceStatus? status,
    String? notes,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      courseId: courseId ?? this.courseId,
      courseName: courseName ?? this.courseName,
      date: date ?? this.date,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}

/// Attendance status enumeration
enum AttendanceStatus { present, absent, late, excused }

extension AttendanceStatusExtension on AttendanceStatus {
  String get displayName {
    switch (this) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.late:
        return 'Late';
      case AttendanceStatus.excused:
        return 'Excused';
    }
  }

  Color get color {
    switch (this) {
      case AttendanceStatus.present:
        return const Color(0xFF4CAF50); // Green
      case AttendanceStatus.absent:
        return const Color(0xFFF44336); // Red
      case AttendanceStatus.late:
        return const Color(0xFFFF9800); // Orange
      case AttendanceStatus.excused:
        return const Color(0xFF2196F3); // Blue
    }
  }

  IconData get icon {
    switch (this) {
      case AttendanceStatus.present:
        return Icons.check_circle;
      case AttendanceStatus.absent:
        return Icons.cancel;
      case AttendanceStatus.late:
        return Icons.schedule;
      case AttendanceStatus.excused:
        return Icons.info;
    }
  }
}
