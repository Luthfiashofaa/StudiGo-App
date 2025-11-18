import 'package:flutter/material.dart';
import '../../views/home/home_view.dart';
import '../../views/schedule/schedule_view.dart';
import '../../views/streak/streak_view.dart';
import '../../views/profile/profile_view.dart';

class AppShell extends StatefulWidget {
  final int initialIndex;
  const AppShell({super.key, this.initialIndex = 0});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeView(),
    ScheduleView(),
    StreakView(),
    ProfileView(),
  ];

  void _onTap(int idx) => setState(() => _currentIndex = idx);

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF2D7DF6);

    return Scaffold(
      body: SafeArea(child: _pages[_currentIndex]),
      bottomNavigationBar: Container(
        height: 86,
        decoration: const BoxDecoration(
          color: primaryBlue,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  onPressed: () => _onTap(0),
                  icon: Icon(
                    Icons.home,
                    color: _currentIndex == 0 ? Colors.white : Colors.white70,
                    size: 28,
                  ),
                ),
                IconButton(
                  onPressed: () => _onTap(1),
                  icon: Icon(
                    Icons.event,
                    color: _currentIndex == 1 ? Colors.white : Colors.white70,
                    size: 28,
                  ),
                ),
                IconButton(
                  onPressed: () => _onTap(2),
                  icon: Icon(
                    Icons.track_changes,
                    color: _currentIndex == 2 ? Colors.white : Colors.white70,
                    size: 28,
                  ),
                ),
                IconButton(
                  onPressed: () => _onTap(3),
                  icon: Icon(
                    Icons.person,
                    color: _currentIndex == 3 ? Colors.white : Colors.white70,
                    size: 28,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: 120,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// _Placeholder removed — replaced by real pages (ScheduleView etc.)