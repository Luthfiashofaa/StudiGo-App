import 'package:flutter/material.dart';
import '../../views/home/home_view.dart';
import '../../views/streak/streak_view.dart';
import '../../views/profile/profile_view.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeView(),
    _Placeholder(title: 'Calendar'),
    StreakView(),
    ProfileView(),
  ];

  void _onTap(int idx) => setState(() => _currentIndex = idx);

  Widget _buildNavIcon({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    const activeBoxColor = Color(0xFF6097FF); // #6097FF untuk kotak aktif
    return Container(
      width: 52,
      height: 52,
      decoration: isActive
          ? BoxDecoration(
              color: activeBoxColor,
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      alignment: Alignment.center,
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 52, height: 52),
        onPressed: onTap,
        icon: Icon(
          icon,
          color: isActive ? Colors.white : Colors.white70,
          size: 24,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF1557D4);

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
                _buildNavIcon(
                  icon: Icons.home,
                  isActive: _currentIndex == 0,
                  onTap: () => _onTap(0),
                ),
                _buildNavIcon(
                  icon: Icons.event,
                  isActive: _currentIndex == 1,
                  onTap: () => _onTap(1),
                ),
                _buildNavIcon(
                  icon: Icons.track_changes,
                  isActive: _currentIndex == 2,
                  onTap: () => _onTap(2),
                ),
                _buildNavIcon(
                  icon: Icons.person,
                  isActive: _currentIndex == 3,
                  onTap: () => _onTap(3),
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

class _Placeholder extends StatelessWidget {
  final String title;
  const _Placeholder({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(title, style: const TextStyle(fontSize: 20)));
  }
}
