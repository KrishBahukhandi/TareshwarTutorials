import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/auth_controller.dart';
import '../../core/theme/app_theme.dart';

/// Professional teacher layout with responsive sidebar/drawer navigation
class TeacherLayout extends StatelessWidget {
  const TeacherLayout({
    super.key,
    required this.currentRoute,
    required this.child,
  });

  final String currentRoute;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Mobile layout (width < 800)
        if (constraints.maxWidth < 800) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                'Tareshwar Tutorials Teacher',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.gray900,
                ),
              ),
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: IconThemeData(color: AppTheme.gray900),
              actions: [
                Consumer(
                  builder: (context, ref, _) {
                    return IconButton(
                      icon: const Icon(Icons.logout),
                      tooltip: 'Logout',
                      onPressed: () async {
                        await ref.read(authControllerProvider.notifier).signOut();
                        if (context.mounted) {
                          context.go('/login');
                        }
                      },
                    );
                  },
                ),
              ],
            ),
            drawer: Drawer(
              child: _SidebarContent(currentRoute: currentRoute, isMobile: true),
            ),
            body: SafeArea(child: child),
          );
        }

        // Desktop layout (width >= 800)
        return Scaffold(
          body: Row(
            children: [
              // Sidebar
              _SidebarContent(currentRoute: currentRoute, isMobile: false),
              // Main content area
              Expanded(
                child: Column(
                  children: [
                    _TeacherAppBar(),
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

class _SidebarContent extends StatelessWidget {
  const _SidebarContent({
    required this.currentRoute,
    required this.isMobile,
  });

  final String currentRoute;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isMobile ? null : 260,
      decoration: BoxDecoration(
        color: Colors.white,
        border: isMobile
            ? null
            : Border(
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
                    color: AppTheme.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.school_rounded,
                    color: AppTheme.success,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tareshwar Tutorials',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.gray900,
                      ),
                    ),
                    Text(
                      'Teacher Portal',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.gray500,
                      ),
                    ),
                  ],
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
                  route: '/teacher',
                  isActive: currentRoute == '/teacher',
                  isMobile: isMobile,
                ),
                const SizedBox(height: 20),
                _NavSection(title: 'TEACHING'),
                const SizedBox(height: 4),
                _NavItem(
                  icon: Icons.class_outlined,
                  activeIcon: Icons.class_rounded,
                  label: 'My Batches',
                  route: '/teacher/courses',
                  isActive: currentRoute.startsWith('/teacher/courses') ||
                      currentRoute.startsWith('/teacher/batches'),
                  isMobile: isMobile,
                ),
                const SizedBox(height: 20),
                _NavSection(title: 'CONTENT'),
                const SizedBox(height: 4),
                _NavItem(
                  icon: Icons.video_library_outlined,
                  activeIcon: Icons.video_library_rounded,
                  label: 'Upload Video',
                  route: '/teacher/videos/upload',
                  isActive: currentRoute == '/teacher/videos/upload',
                  isMobile: isMobile,
                ),
                _NavItem(
                  icon: Icons.note_outlined,
                  activeIcon: Icons.note_rounded,
                  label: 'Upload Notes',
                  route: '/teacher/notes/upload',
                  isActive: currentRoute == '/teacher/notes/upload',
                  isMobile: isMobile,
                ),
                _NavItem(
                  icon: Icons.folder_outlined,
                  activeIcon: Icons.folder_rounded,
                  label: 'My Content',
                  route: '/teacher/content',
                  isActive: currentRoute.startsWith('/teacher/content'),
                  isMobile: isMobile,
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
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
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
    this.isMobile = false,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
  final bool isActive;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          context.go(route);
          if (isMobile) {
            Navigator.of(context).pop(); // Close drawer on mobile
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? AppTheme.success.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                isActive ? activeIcon : icon,
                size: 20,
                color: isActive ? AppTheme.success : AppTheme.gray600,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive ? AppTheme.success : AppTheme.gray700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeacherAppBar extends ConsumerWidget {
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Logout button
            TextButton.icon(
              onPressed: () async {
                await ref.read(authControllerProvider.notifier).signOut();
                if (context.mounted) {
                  context.go('/login');
                }
              },
              icon: Icon(Icons.logout, size: 18, color: AppTheme.gray700),
              label: Text(
                'Logout',
                style: TextStyle(
                  color: AppTheme.gray700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
