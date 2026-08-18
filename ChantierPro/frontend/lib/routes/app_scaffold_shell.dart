import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../core/app_state.dart';
import '../core/app_strings.dart';

class AppScaffoldShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppScaffoldShell({required this.navigationShell, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = AppState();
    final lang = appState.locale.languageCode;
    String s(String k) => AppStrings.get(k, lang);

    final tabs = [
      {
        'label': s('dashboard'),
        'icon': Icons.dashboard_outlined,
        'selectedIcon': Icons.dashboard_rounded,
      },
      {
        'label': s('chantiers'),
        'icon': Icons.construction_outlined,
        'selectedIcon': Icons.construction_rounded,
      },
      {
        'label': s('tasks'),
        'icon': Icons.task_outlined,
        'selectedIcon': Icons.task_rounded,
      },
      {
        'label': s('reports'),
        'icon': Icons.description_outlined,
        'selectedIcon': Icons.description_rounded,
      },
      {
        'label': s('profile'),
        'icon': Icons.person_outline_rounded,
        'selectedIcon': Icons.person_rounded,
      },
    ];

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(15),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) {
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
          backgroundColor: theme.colorScheme.surface,
          indicatorColor: AppTheme.primaryContainer,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          destinations: tabs.asMap().entries.map((entry) {
            final i = entry.key;
            final tab = entry.value;
            final isSelected = navigationShell.currentIndex == i;
            return NavigationDestination(
              icon: Icon(tab['icon'] as IconData),
              selectedIcon: Icon(tab['selectedIcon'] as IconData),
              label: tab['label'] as String,
            );
          }).toList(),
        ),
      ),
    );
  }
}
