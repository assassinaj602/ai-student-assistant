# Attendance Validation Flow Diagram

## High-Level Flow
```
User Clicks "Mark Attendance"
         ↓
┌────────────────────────────┐
│  Class Detail Screen       │
│  _markAttendance()         │
└────────────────────────────┘
         ↓
    Check if scheduled today
         ↓
┌────────────────────────────┐
│  Show Dialog with Warning  │
│  (if not scheduled)        │
└────────────────────────────┘
         ↓
    User selects status
         ↓
┌────────────────────────────┐
│  _markAttendanceStatus()   │
│  + course parameter        │
└────────────────────────────┘
         ↓
┌────────────────────────────┐
│  AttendanceActions         │
│  .markAttendance()         │
└────────────────────────────┘
         ↓
┌────────────────────────────┐
│  AttendanceService         │
│  .markAttendance()         │
└────────────────────────────┘
         ↓
  ┌─── Validation Layer ───┐
  │                         │
  │  1. Future Date Check   │
  │     ↓ Pass              │
  │  2. Duplicate Check     │
  │     ↓ Pass              │
  │  3. Schedule Day Check  │
  │     ↓ Pass              │
  └─────────────────────────┘
         ↓
┌────────────────────────────┐
│  Save to Firestore         │
└────────────────────────────┘
         ↓
    Success Message
```

## Validation Details

### Validation 1: Future Date Check
```dart
Input: attendanceDate, DateTime.now()
Process:
  - Normalize both dates to day-level (remove time)
  - Compare: targetDay > today?
  - If yes: throw "Cannot mark attendance for future dates"
Output: Pass or Exception
```

### Validation 2: Duplicate Check
```dart
Input: courseId, date
Process:
  - Query Firestore for existing attendance records
  - Filter: userId, courseId, date range (start to end of day)
  - Check: snapshot.docs.isNotEmpty?
  - If yes: throw "Attendance already marked for [date]"
Output: Pass or Exception
```

### Validation 3: Schedule Day Check
```dart
Input: course, attendanceDate
Process:
  - If course is null: skip validation
  - Call: course.isScheduledFor(attendanceDate)
  - Get day name from weekday index
  - Check: course.days.contains(dayName)?
  - If no: throw "Class is not scheduled on [dayName]"
Output: Pass or Exception
```

## Error Handling Flow

```
Exception Thrown
     ↓
┌───────────────────────────────┐
│  _markAttendanceStatus()      │
│  catch block                  │
└───────────────────────────────┘
     ↓
Extract error message
(remove "Exception: " prefix)
     ↓
┌───────────────────────────────┐
│  Show SnackBar                │
│  - Red background             │
│  - 4 second duration          │
│  - "OK" action button         │
└───────────────────────────────┘
     ↓
User dismisses or auto-dismiss
```

## UI Warning Flow (Non-Scheduled Day)

```
User clicks "Mark Attendance"
     ↓
Check: widget.course.isScheduledFor(today)
     ↓
Returns: false
     ↓
┌─────────────────────────────────────┐
│  Show Dialog with Warning Banner    │
│  ┌───────────────────────────────┐  │
│  │ ⚠️ Class not scheduled today  │  │
│  └───────────────────────────────┘  │
│                                     │
│  "This class is scheduled on:       │
│   Monday, Wednesday, Friday"        │
│                                     │
│  ─────────────────────────────      │
│                                     │
│  "Mark your attendance for today:"  │
│                                     │
│  [Present] [Absent]                 │
│  [Late]    [Excused]                │
└─────────────────────────────────────┘
     ↓
User can still proceed (for makeup classes)
     ↓
Validation will still catch if not scheduled
```

## Data Structure

### Course Model
```dart
class Course {
  final List<String> days; // ['monday', 'wednesday', 'friday']
  
  bool isScheduledFor(DateTime date) {
    final dayNames = ['monday', 'tuesday', ..., 'sunday'];
    final dayName = dayNames[date.weekday - 1];
    return days.contains(dayName);
  }
}
```

### AttendanceRecord Model
```dart
class AttendanceRecord {
  final String courseId;
  final DateTime date; // stored as millisecondsSinceEpoch
  final AttendanceStatus status;
  // ... other fields
}
```

## Database Queries

### Check for Duplicate (hasAttendanceForDate)
```dart
Query:
  collection: 'attendance_records'
  where: 
    - userId == currentUserId
    - courseId == targetCourseId
    - date >= startOfDay (00:00:00)
    - date <= endOfDay (23:59:59)
  limit: 1

Result: snapshot.docs.isNotEmpty
```

### Save Attendance
```dart
Collection: 'attendance_records'
Document: Auto-generated ID
Data:
  - userId: string
  - courseId: string
  - courseName: string
  - date: int (millisecondsSinceEpoch)
  - status: string ('present', 'absent', 'late', 'excused')
  - notes: string? (optional)
```

## Edge Cases

### Case 1: Marking at Midnight
- **Scenario**: User marks attendance at 11:59 PM
- **Handling**: Date normalized to day-level, still counts as "today"
- **Result**: Valid

### Case 2: Makeup Class on Non-Scheduled Day
- **Scenario**: Class normally on Monday, makeup on Friday
- **Handling**: 
  1. Warning shown in dialog
  2. User can still select status
  3. Validation error on submit
- **Result**: Blocked (user would need to edit course schedule temporarily)

### Case 3: Rapid Duplicate Clicks
- **Scenario**: User double-clicks attendance button
- **Handling**: 
  1. First request checks Firestore (no records)
  2. First request saves
  3. Second request checks Firestore (finds record)
  4. Second request throws duplicate error
- **Result**: Only one record saved

### Case 4: Editing Existing Attendance
- **Scenario**: User wants to change status from "Absent" to "Present"
- **Handling**: 
  1. Uses `updateAttendance()` method (separate from `markAttendance()`)
  2. No validation needed (record already exists)
  3. Updates existing document
- **Result**: Status changed successfully

## Performance Considerations

1. **Validation Order**: Fast checks first (future date), expensive checks last (Firestore query)
2. **Query Optimization**: Uses compound indexes and limit(1) for duplicate check
3. **UI Responsiveness**: Warning shown immediately (no server call), validation on submit
4. **Error Messages**: Pre-computed and user-friendly (no technical jargon)

## Security Notes

- **Server-Side Validation**: Firestore Security Rules should mirror these validations
- **User Authentication**: All queries filtered by `currentUserId`
- **Data Integrity**: Multiple validation layers prevent bad data
- **Audit Trail**: All attendance records include userId and timestamp
