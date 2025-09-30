/// Course model representing classes in the timetable
class Course {
  final String id;
  final String userId;
  final String name;
  final List<String> days; // e.g., ['monday', 'wednesday', 'friday']
  final String times; // e.g., '9:00 - 10:30'
  final String location;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool notificationsEnabled;

  const Course({
    required this.id,
    required this.userId,
    required this.name,
    required this.days,
    required this.times,
    this.location = '',
    required this.createdAt,
    required this.updatedAt,
    this.notificationsEnabled = true,
  });

  /// Create Course from Firestore document data
  factory Course.fromMap(Map<String, dynamic> map, String id) {
    return Course(
      id: id,
      userId: map['userId'] as String? ?? '',
      name: map['name'] as String,
      days: List<String>.from(map['days'] as List),
      times: map['times'] as String,
      location: map['location'] as String? ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
      notificationsEnabled: map['notificationsEnabled'] as bool? ?? true,
    );
  }

  /// Convert Course to Firestore document data
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'days': days,
      'times': times,
      'location': location,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'notificationsEnabled': notificationsEnabled,
    };
  }

  /// Create Course from local database data
  factory Course.fromLocalMap(Map<String, dynamic> map) {
    return Course(
      id: map['id'] as String,
      userId: map['userId'] as String,
      name: map['name'] as String,
      days: (map['days'] as String).split(','),
      times: map['times'] as String,
      location: map['location'] as String? ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
      notificationsEnabled: (map['notificationsEnabled'] as int) == 1,
    );
  }

  /// Convert Course to local database data
  Map<String, dynamic> toLocalMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'days': days.join(','),
      'times': times,
      'location': location,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'notificationsEnabled': notificationsEnabled ? 1 : 0,
      'synced': 0, // Always mark as unsynced when creating local entries
    };
  }

  /// Create a copy of Course with updated fields
  Course copyWith({
    String? id,
    String? userId,
    String? name,
    List<String>? days,
    String? times,
    String? location,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? notificationsEnabled,
  }) {
    return Course(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      days: days ?? this.days,
      times: times ?? this.times,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  /// Get formatted days string for display
  String get formattedDays {
    return days
        .map((day) => day.substring(0, 1).toUpperCase() + day.substring(1))
        .join(', ');
  }

  /// Check if course is scheduled for a specific day
  bool isScheduledFor(DateTime date) {
    final dayName =
        [
          'monday',
          'tuesday',
          'wednesday',
          'thursday',
          'friday',
          'saturday',
          'sunday',
        ][date.weekday - 1];
    return days.contains(dayName);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Course && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Course(id: $id, name: $name, days: $days, times: $times)';
  }
}
