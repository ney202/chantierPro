import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/api/auth_session.dart';
import '../presentation/admin_affectations_screen/admin_affectations_screen.dart';
import '../presentation/admin_chefs_screen/admin_chefs_screen.dart';
import '../presentation/admin_consultation_screen/admin_consultation_screen.dart';
import '../presentation/admin_dashboard_screen/admin_dashboard_screen.dart';
import '../presentation/chantier_detail_screen/chantier_detail_screen.dart';
import '../presentation/chantiers_list_screen/chantiers_list_screen.dart';
import '../presentation/dashboard_screen/dashboard_screen.dart';
import '../presentation/login_screen/login_screen.dart';
import '../presentation/profile_screen/profile_screen.dart';
import '../presentation/register_screen/register_screen.dart';
import '../presentation/reports_screen/reports_screen.dart';
import '../presentation/tasks_screen/tasks_screen.dart';
import 'admin_app_scaffold_shell.dart';
import 'app_scaffold_shell.dart';

// ── Si ConsultationType est dans un fichier séparé chez toi, décommente : ──
// import '../presentation/admin_consultation_screen/consultation_type.dart';

class AppRoutes {
  static const String initial = '/';
  static const String loginScreen = '/login';
  static const String registerScreen = '/register';

  // Chef
  static const String dashboardScreen = '/dashboard';
  static const String chantiersListScreen = '/chantiers';
  static const String chantierDetailScreen = '/chantiers/detail';
  static const String tasksScreen = '/tasks';
  static const String reportsScreen = '/reports';
  static const String profileScreen = '/profile';

  // Admin shell
  static const String adminDashboard = '/admin';
  static const String adminChantiers = '/admin/chantiers';
  static const String adminTasks = '/admin/tasks';
  static const String adminReports = '/admin/reports';
  static const String adminProfile = '/admin/profile';

  // Admin hors shell
  static const String adminChefs = '/admin/chefs';
  static const String adminAffectations = '/admin/affectations';
  static const String adminAlertes = '/admin/consultation/alertes';
  static const String adminDepenses = '/admin/consultation/depenses';
}

final List<String> _adminRoutes = [
  AppRoutes.adminDashboard,
  AppRoutes.adminChantiers,
  AppRoutes.adminTasks,
  AppRoutes.adminReports,
  AppRoutes.adminProfile,
  AppRoutes.adminChefs,
  AppRoutes.adminAffectations,
  AppRoutes.adminAlertes,
  AppRoutes.adminDepenses,
];

final List<String> _chefRoutes = [
  AppRoutes.dashboardScreen,
  AppRoutes.chantiersListScreen,
  AppRoutes.tasksScreen,
  AppRoutes.reportsScreen,
  AppRoutes.profileScreen,
];

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.initial,
  refreshListenable: AuthSession(),
  redirect: (context, state) {
    final loggedIn = AuthSession().isLoggedIn;
    final user = AuthSession().user;
    final isAdmin = user?.role == 'ADMIN';
    final location = state.uri.path;

    final onAuthPage =
        location == AppRoutes.initial ||
        location == AppRoutes.loginScreen ||
        location == AppRoutes.registerScreen;

    // 1. Non connecté → login
    if (!loggedIn && !onAuthPage) return AppRoutes.loginScreen;

    // 2. Connecté sur page auth → redirige selon rôle
    if (loggedIn && onAuthPage) {
      return isAdmin ? AppRoutes.adminDashboard : AppRoutes.dashboardScreen;
    }

    // 3. Admin sur route chef (ou sous-route) → équivalent admin
    if (loggedIn && isAdmin) {
      for (final chefRoute in _chefRoutes) {
        if (location == chefRoute || location.startsWith('$chefRoute/')) {
          if (chefRoute == AppRoutes.dashboardScreen) {
            return AppRoutes.adminDashboard;
          }
          if (chefRoute == AppRoutes.chantiersListScreen) {
            return AppRoutes.adminChantiers;
          }
          if (chefRoute == AppRoutes.tasksScreen) {
            return AppRoutes.adminTasks;
          }
          if (chefRoute == AppRoutes.reportsScreen) {
            return AppRoutes.adminReports;
          }
          if (chefRoute == AppRoutes.profileScreen) {
            return AppRoutes.adminProfile;
          }
        }
      }
    }

    // 4. Chef sur route admin (ou sous-route) → dashboard chef
    if (loggedIn && !isAdmin) {
      for (final adminRoute in _adminRoutes) {
        if (location == adminRoute || location.startsWith('$adminRoute/')) {
          return AppRoutes.dashboardScreen;
        }
      }
    }

    return null;
  },
  routes: [
    // ── Auth ──
    GoRoute(
      path: AppRoutes.initial,
      pageBuilder: (context, state) => _fadePage(state, const LoginScreen()),
    ),
    GoRoute(
      path: AppRoutes.loginScreen,
      pageBuilder: (context, state) => _slidePage(state, const LoginScreen()),
    ),
    GoRoute(
      path: AppRoutes.registerScreen,
      pageBuilder: (context, state) =>
          _slidePage(state, const RegisterScreen()),
    ),

    // ── Admin hors shell ──
    GoRoute(
      path: AppRoutes.adminChefs,
      pageBuilder: (context, state) =>
          _slidePage(state, const AdminChefsScreen()),
    ),
    GoRoute(
      path: AppRoutes.adminAffectations,
      pageBuilder: (context, state) =>
          _slidePage(state, const AdminAffectationsScreen()),
    ),
    GoRoute(
      path: AppRoutes.adminAlertes,
      pageBuilder: (context, state) => _slidePage(
        state,
        const AdminConsultationScreen(type: ConsultationType.alertes),
      ),
    ),
    GoRoute(
      path: AppRoutes.adminDepenses,
      pageBuilder: (context, state) => _slidePage(
        state,
        const AdminConsultationScreen(type: ConsultationType.depenses),
      ),
    ),

    // ── Shell CHEF ──
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppScaffoldShell(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.dashboardScreen,
              pageBuilder: (context, state) =>
                  _fadePage(state, const DashboardScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.chantiersListScreen,
              pageBuilder: (context, state) =>
                  _fadePage(state, ChantiersListScreen()),
              routes: [
                GoRoute(
                  path: 'detail',
                  pageBuilder: (context, state) {
                    final extra = state.extra;
                    final chantier = extra is Map<String, dynamic>
                        ? extra
                        : <String, dynamic>{};
                    return _slidePage(
                      state,
                      ChantierDetailScreen(chantier: chantier),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.tasksScreen,
              pageBuilder: (context, state) => _fadePage(state, TasksScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.reportsScreen,
              pageBuilder: (context, state) =>
                  _fadePage(state, ReportsScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.profileScreen,
              pageBuilder: (context, state) =>
                  _fadePage(state, const ProfileScreen()),
            ),
          ],
        ),
      ],
    ),

    // ── Shell ADMIN ──
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AdminAppScaffoldShell(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.adminDashboard,
              pageBuilder: (context, state) =>
                  _fadePage(state, const AdminDashboardScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.adminChantiers,
              pageBuilder: (context, state) =>
                  _fadePage(state, ChantiersListScreen()),
              routes: [
                GoRoute(
                  path: 'detail',
                  pageBuilder: (context, state) {
                    final extra = state.extra;
                    final chantier = extra is Map<String, dynamic>
                        ? extra
                        : <String, dynamic>{};
                    return _slidePage(
                      state,
                      ChantierDetailScreen(chantier: chantier),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.adminTasks,
              pageBuilder: (context, state) => _fadePage(state, TasksScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.adminReports,
              pageBuilder: (context, state) =>
                  _fadePage(state, ReportsScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.adminProfile,
              pageBuilder: (context, state) =>
                  _fadePage(state, const ProfileScreen()),
            ),
          ],
        ),
      ],
    ),
  ],
);

CustomTransitionPage<void> _fadePage(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        child: child,
      );
    },
  );
}

CustomTransitionPage<void> _slidePage(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
        child: child,
      );
    },
  );
}
