import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/auth_provider.dart';
import '../providers/notes_provider.dart';
import '../providers/timetable_provider.dart';

import '../services/firebase_service.dart';
import '../models/flashcard_generation.dart';
import 'timetable_screen.dart';
import 'notes_screen.dart';
import 'simple_chat_screen.dart';
import 'flashcards_screen.dart';
import 'diagnostics_screen.dart';
import 'profile_screen.dart';

/// Main home screen with bottom navigation and feature access
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  /// List of screens for bottom navigation
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      _DashboardTab(onNavigateToTab: _onItemTapped),
      const TimetableScreen(),
      const NotesScreen(),
      const SimpleChatScreen(),
      const FlashcardsScreen(),
    ];
  }

  /// Handle bottom navigation tap
  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  /// Handle user logout
  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Sign Out'),
            content: const Text('Are you sure you want to sign out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Sign Out'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await ref.read(authProvider.notifier).signOut();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sign out failed: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Student Assistant'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                  break;
                case 'logout':
                  _handleLogout();
                  break;
                case 'settings':
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const DiagnosticsScreen(),
                    ),
                  );
                  break;
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(Icons.person),
                        SizedBox(width: 8),
                        Text('Profile'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(Icons.developer_board),
                        SizedBox(width: 8),
                        Text('AI Diagnostics'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout),
                        SizedBox(width: 8),
                        Text('Sign Out'),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: 'Timetable',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.note), label: 'Notes'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'AI Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.quiz), label: 'Flashcards'),
        ],
      ),
    );
  }
}

/// Dashboard tab showing overview and quick actions
class _DashboardTab extends ConsumerWidget {
  final Function(int) onNavigateToTab;

  const _DashboardTab({required this.onNavigateToTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome message
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back, ${user?.displayName ?? 'Student'}!',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ready to boost your productivity today?',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Quick actions
              Text(
                'Quick Actions',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _QuickActionCard(
                    icon: Icons.add_circle,
                    title: 'Add Note',
                    subtitle: 'Create a new note',
                    onTap: () => onNavigateToTab(2),
                  ),
                  _QuickActionCard(
                    icon: Icons.schedule_send,
                    title: 'Add Class',
                    subtitle: 'Add to timetable',
                    onTap: () => onNavigateToTab(1),
                  ),
                  _QuickActionCard(
                    icon: Icons.chat_bubble,
                    title: 'Ask AI',
                    subtitle: 'Get instant help',
                    onTap: () => onNavigateToTab(3),
                  ),
                  _QuickActionCard(
                    icon: Icons.quiz,
                    title: 'Study Cards',
                    subtitle: 'Review flashcards',
                    onTap: () => onNavigateToTab(4),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Recent activity
              Text(
                'Recent Activity',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              _RecentActivityWidget(),
            ],
          ),
        );
      },
    );
  }
}

/// Quick action card widget
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 28, color: Theme.of(context).primaryColor),
              const SizedBox(height: 6),
              Flexible(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 2),
              Flexible(
                child: Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Activity item model
class _ActivityItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final DateTime time;

  _ActivityItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
  });
}

/// Widget showing real-time recent activity
class _RecentActivityWidget extends ConsumerWidget {
  const _RecentActivityWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firebase = ref.watch(firebaseServiceProvider);
    final notesAsync = ref.watch(notesStreamProvider);
    final coursesAsync = ref.watch(timetableProvider);

    return StreamBuilder<List<FlashcardGeneration>>(
      stream: firebase.getFlashcardGenerationHistoryStream(),
      builder: (context, flashcardSnapshot) {
        final activities = <_ActivityItem>[];

        // Add flashcard generations to activity
        if (flashcardSnapshot.hasData) {
          for (final generation in flashcardSnapshot.data!.take(3)) {
            activities.add(
              _ActivityItem(
                icon: Icons.quiz,
                title: 'Generated ${generation.flashcardCount} flashcards',
                subtitle:
                    generation.sourceTitle.isNotEmpty
                        ? generation.sourceTitle
                        : 'From text content',
                time: generation.createdAt,
              ),
            );
          }
        }

        // Add notes to activity
        notesAsync.whenData((notes) {
          final sortedNotes = List.from(notes);
          sortedNotes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          for (final note in sortedNotes.take(2)) {
            activities.add(
              _ActivityItem(
                icon: Icons.note,
                title: 'Created note',
                subtitle: note.title.isNotEmpty ? note.title : 'Untitled Note',
                time: note.createdAt,
              ),
            );
          }
        });

        // Add courses to activity
        coursesAsync.whenData((courses) {
          final sortedCourses = List.from(courses);
          sortedCourses.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          for (final course in sortedCourses.take(2)) {
            activities.add(
              _ActivityItem(
                icon: Icons.class_,
                title: 'Added course',
                subtitle: '${course.name} - ${course.location}',
                time: course.createdAt,
              ),
            );
          }
        });

        // Sort by time (most recent first) and take only the most recent 5 items
        activities.sort((a, b) => b.time.compareTo(a.time));
        final recentActivities = activities.take(5).toList();

        if (recentActivities.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(
                    Icons.timeline,
                    size: 48,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No recent activity',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start creating notes, flashcards, or courses to see your activity here',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                for (int i = 0; i < recentActivities.length; i++) ...[
                  _buildActivityTile(context, recentActivities[i]),
                  if (i < recentActivities.length - 1) const Divider(),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActivityTile(BuildContext context, _ActivityItem activity) {
    return ListTile(
      leading: Icon(activity.icon),
      title: Text(activity.title),
      subtitle: Text('${activity.subtitle} • ${_formatTimeAgo(activity.time)}'),
      contentPadding: EdgeInsets.zero,
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hr ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
