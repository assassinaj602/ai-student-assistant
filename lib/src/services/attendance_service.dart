import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/attendance_record.dart';

/// Service for managing attendance records with Firebase
class AttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get the current user's ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Collection reference for attendance records
  CollectionReference get _attendanceCollection =>
      _firestore.collection('attendance_records');

  /// Add an attendance record
  Future<void> markAttendance({
    required String courseId,
    required String courseName,
    required AttendanceStatus status,
    String? notes,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final record = AttendanceRecord(
      id: '',
      userId: userId,
      courseId: courseId,
      courseName: courseName,
      date: DateTime.now(),
      status: status,
      notes: notes,
    );

    await _attendanceCollection.add(record.toMap());
  }

  /// Get attendance records for a specific course
  Stream<List<AttendanceRecord>> getCourseAttendance(String courseId) {
    final userId = currentUserId;
    if (userId == null) {
      print('DEBUG: No authenticated user for attendance query');
      return Stream.value([]);
    }

    print('DEBUG: Querying attendance for user: $userId, course: $courseId');

    // Try simple query first, then filter and sort in memory
    return _attendanceCollection
        .where('userId', isEqualTo: userId)
        .where('courseId', isEqualTo: courseId)
        .snapshots()
        .map((snapshot) {
          print('DEBUG: Received ${snapshot.docs.length} attendance records');
          final records =
              snapshot.docs.map((doc) {
                try {
                  final data = doc.data() as Map<String, dynamic>;
                  print(
                    'DEBUG: Processing attendance record: ${doc.id} -> $data',
                  );
                  return AttendanceRecord.fromMap(data, doc.id);
                } catch (e) {
                  print(
                    'ERROR: Failed to parse attendance record ${doc.id}: $e',
                  );
                  rethrow;
                }
              }).toList();

          // Sort by date in memory (descending - newest first)
          records.sort((a, b) => b.date.compareTo(a.date));
          return records;
        })
        .handleError((error) {
          print('ERROR: Firestore query failed: $error');
        });
  }

  /// Get all attendance records for current user
  Stream<List<AttendanceRecord>> getAllAttendance() {
    final userId = currentUserId;
    if (userId == null) return Stream.value([]);

    return _attendanceCollection
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => AttendanceRecord.fromMap(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    ),
                  )
                  .toList(),
        );
  }

  /// Get attendance statistics for a course
  Future<AttendanceStats> getCourseStats(String courseId) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    print('DEBUG: Getting stats for user: $userId, course: $courseId');

    try {
      final snapshot =
          await _attendanceCollection
              .where('userId', isEqualTo: userId)
              .where('courseId', isEqualTo: courseId)
              .get();

      print('DEBUG: Found ${snapshot.docs.length} records for stats');

      final records =
          snapshot.docs.map((doc) {
            try {
              final data = doc.data() as Map<String, dynamic>;
              return AttendanceRecord.fromMap(data, doc.id);
            } catch (e) {
              print('ERROR: Failed to parse record ${doc.id} for stats: $e');
              rethrow;
            }
          }).toList();

      final stats = AttendanceStats.fromRecords(records);
      print(
        'DEBUG: Generated stats: ${stats.totalClasses} total, ${stats.present} present, ${stats.attendanceRate}% rate',
      );
      return stats;
    } catch (e) {
      print('ERROR: Failed to get course stats: $e');
      // Return empty stats on error
      return AttendanceStats.empty();
    }
  }

  /// Update an existing attendance record
  Future<void> updateAttendance(
    String recordId,
    AttendanceStatus status, {
    String? notes,
  }) async {
    await _attendanceCollection.doc(recordId).update({
      'status': status.name,
      'notes': notes,
    });
  }

  /// Delete an attendance record
  Future<void> deleteAttendance(String recordId) async {
    await _attendanceCollection.doc(recordId).delete();
  }

  /// Get attendance records for a specific date range
  Stream<List<AttendanceRecord>> getAttendanceByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    String? courseId,
  }) {
    final userId = currentUserId;
    if (userId == null) return Stream.value([]);

    Query query = _attendanceCollection
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: startDate.millisecondsSinceEpoch)
        .where('date', isLessThanOrEqualTo: endDate.millisecondsSinceEpoch);

    if (courseId != null) {
      query = query.where('courseId', isEqualTo: courseId);
    }

    return query
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => AttendanceRecord.fromMap(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    ),
                  )
                  .toList(),
        );
  }

  /// Get today's attendance records
  Stream<List<AttendanceRecord>> getTodayAttendance() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

    return getAttendanceByDateRange(startDate: startOfDay, endDate: endOfDay);
  }

  /// Check if attendance is already marked for a course today
  Future<bool> isAttendanceMarkedToday(String courseId) async {
    final userId = currentUserId;
    if (userId == null) return false;

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

    final snapshot =
        await _attendanceCollection
            .where('userId', isEqualTo: userId)
            .where('courseId', isEqualTo: courseId)
            .where(
              'date',
              isGreaterThanOrEqualTo: startOfDay.millisecondsSinceEpoch,
            )
            .where('date', isLessThanOrEqualTo: endOfDay.millisecondsSinceEpoch)
            .limit(1)
            .get();

    return snapshot.docs.isNotEmpty;
  }
}

/// Statistics for course attendance
class AttendanceStats {
  final int totalClasses;
  final int present;
  final int absent;
  final int late;
  final double attendanceRate;

  const AttendanceStats({
    required this.totalClasses,
    required this.present,
    required this.absent,
    required this.late,
    required this.attendanceRate,
  });

  /// Create stats from attendance records
  factory AttendanceStats.fromRecords(List<AttendanceRecord> records) {
    final total = records.length;
    final present =
        records.where((r) => r.status == AttendanceStatus.present).length;
    final absent =
        records.where((r) => r.status == AttendanceStatus.absent).length;
    final late = records.where((r) => r.status == AttendanceStatus.late).length;

    final rate = total > 0 ? (present + late) / total * 100 : 0.0;

    return AttendanceStats(
      totalClasses: total,
      present: present,
      absent: absent,
      late: late,
      attendanceRate: rate,
    );
  }

  /// Empty stats for when no records exist
  factory AttendanceStats.empty() {
    return const AttendanceStats(
      totalClasses: 0,
      present: 0,
      absent: 0,
      late: 0,
      attendanceRate: 0.0,
    );
  }
}
