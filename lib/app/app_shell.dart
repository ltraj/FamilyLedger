import 'package:family_ledger/app/app_tab_controller.dart';
import 'package:family_ledger/features/dashboard/screens/dashboard_screen.dart';
import 'package:family_ledger/features/people/screens/people_screen.dart';
import 'package:family_ledger/features/reports/screens/reports_screen.dart';
import 'package:family_ledger/features/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Root shell hosting the app's top-level tabs behind a Material 3 bottom
/// navigation bar.
///
/// Each tab is kept alive in an [IndexedStack] rather than rebuilt on
/// every switch, so, for example, an in-progress search on the People tab
/// survives a trip to Settings and back.
class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  static const _tabs = [
    DashboardScreen(),
    PeopleScreen(),
    ReportsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = ref.watch(appTabProvider);

    return Scaffold(
      body: IndexedStack(index: selectedTab.index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedTab.index,
        onDestinationSelected: (index) =>
            ref.read(appTabProvider.notifier).select(AppTab.values[index]),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'People',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
