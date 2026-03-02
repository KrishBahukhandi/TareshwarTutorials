import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/auth_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../services/supabase_client.dart';

class StudentLayout extends ConsumerWidget {
  const StudentLayout({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  final Widget child;
  final String currentRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;

        if (isMobile) {
          // Mobile layout with drawer
          return Scaffold(
            appBar: AppBar(
              title: const Text('Tareshwar Tutorials Student'),
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            drawer: Drawer(
              child: _SidebarContent(
                currentRoute: currentRoute,
                isMobile: true,
              ),
            ),
            body: SafeArea(child: child),
          );
        }

        // Desktop layout with persistent sidebar
        return Scaffold(
          body: Row(
            children: [
              _SidebarContent(
                currentRoute: currentRoute,
                isMobile: false,
              ),
              Expanded(
                child: Column(
                  children: [
                    _StudentAppBar(),
                    Expanded(child: child),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StudentAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppTheme.gray200),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // User info
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
                child: Icon(
                  Icons.person,
                  color: AppTheme.primaryBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.email?.split('@').first ?? 'Student',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.gray900,
                    ),
                  ),
                  Text(
                    'Student',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.gray500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SidebarContent extends ConsumerWidget {
  const _SidebarContent({
    required this.currentRoute,
    required this.isMobile,
  });

  final String currentRoute;
  final bool isMobile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: isMobile ? null : 260,
      color: AppTheme.primaryBlue,
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(isMobile ? 20 : 24),
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.school,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Tareshwar Tutorials',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Student Portal',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          
          Divider(color: Colors.white.withValues(alpha: 0.2), height: 1),
          
          // Navigation items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _NavItem(
                  icon: Icons.dashboard,
                  label: 'Dashboard',
                  route: '/student',
                  currentRoute: currentRoute,
                  isMobile: isMobile,
                ),
                _NavItem(
                  icon: Icons.book,
                  label: 'My Courses',
                  route: '/student/my-courses',
                  currentRoute: currentRoute,
                  isMobile: isMobile,
                ),
                _NavItem(
                  icon: Icons.explore,
                  label: 'Browse Courses',
                  route: '/student/courses',
                  currentRoute: currentRoute,
                  isMobile: isMobile,
                ),
                _NavItem(
                  icon: Icons.play_circle,
                  label: 'Videos',
                  route: '/student/videos',
                  currentRoute: currentRoute,
                  isMobile: isMobile,
                ),
                _NavItem(
                  icon: Icons.description,
                  label: 'Notes',
                  route: '/student/notes',
                  currentRoute: currentRoute,
                  isMobile: isMobile,
                ),
              ],
            ),
          ),

          // Logout button at bottom
          Divider(color: Colors.white.withValues(alpha: 0.2), height: 1),
          InkWell(
            onTap: () {
              ref.read(authControllerProvider.notifier).signOut();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.logout,
                    color: Colors.white.withValues(alpha: 0.9),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: isMobile ? 8 : 16),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.currentRoute,
    required this.isMobile,
  });

  final IconData icon;
  final String label;
  final String route;
  final String currentRoute;
  final bool isMobile;

  bool get isActive => currentRoute == route || currentRoute.startsWith('$route/');

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: InkWell(
        onTap: () {
          context.go(route);
          if (isMobile) {
            Navigator.of(context).pop(); // Close drawer on mobile
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: isActive
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isActive
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.7),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: isActive
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.7),
                  fontSize: 15,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
