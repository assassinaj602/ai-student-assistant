import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
// Removed unused dashboard-related imports
import 'timetable_screen.dart';
import 'notes_screen.dart';
import 'chat_screen.dart';
import 'flashcards_screen.dart';
import 'diagnostics_screen.dart';
import 'profile_screen.dart';
import 'stunning_dashboard.dart';

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
      StunningDashboard(onNavigateToTab: _onItemTapped),
      const TimetableScreen(),
      const NotesScreen(),
      const ChatScreen(),
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
    return PopScope(
      canPop: false, // Prevent back button from closing app
      onPopInvoked: (bool didPop) {
        if (didPop) return;

        // If not on dashboard (index 0), go back to dashboard
        if (_selectedIndex != 0) {
          setState(() => _selectedIndex = 0);
        }
        // If on dashboard, do nothing (keep app open)
      },
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 48,
          titleSpacing: 8,
          title: const Text(
            'AI Student Assistant',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
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
          backgroundColor: const Color(0xFF1A1625),
          selectedItemColor: const Color(0xFFA78BFA),
          unselectedItemColor: const Color(0xFFD1D5DB),
          items: [
            BottomNavigationBarItem(
              icon: Icon(
                Icons.dashboard_rounded,
                color:
                    _selectedIndex == 0
                        ? const Color(0xFFA78BFA)
                        : const Color(0xFFD1D5DB),
              ),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.calendar_today_rounded,
                color:
                    _selectedIndex == 1
                        ? const Color(0xFFA78BFA)
                        : const Color(0xFFD1D5DB),
              ),
              label: 'Timetable',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.note_alt_rounded,
                color:
                    _selectedIndex == 2
                        ? const Color(0xFFA78BFA)
                        : const Color(0xFFD1D5DB),
              ),
              label: 'Notes',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.smart_toy_rounded,
                color:
                    _selectedIndex == 3
                        ? const Color(0xFFA78BFA)
                        : const Color(0xFFD1D5DB),
              ),
              label: 'AI Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.style_rounded,
                color:
                    _selectedIndex == 4
                        ? const Color(0xFFA78BFA)
                        : const Color(0xFFD1D5DB),
              ),
              label: 'Flashcards',
            ),
          ],
        ),
      ),
    );
  }
}
