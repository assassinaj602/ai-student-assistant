import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/course.dart';

/// Timetable provider notifier for managing courses
class TimetableNotifier extends StateNotifier<AsyncValue<List<Course>>> {
  TimetableNotifier() : super(const AsyncValue.loading()) {
    _init();
  }

  /// Get courses collection reference for current user
  CollectionReference get _coursesCollection {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('courses');
  }

  /// Initialize timetable data
  Future<void> _init() async {
    try {
      await loadCourses();

      // Listen to Firebase stream for real-time updates
      _coursesCollection.snapshots().listen(
        (snapshot) {
          print(
            'DEBUG: Firestore snapshot received with ${snapshot.docs.length} courses',
          );
          final courses =
              snapshot.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                print('DEBUG: Course data from Firestore: ${doc.id} -> $data');
                // Convert Firestore Timestamps to milliseconds
                if (data['createdAt'] is Timestamp) {
                  data['createdAt'] =
                      (data['createdAt'] as Timestamp).millisecondsSinceEpoch;
                }
                if (data['updatedAt'] is Timestamp) {
                  data['updatedAt'] =
                      (data['updatedAt'] as Timestamp).millisecondsSinceEpoch;
                }
                return Course.fromMap(data, doc.id);
              }).toList();
          print('DEBUG: Parsed ${courses.length} courses for UI');
          state = AsyncValue.data(courses);
        },
        onError: (error) {
          print('DEBUG: Firestore stream error: $error');
          state = AsyncValue.error(error, StackTrace.current);
        },
      );
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Load courses from Firestore
  Future<void> loadCourses() async {
    try {
      final snapshot = await _coursesCollection.get();
      final courses =
          snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            // Convert Firestore Timestamps to milliseconds
            if (data['createdAt'] is Timestamp) {
              data['createdAt'] =
                  (data['createdAt'] as Timestamp).millisecondsSinceEpoch;
            }
            if (data['updatedAt'] is Timestamp) {
              data['updatedAt'] =
                  (data['updatedAt'] as Timestamp).millisecondsSinceEpoch;
            }
            return Course.fromMap(data, doc.id);
          }).toList();
      state = AsyncValue.data(courses);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Add a new course
  Future<void> addCourse(Course course) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final now = DateTime.now();
      final courseData =
          course
              .copyWith(userId: user.uid, createdAt: now, updatedAt: now)
              .toMap();

      // Convert to Firestore Timestamps
      courseData['createdAt'] = Timestamp.fromDate(now);
      courseData['updatedAt'] = Timestamp.fromDate(now);

      print('DEBUG: Adding course to Firestore: $courseData');
      final docRef = await _coursesCollection.add(courseData);
      print('DEBUG: Course added with ID: ${docRef.id}');
    } catch (e) {
      print('DEBUG: Error adding course: $e');
      throw Exception('Failed to add course: $e');
    }
  }

  /// Update an existing course
  Future<void> updateCourse(Course course) async {
    try {
      if (course.id.isEmpty) throw Exception('Course ID cannot be empty');

      final now = DateTime.now();
      final courseData = course.copyWith(updatedAt: now).toMap();

      // Convert to Firestore Timestamps
      courseData['updatedAt'] = Timestamp.fromDate(now);

      await _coursesCollection.doc(course.id).update(courseData);
    } catch (e) {
      throw Exception('Failed to update course: $e');
    }
  }

  /// Delete a course
  Future<void> deleteCourse(String courseId) async {
    try {
      await _coursesCollection.doc(courseId).delete();
    } catch (e) {
      throw Exception('Failed to delete course: $e');
    }
  }

  /// Get courses for a specific day
  List<Course> getCoursesForDay(String day) {
    final courses = state.value ?? [];
    return courses
        .where((course) => course.days.contains(day.toLowerCase()))
        .toList();
  }

  /// Get courses scheduled for today
  List<Course> getTodaysCourses() {
    final today = DateTime.now();
    final dayNames = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    final todayName = dayNames[today.weekday - 1];
    return getCoursesForDay(todayName);
  }

  /// Get upcoming courses (next 7 days)
  List<Course> getUpcomingCourses() {
    final courses = state.value ?? [];
    final upcomingCourses = <Course>[];

    for (int i = 0; i < 7; i++) {
      final date = DateTime.now().add(Duration(days: i));
      final dayNames = [
        'monday',
        'tuesday',
        'wednesday',
        'thursday',
        'friday',
        'saturday',
        'sunday',
      ];
      final dayName = dayNames[date.weekday - 1];

      for (final course in courses) {
        if (course.days.contains(dayName) &&
            !upcomingCourses.contains(course)) {
          upcomingCourses.add(course);
        }
      }
    }

    return upcomingCourses;
  }

  /// Toggle notifications for a course
  Future<void> toggleNotifications(String courseId) async {
    try {
      final courses = state.value ?? [];
      final course = courses.firstWhere((c) => c.id == courseId);

      final updatedCourse = course.copyWith(
        notificationsEnabled: !course.notificationsEnabled,
        updatedAt: DateTime.now(),
      );

      await updateCourse(updatedCourse);
    } catch (e) {
      throw Exception('Failed to toggle notifications: $e');
    }
  }

  /// Force refresh data from Firebase
  Future<void> refresh() async {
    await loadCourses();
  }
}

/// Timetable provider
final timetableProvider =
    StateNotifierProvider<TimetableNotifier, AsyncValue<List<Course>>>((ref) {
      return TimetableNotifier();
    });

/// Courses provider (alias for easier access)
final coursesProvider = Provider<AsyncValue<List<Course>>>((ref) {
  return ref.watch(timetableProvider);
});

/// Today's courses provider
final todaysCoursesProvider = Provider<List<Course>>((ref) {
  final coursesAsync = ref.watch(coursesProvider);
  return coursesAsync.when(
    data: (courses) {
      final today = DateTime.now();
      final dayNames = [
        'monday',
        'tuesday',
        'wednesday',
        'thursday',
        'friday',
        'saturday',
        'sunday',
      ];
      final todayName = dayNames[today.weekday - 1];
      return courses
          .where((course) => course.days.contains(todayName))
          .toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Upcoming courses provider
final upcomingCoursesProvider = Provider<List<Course>>((ref) {
  final coursesAsync = ref.watch(coursesProvider);
  return coursesAsync.when(
    data: (courses) {
      final upcomingCourses = <Course>[];
      for (int i = 0; i < 7; i++) {
        final date = DateTime.now().add(Duration(days: i));
        final dayNames = [
          'monday',
          'tuesday',
          'wednesday',
          'thursday',
          'friday',
          'saturday',
          'sunday',
        ];
        final dayName = dayNames[date.weekday - 1];

        for (final course in courses) {
          if (course.days.contains(dayName) &&
              !upcomingCourses.contains(course)) {
            upcomingCourses.add(course);
          }
        }
      }
      return upcomingCourses;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});
