import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/auth_controller.dart';
import '../../core/theme/app_theme.dart';

/// Modern, clean admin layout with professional sidebar navigation
/// Responsive: Desktop uses sidebar, Mobile uses drawer
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final theme = Theme.of(context);
        final cs = theme.colorScheme;

        // Mobile layout (width < 800)
        if (constraints.maxWidth < 800) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                'Admin',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              backgroundColor: cs.surface,
              foregroundColor: cs.onSurface,
              elevation: 0,
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
          backgroundColor: cs.surface,
          body: Row(
            children: [
              _SidebarContent(currentRoute: currentRoute, isMobile: false),
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      width: isMobile ? null : 260,
      decoration: BoxDecoration(
        color: cs.surface,
        border: isMobile
            ? null
            : Border(
                right: BorderSide(color: cs.outlineVariant, width: 1),
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
                    color: cs.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.school_rounded,
                    color: cs.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tareshwar Tutorials',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: cs.outlineVariant),

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
                  isMobile: isMobile,
                ),
                const SizedBox(height: 4),
                _NavItem(
                  icon: Icons.analytics_outlined,
                  activeIcon: Icons.analytics_rounded,
                  label: 'Analytics',
                  route: '/admin/analytics',
                  isActive: currentRoute.startsWith('/admin/analytics'),
                  isMobile: isMobile,
                ),
                const SizedBox(height: 20),
                _NavSection(title: 'USER MANAGEMENT'),
                const SizedBox(height: 4),
                _NavItem(
                  icon: Icons.people_outline,
                  activeIcon: Icons.people_rounded,
                  label: 'Students',
                  route: '/admin/students',
                  isActive: currentRoute.startsWith('/admin/students'),
                  isMobile: isMobile,
                ),
                _NavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person_rounded,
                  label: 'Teachers',
                  route: '/admin/teachers',
                  isActive: currentRoute.startsWith('/admin/teachers'),
                  isMobile: isMobile,
                ),
                const SizedBox(height: 20),
                _NavSection(title: 'CONTENT'),
                const SizedBox(height: 4),
                _NavItem(
                  icon: Icons.book_outlined,
                  activeIcon: Icons.book_rounded,
                  label: 'Courses',
                  route: '/admin/courses',
                  isActive: currentRoute.startsWith('/admin/courses'),
                  isMobile: isMobile,
                ),
                _NavItem(
                  icon: Icons.class_outlined,
                  activeIcon: Icons.class_rounded,
                  label: 'Batches',
                  route: '/admin/batches',
                  isActive: currentRoute.startsWith('/admin/batches'),
                  isMobile: isMobile,
                ),
                const SizedBox(height: 20),
                _NavSection(title: 'OPERATIONS'),
                const SizedBox(height: 4),
                _NavItem(
                  icon: Icons.assignment_outlined,
                  activeIcon: Icons.assignment_rounded,
                  label: 'Enrollments',
                  route: '/admin/enrollments',
                  isActive: currentRoute.startsWith('/admin/enrollments'),
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Text(
        title,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: cs.onSurfaceVariant,
          letterSpacing: 0.8,
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final activeColor = cs.primary;
    final inactiveColor = cs.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          context.go(route);
          if (isMobile) {
            Navigator.of(context).pop();
          }
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? activeColor.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                isActive ? activeIcon : icon,
                size: 20,
                color: isActive ? activeColor : inactiveColor,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                  color: isActive ? activeColor : cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminAppBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant, width: 1),
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
              icon: Icon(Icons.logout, size: 18, color: cs.onSurfaceVariant),
              label: Text(
                'Logout',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
