import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/timetable_provider.dart';
import '../models/course.dart';
import 'class_detail_screen.dart';

/// Advanced Timetable screen with calendar and schedule views
class TimetableScreen extends ConsumerStatefulWidget {
  const TimetableScreen({super.key});

  @override
  ConsumerState<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends ConsumerState<TimetableScreen>
    with TickerProviderStateMixin {
  late TabController _mainTabController;
  late TabController _scheduleTabController;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.week;

  @override
  void initState() {
    super.initState();
    try {
      _mainTabController = TabController(length: 2, vsync: this);
      _scheduleTabController = TabController(length: 7, vsync: this);
    } catch (e) {
      debugPrint('Error initializing TabControllers: $e');
      // Fallback initialization
      _mainTabController = TabController(length: 2, vsync: this);
      _scheduleTabController = TabController(length: 7, vsync: this);
    }
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    _scheduleTabController.dispose();
    super.dispose();
  }

  String _getDayName(DateTime date) {
    return DateFormat('EEEE').format(date).toLowerCase();
  }

  /// Navigate to add/edit course screen
  void _navigateToAddCourse([Course? course]) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;

    if (isWideScreen) {
      // On web/tablets, use dialog
      showDialog(
        context: context,
        builder:
            (context) => Dialog(
              child: Container(
                width: 400,
                constraints: const BoxConstraints(maxHeight: 600),
                child: _AddCourseSheet(course: course),
              ),
            ),
      );
    } else {
      // On mobile, use bottom sheet
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => _AddCourseSheet(course: course),
      );
    }
  }

  /// Navigate to course detail screen
  void _navigateToCourseDetail(Course course) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ClassDetailScreen(course: course),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final courses = ref.watch(coursesProvider);

    return Column(
      children: [
        // Custom header with tabs and actions
        Container(
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            children: [
              // Action buttons row
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Timetable',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.today),
                          onPressed: () {
                            setState(() {
                              _selectedDay = DateTime.now();
                              _focusedDay = DateTime.now();
                            });
                          },
                          tooltip: 'Go to Today',
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () => _navigateToAddCourse(),
                          tooltip: 'Add Course',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Tab bar
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: TabBar(
                  controller: _mainTabController,
                  labelColor: Theme.of(context).colorScheme.primary,
                  unselectedLabelColor: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                  indicatorColor: Theme.of(context).colorScheme.primary,
                  indicatorWeight: 3.0,
                  tabs: const [
                    Tab(icon: Icon(Icons.calendar_month), text: 'Calendar'),
                    Tab(icon: Icon(Icons.view_agenda), text: 'Schedule'),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Main content area
        Expanded(
          child: courses.when(
            data:
                (courseList) => TabBarView(
                  controller: _mainTabController,
                  children: [
                    _buildCalendarView(courseList),
                    _buildScheduleView(courseList),
                  ],
                ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error:
                (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading timetable',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.refresh(coursesProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
          ),
        ),
      ],
    );
  }

  /// Build calendar view with course events and course list
  Widget _buildCalendarView(List<Course> courses) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            // Calendar section - smaller
            Container(
              constraints: BoxConstraints(
                maxHeight:
                    constraints.maxHeight * 0.35, // Reduced from 0.6 to 0.35
              ),
              child: TableCalendar<Course>(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                eventLoader: (day) => _getEventsForDay(day, courses),
                startingDayOfWeek: StartingDayOfWeek.monday,
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  weekendTextStyle: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                  holidayTextStyle: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiary,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: true,
                  titleCentered: true,
                  formatButtonShowsNext: false,
                  formatButtonDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  formatButtonTextStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 12.0,
                  ),
                ),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
              ),
            ),
            const SizedBox(height: 8.0),
            Expanded(child: _buildSelectedDayEvents(courses)),
          ],
        );
      },
    );
  }

  /// Build schedule view showing daily timetable
  Widget _buildScheduleView(List<Course> courses) {
    return Column(
      children: [
        Container(
          color: Theme.of(context).colorScheme.surface,
          height: MediaQuery.of(context).size.width > 600 ? 80 : 70,
          child: TabBar(
            controller: _scheduleTabController,
            isScrollable: true,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(
              context,
            ).colorScheme.onSurface.withOpacity(0.6),
            indicatorColor: Theme.of(context).colorScheme.primary,
            indicatorWeight: 2.0,
            labelPadding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width > 600 ? 12 : 8,
            ),
            tabs: _buildWeekTabs(),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _scheduleTabController,
            children: _buildWeekTabViews(courses),
          ),
        ),
      ],
    );
  }

  /// Get events for a specific day
  List<Course> _getEventsForDay(DateTime day, List<Course> courses) {
    final dayName = _getDayName(day);
    return courses.where((course) => course.days.contains(dayName)).toList();
  }

  /// Build selected day events and all courses list with enhanced layout
  Widget _buildSelectedDayEvents(List<Course> courses) {
    final events = _getEventsForDay(_selectedDay, courses);
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');

    return Column(
      children: [
        // Date header - more compact
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primaryContainer,
                Theme.of(context).colorScheme.secondaryContainer,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateFormat.format(_selectedDay),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      events.isEmpty
                          ? 'No classes today'
                          : '${events.length} class${events.length == 1 ? '' : 'es'} scheduled',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onPrimaryContainer.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // All Courses Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.school,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'All Courses',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const Spacer(),
              Text(
                '${courses.length} courses',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),

        // Courses List - Enhanced with attendance
        Expanded(
          child:
              courses.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_circle_outline,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No courses added yet',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the + button to add your first course',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                  : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: courses.length,
                    itemBuilder: (context, index) {
                      return _buildEnhancedCourseCardWithAttendance(
                        courses[index],
                        events.contains(courses[index]),
                      );
                    },
                  ),
        ),
      ],
    );
  }

  /// Build week tabs for schedule view
  List<Widget> _buildWeekTabs() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    return List.generate(7, (index) {
      final date = startOfWeek.add(Duration(days: index));
      final dayName = DateFormat('E').format(date);
      final dayNumber = date.day;
      final isToday = isSameDay(date, DateTime.now());

      return Tab(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 50, maxWidth: 70),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                dayName,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color:
                      isToday
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    dayNumber.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color:
                          isToday
                              ? Theme.of(context).colorScheme.onPrimary
                              : null,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  /// Build week tab views for schedule
  List<Widget> _buildWeekTabViews(List<Course> courses) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    return List.generate(7, (index) {
      final date = startOfWeek.add(Duration(days: index));
      final dayEvents = _getEventsForDay(date, courses);

      return _buildDaySchedule(date, dayEvents);
    });
  }

  /// Build day schedule view
  Widget _buildDaySchedule(DateTime date, List<Course> courses) {
    final dateFormat = DateFormat('EEEE, MMM d');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.primaryContainer.withOpacity(0.3),
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
          ),
          child: Text(
            dateFormat.format(date),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          child:
              courses.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_available,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No classes today',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          'Enjoy your free day!',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  )
                  : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: courses.length,
                    itemBuilder: (context, index) {
                      return _buildEnhancedCourseCard(courses[index]);
                    },
                  ),
        ),
      ],
    );
  }

  /// Build enhanced course card with better design
  Widget _buildEnhancedCourseCard(Course course) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToCourseDetail(course),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.book,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course.name,
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      itemBuilder:
                          (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: ListTile(
                                leading: Icon(Icons.edit),
                                title: Text('Edit'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: ListTile(
                                leading: Icon(Icons.delete),
                                title: Text('Delete'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            _navigateToAddCourse(course);
                            break;
                          case 'delete':
                            _deleteCourse(course);
                            break;
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            course.times.isNotEmpty
                                ? course.times
                                : 'No time set',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            course.location.isNotEmpty
                                ? course.location
                                : 'No location',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build enhanced course card with attendance functionality
  Widget _buildEnhancedCourseCardWithAttendance(
    Course course,
    bool isScheduledToday,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.surface,
            isScheduledToday
                ? Theme.of(
                  context,
                ).colorScheme.primaryContainer.withOpacity(0.5)
                : Theme.of(
                  context,
                ).colorScheme.primaryContainer.withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isScheduledToday
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
                  : Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: isScheduledToday ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToCourseDetail(course),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Course header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.school,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  course.name,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              if (isScheduledToday)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Today',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelSmall?.copyWith(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSecondary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            course.location.isNotEmpty
                                ? course.location
                                : 'No location set',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Course details
                Row(
                  children: [
                    Expanded(
                      child: _buildCourseDetailItem(
                        Icons.access_time,
                        course.times.isNotEmpty ? course.times : 'No time set',
                        context,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildCourseDetailItem(
                        Icons.location_on,
                        course.location.isNotEmpty
                            ? course.location
                            : 'No location',
                        context,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Days and actions
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 4,
                        children:
                            course.days
                                .map(
                                  (day) => Chip(
                                    label: Text(
                                      day.toUpperCase(),
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                    backgroundColor:
                                        Theme.of(
                                          context,
                                        ).colorScheme.secondaryContainer,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                )
                                .toList(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Action buttons
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, size: 20),
                          onPressed: () => _navigateToAddCourse(course),
                          tooltip: 'Edit Course',
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete,
                            size: 20,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          onPressed: () => _deleteCourse(course),
                          tooltip: 'Delete Course',
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCourseDetailItem(
    IconData icon,
    String text,
    BuildContext context,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Delete course with confirmation
  Future<void> _deleteCourse(Course course) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Course'),
            content: Text('Are you sure you want to delete "${course.name}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await ref.read(timetableProvider.notifier).deleteCourse(course.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Course deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting course: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }
}

/// Add Course Modal Sheet
class _AddCourseSheet extends ConsumerStatefulWidget {
  final Course? course;

  const _AddCourseSheet({this.course});

  @override
  ConsumerState<_AddCourseSheet> createState() => _AddCourseSheetState();
}

class _AddCourseSheetState extends ConsumerState<_AddCourseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final List<String> _selectedDays = [];

  final List<String> _daysOfWeek = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.course != null) {
      final course = widget.course!;
      _nameController.text = course.name;
      _locationController.text = course.location;
      _selectedDays.addAll(course.days);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _saveCourse() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one day')),
      );
      return;
    }

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      final course = Course(
        id: widget.course?.id ?? '',
        userId: widget.course?.userId ?? currentUser.uid,
        name: _nameController.text.trim(),
        location: _locationController.text.trim(),
        days: _selectedDays,
        times: 'TBD',
        createdAt: widget.course?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.course == null) {
        await ref.read(timetableProvider.notifier).addCourse(course);
      } else {
        await ref.read(timetableProvider.notifier).updateCourse(course);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.course == null
                  ? 'Course added successfully!'
                  : 'Course updated successfully!',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.course == null ? 'Add New Course' : 'Edit Course',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Course Name *',
                  hintText: 'e.g. Mathematics, Biology',
                  border: OutlineInputBorder(),
                ),
                validator:
                    (value) =>
                        value?.trim().isEmpty == true
                            ? 'Course name is required'
                            : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  hintText: 'e.g. Room 101, Online',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              const SizedBox(height: 4),

              Text(
                'Days of Week *',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              Wrap(
                spacing: 8,
                children:
                    _daysOfWeek.map((day) {
                      final isSelected = _selectedDays.contains(day);
                      return FilterChip(
                        label: Text(day.substring(0, 3).toUpperCase()),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedDays.add(day);
                            } else {
                              _selectedDays.remove(day);
                            }
                          });
                        },
                      );
                    }).toList(),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveCourse,
                      child: Text(
                        widget.course == null ? 'Add Course' : 'Update Course',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
