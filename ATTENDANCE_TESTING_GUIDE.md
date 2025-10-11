# Attendance Validation Testing Guide

## Prerequisites
1. Have at least one course created with specific scheduled days
2. Know which days your test course is scheduled for
3. Have the app running (web or mobile)

## Test Scenarios

### ✅ Test 1: Normal Attendance Marking (Expected: Success)

**Steps:**
1. Create a course scheduled for today's day of the week
   - Example: If today is Monday, create course with "Monday" selected
2. Open the course detail screen
3. Click "Mark Attendance" button
4. Dialog should show "Mark your attendance for today:"
5. No warning banner should appear
6. Select "Present"

**Expected Result:**
- ✅ Success message: "Marked as present"
- ✅ Attendance appears in the list below
- ✅ Stats update (Present count increases)

---

### ❌ Test 2: Duplicate Attendance (Expected: Error)

**Steps:**
1. Use the same course from Test 1 (attendance already marked today)
2. Click "Mark Attendance" button again
3. Select any status (e.g., "Absent")

**Expected Result:**
- ❌ Error message: "Attendance already marked for [today's date]"
- ❌ Red snackbar with "OK" button
- ❌ No new attendance record created
- ✅ Can dismiss error and try again

**Verification:**
- Open attendance list
- Should only see ONE record for today's date

---

### ⚠️ Test 3: Wrong Day Warning (Expected: Warning + Error)

**Steps:**
1. Create or use a course NOT scheduled for today
   - Example: If today is Monday, use a course scheduled only on "Wednesday, Friday"
2. Open the course detail screen
3. Click "Mark Attendance" button

**Expected Result - Part 1 (Warning):**
- ⚠️ Orange warning banner: "Class not scheduled today"
- ⚠️ Message: "This class is scheduled on: [course days]"
- ✅ Can still select attendance options

**Steps - Part 2:**
4. Select any status (e.g., "Present")

**Expected Result - Part 2 (Error):**
- ❌ Error message: "Class is not scheduled on [day name]. Scheduled days: [course days]"
- ❌ Red snackbar appears
- ❌ No attendance record created

---

### ❌ Test 4: Future Date Prevention (Expected: Error)

**Note:** This requires code modification to test, as the current UI always uses today's date.

**Manual Test (Requires Dev Tools):**
```dart
// In class_detail_screen.dart, temporarily modify _markAttendanceStatus:
await attendanceActions.markAttendance(
  courseId: widget.course.id,
  courseName: widget.course.name,
  status: status,
  course: widget.course,
  date: DateTime.now().add(Duration(days: 1)), // Tomorrow
);
```

**Expected Result:**
- ❌ Error message: "Cannot mark attendance for future dates"
- ❌ Red snackbar appears
- ❌ No attendance record created

**Revert Changes:** Remove the test code after verification

---

### ✅ Test 5: Edit Existing Attendance (Expected: Success)

**Steps:**
1. Use a course with existing attendance marked today
2. In the attendance list, click the edit icon (✏️) next to today's record
3. Select a different status (e.g., change from "Present" to "Late")

**Expected Result:**
- ✅ Success message: "Attendance updated"
- ✅ Record updates in the list immediately
- ✅ Stats recalculate correctly
- ✅ Only ONE record exists for today (not a duplicate)

---

### ✅ Test 6: Multiple Courses Same Day (Expected: Success)

**Steps:**
1. Create two different courses, both scheduled for today
   - Course A: "Mathematics" - Monday, Wednesday, Friday
   - Course B: "Physics" - Monday, Wednesday, Friday
2. Mark attendance for Course A as "Present"
3. Mark attendance for Course B as "Absent"

**Expected Result:**
- ✅ Both courses can have attendance marked on same day
- ✅ Each course maintains separate attendance records
- ✅ No "duplicate" errors between different courses

---

### ✅ Test 7: Past Date Attendance (Expected: Success)

**Note:** Current UI defaults to today, but service supports custom dates.

**Manual Test (If date picker added in future):**
```dart
// Use yesterday's date
await attendanceActions.markAttendance(
  courseId: widget.course.id,
  courseName: widget.course.name,
  status: status,
  course: widget.course,
  date: DateTime.now().subtract(Duration(days: 1)),
);
```

**Expected Result:**
- ✅ Attendance marked for yesterday
- ✅ No future date error
- ✅ Schedule validation still applies

---

## Automated Testing (Optional)

### Unit Test: hasAttendanceForDate
```dart
test('hasAttendanceForDate returns true when attendance exists', () async {
  // Given: Attendance record exists for today
  final service = AttendanceService();
  await service.markAttendance(
    courseId: 'test-course',
    courseName: 'Test Course',
    status: AttendanceStatus.present,
  );
  
  // When: Check if attendance exists
  final exists = await service.hasAttendanceForDate(
    courseId: 'test-course',
    date: DateTime.now(),
  );
  
  // Then: Should return true
  expect(exists, true);
});
```

### Unit Test: Future Date Validation
```dart
test('markAttendance throws error for future dates', () async {
  final service = AttendanceService();
  final tomorrow = DateTime.now().add(Duration(days: 1));
  
  expect(
    () => service.markAttendance(
      courseId: 'test-course',
      courseName: 'Test Course',
      status: AttendanceStatus.present,
      date: tomorrow,
    ),
    throwsA(predicate((e) => 
      e.toString().contains('Cannot mark attendance for future dates')
    )),
  );
});
```

### Unit Test: Schedule Day Validation
```dart
test('markAttendance throws error for non-scheduled days', () async {
  // Given: Course scheduled only on Monday
  final course = Course(
    id: 'test-course',
    userId: 'test-user',
    name: 'Test Course',
    days: ['monday'],
    times: '10:00 - 11:00',
    location: 'Room 101',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
  
  // When: Try to mark attendance on Tuesday
  final service = AttendanceService();
  // (Assume today is Tuesday for this test)
  
  // Then: Should throw error
  expect(
    () => service.markAttendance(
      courseId: course.id,
      courseName: course.name,
      status: AttendanceStatus.present,
      course: course,
    ),
    throwsA(predicate((e) => 
      e.toString().contains('Class is not scheduled')
    )),
  );
});
```

---

## Bug Report Template

If any test fails, use this template:

```
**Test:** [Test name/number]
**Expected:** [What should happen]
**Actual:** [What actually happened]
**Steps to Reproduce:**
1. 
2. 
3. 

**Screenshots:** [If applicable]
**Device/Platform:** [Web/Android/iOS]
**Course Configuration:**
- Course Name: 
- Scheduled Days: 
- Test Day: 

**Console Logs:** [Any errors from console]
```

---

## Verification Checklist

After running all tests, verify:

- [ ] Cannot mark duplicate attendance on same day for same course
- [ ] Warning appears when marking attendance on non-scheduled days
- [ ] Error appears when trying to mark on non-scheduled days (if proceeded past warning)
- [ ] Cannot mark attendance for future dates
- [ ] Can successfully mark attendance on scheduled days
- [ ] Can edit existing attendance records
- [ ] Multiple courses can have attendance on same day
- [ ] Stats update correctly after marking/editing
- [ ] Error messages are user-friendly and clear
- [ ] Success messages appear for valid operations
- [ ] UI remains responsive during operations

---

## Common Issues & Solutions

### Issue: No error appears on duplicate
**Solution:** Check Firestore connection, verify user is authenticated

### Issue: Warning doesn't show on wrong day
**Solution:** Verify course.days array contains lowercase day names ('monday', not 'Monday')

### Issue: Can mark future attendance
**Solution:** Check system clock, verify date comparison logic

### Issue: Stats not updating
**Solution:** Refresh the page/screen, check Firestore listeners

---

## Database Verification

Use Firebase Console to verify:

1. **Check Attendance Collection:**
   ```
   Firebase Console → Firestore Database → attendance_records
   ```

2. **Verify Record Structure:**
   ```json
   {
     "userId": "abc123",
     "courseId": "xyz789",
     "courseName": "Mathematics",
     "date": 1704067200000,
     "status": "present",
     "notes": null
   }
   ```

3. **Check for Duplicates:**
   - Filter by courseId and date
   - Should see max 1 record per course per day per user

4. **Verify Indexes:**
   ```
   Collection: attendance_records
   Indexes needed:
   - userId, courseId, date (ascending)
   - userId, date (ascending)
   ```

---

## Performance Testing

1. **Response Time:** Mark attendance should complete within 2 seconds
2. **UI Freezing:** No freezing during validation
3. **Network Efficiency:** Single query for duplicate check
4. **Error Display:** Errors appear within 500ms

---

## Accessibility Testing

- [ ] Error messages readable by screen readers
- [ ] Warning banner has proper contrast
- [ ] All buttons have tooltips
- [ ] Keyboard navigation works
- [ ] Touch targets are adequate size (mobile)
