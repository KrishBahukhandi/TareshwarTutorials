import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/auth_controller.dart';
import '../../core/theme/app_theme.dart';

/// Modern, clean admin layout with professional sidebar navigation
class AdminLayout extends StatelessWidget {
  const AdminLayout({
    super.key,
    required this.currentRoute,
    required this.child,
  });

  final String currentRoute;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          _AdminSidebar(currentRoute: currentRoute),
          // Main content area
          Expanded(
            child: Column(
              children: [
                _AdminAppBar(),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminSidebar extends StatelessWidget {
  const _AdminSidebar({required this.currentRoute});

  final String currentRoute;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: AppTheme.gray200, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Logo/Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.school_rounded,
                    color: AppTheme.primaryBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'EduTech',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.gray900,
                  ),
                ),
              ],
            ),
          ),
          
          Divider(height: 1, color: AppTheme.gray200),
          
          // Navigation items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _NavItem(
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  route: '/admin',
                  isActive: currentRoute == '/admin',
                ),
                const SizedBox(height: 24),
                _NavSection(title: 'USER MANAGEMENT'),
                const SizedBox(height: 8),
                _NavItem(
                  icon: Icons.people_outline,
                  activeIcon: Icons.people_rounded,
                  label: 'Students',
                  route: '/admin/students',
                  isActive: currentRoute.startsWith('/admin/students'),
                ),
                _NavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person_rounded,
                  label: 'Teachers',
                  route: '/admin/teachers',
                  isActive: currentRoute.startsWith('/admin/teachers'),
                ),
                const SizedBox(height: 24),
                _NavSection(title: 'CONTENT'),
                const SizedBox(height: 8),
                _NavItem(
                  icon: Icons.book_outlined,
                  activeIcon: Icons.book_rounded,
                  label: 'Courses',
                  route: '/admin/courses',
                  isActive: currentRoute.startsWith('/admin/courses'),
                ),
                _NavItem(
                  icon: Icons.class_outlined,
                  activeIcon: Icons.class_rounded,
                  label: 'Batches',
                  route: '/admin/batches',
                  isActive: currentRoute.startsWith('/admin/batches'),
                ),
                const SizedBox(height: 24),
                _NavSection(title: 'OPERATIONS'),
                const SizedBox(height: 8),
                _NavItem(
                  icon: Icons.assignment_outlined,
                  activeIcon: Icons.assignment_rounded,
                  label: 'Enrollments',
                  route: '/admin/enrollments',
                  isActive: currentRoute.startsWith('/admin/enrollments'),
                ),
                _NavItem(
                  icon: Icons.video_library_outlined,
                  activeIcon: Icons.video_library_rounded,
                  label: 'Content Library',
                  route: '/admin/content',
                  isActive: currentRoute.startsWith('/admin/content'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavSection extends StatelessWidget {
  const _NavSection({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppTheme.gray500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
    required this.isActive,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isActive ? AppTheme.primaryBlue.withOpacity(0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go(route),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: isActive ? AppTheme.primaryBlue : Colors.transparent,
                  width: 3,
                ),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  size: 20,
                  color: isActive ? AppTheme.primaryBlue : AppTheme.gray600,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive ? AppTheme.primaryBlue : AppTheme.gray700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminAppBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppTheme.gray200, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Search bar (placeholder)
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: Icon(Icons.search, size: 20, color: AppTheme.gray400),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  filled: true,
                  fillColor: AppTheme.gray50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.primaryBlue, width: 1),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Notifications
          IconButton(
            icon: Icon(Icons.notifications_outlined, size: 22),
            onPressed: () {},
            tooltip: 'Notifications',
            color: AppTheme.gray600,
          ),
          
          const SizedBox(width: 8),
          
          // Profile
          IconButton(
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.gray200,
              child: Icon(Icons.person, size: 18, color: AppTheme.gray600),
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Account'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.person),
                        title: const Text('Profile'),
                        onTap: () => Navigator.pop(dialogContext),
                      ),
                      ListTile(
                        leading: const Icon(Icons.settings),
                        title: const Text('Settings'),
                        onTap: () => Navigator.pop(dialogContext),
                      ),
                      const Divider(),
                      ListTile(
                        leading: Icon(Icons.logout, color: AppTheme.error),
                        title: Text('Logout', style: TextStyle(color: AppTheme.error)),
                        onTap: () async {
                          Navigator.pop(dialogContext);
                          // Call the signOut method
                          await ref.read(authControllerProvider.notifier).signOut();
                          // Navigate to login
                          if (context.mounted) {
                            context.go('/login');
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
            tooltip: 'Account',
          ),
        ],
      ),
    );
  }
}
