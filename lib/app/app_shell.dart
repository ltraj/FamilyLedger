import 'package:family_ledger/app/app_tab_controller.dart';
import 'package:family_ledger/backup/models/auto_backup_outcome.dart';
import 'package:family_ledger/features/backup/providers/backup_file_picker.dart';
import 'package:family_ledger/features/backup/providers/backup_service_providers.dart';
import 'package:family_ledger/features/backup/providers/backup_view_model.dart';
import 'package:family_ledger/features/dashboard/screens/dashboard_screen.dart';
import 'package:family_ledger/features/people/screens/people_screen.dart';
import 'package:family_ledger/features/reports/screens/reports_screen.dart';
import 'package:family_ledger/features/settings/providers/settings_view_model.dart';
import 'package:family_ledger/features/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Root shell hosting the app's top-level tabs behind a Material 3 bottom
/// navigation bar.
///
/// Each tab is kept alive in an [IndexedStack] rather than rebuilt on
/// every switch, so, for example, an in-progress search on the People tab
/// survives a trip to Settings and back.
///
/// Also the home of the automatic-backup trigger: "check on open" means
/// app launch *and* return from background, and this widget is the one
/// place that reliably sees both (via a post-first-frame callback and
/// [WidgetsBindingObserver.didChangeAppLifecycleState]) while having the
/// UI context needed to surface a broken backup setup to the user.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with WidgetsBindingObserver {
  static const _tabs = [
    DashboardScreen(),
    PeopleScreen(),
    ReportsScreen(),
    SettingsScreen(),
  ];

  bool _autoBackupRunning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Post-frame so the first paint never waits on the backup check; the
    // export itself then runs on the DB's background isolate.
    WidgetsBinding.instance.addPostFrameCallback((_) => _runAutoBackup());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _runAutoBackup();
  }

  /// Runs the automatic-backup check, guarded so overlapping triggers
  /// (launch immediately followed by a resume) can't start two exports.
  ///
  /// Swallows every error deliberately: this is an unattended background
  /// nicety, and no failure here may ever crash or block the app — the
  /// service already converts expected failures into outcomes, and the
  /// catch covers the truly unexpected (including environments where the
  /// service locator isn't populated, e.g. widget tests pumping AppShell).
  Future<void> _runAutoBackup() async {
    if (_autoBackupRunning) return;
    _autoBackupRunning = true;
    try {
      final outcome = await ref
          .read(autoBackupServiceProvider)
          .runIfDue();
      if (!mounted) return;

      switch (outcome) {
        case AutoBackupSucceeded():
          // Silent by design — but refresh the Backup screen's info card
          // so "Last Backup Date" is current if the user goes looking.
          ref.invalidate(backupViewModelProvider);
        case AutoBackupNoFolder():
          _showFolderPrompt(
            'Automatic backup is on, but no backup folder is chosen.',
          );
        case AutoBackupFolderUnavailable():
          _showFolderPrompt(
            'Automatic backup could not write to your backup folder. '
            'It may have been moved or its permission revoked.',
          );
        case AutoBackupDisabled():
        case AutoBackupNotDue():
        case AutoBackupFailed():
          // Disabled/not-due are the normal quiet cases. A generic
          // failure has no user-fixable action; it retries next open.
          break;
      }
    } catch (_) {
      // Never let the backup check take the app down; see doc comment.
    } finally {
      _autoBackupRunning = false;
    }
  }

  /// A broken backup setup must never fail silently: prompt with a direct
  /// fix — re-pick the folder right from the snackbar.
  void _showFolderPrompt(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 8),
        action: SnackBarAction(
          label: 'Choose folder',
          onPressed: _repickFolder,
        ),
      ),
    );
  }

  Future<void> _repickFolder() async {
    final path = await ref
        .read(backupFilePickerProvider)
        .pickDestinationDirectory();
    if (path == null) return;
    await ref
        .read(settingsViewModelProvider.notifier)
        .setAutoBackupDirectory(path);
    // The folder is fixed and a backup is still due (it never succeeded),
    // so run the check again right away instead of waiting for next open.
    await _runAutoBackup();
  }

  @override
  Widget build(BuildContext context) {
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
