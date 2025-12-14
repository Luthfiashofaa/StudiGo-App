import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/home/home_controller.dart';

class AdminView extends GetView<HomeController> {
  const AdminView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        elevation: 0,
        backgroundColor: Colors.blue,
      ),
      body: Stack(
        children: [
          // Background blur effects (same as HomeView)
          Positioned(
            top: 180,
            left: -70,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.blue.withOpacity(0.11),
                    Colors.blue.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 150,
            right: -90,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.purple.withOpacity(0.1),
                    Colors.purple.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selamat datang Admin',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  // Admin Stats Cards
                  _StatCard(
                    title: 'Total Users',
                    value: '1,234',
                    icon: Icons.people,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  _StatCard(
                    title: 'Active Tasks',
                    value: '567',
                    icon: Icons.assignment,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 12),
                  _StatCard(
                    title: 'Pending Reports',
                    value: '42',
                    icon: Icons.warning,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 24),

                  // Admin Actions
                  const Text(
                    'Admin Actions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _AdminActionButton(
                    label: 'Manage Users',
                    icon: Icons.person_add,
                    onTap: () {
                      Get.snackbar('Info', 'User management - Coming soon');
                    },
                  ),
                  const SizedBox(height: 10),
                  _AdminActionButton(
                    label: 'View Reports',
                    icon: Icons.analytics,
                    onTap: () {
                      Get.snackbar('Info', 'Reports - Coming soon');
                    },
                  ),
                  const SizedBox(height: 10),
                  _AdminActionButton(
                    label: 'System Settings',
                    icon: Icons.settings,
                    onTap: () {
                      Get.snackbar('Info', 'Settings - Coming soon');
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _AdminActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
