import 'package:family_ledger/features/backup/screens/backup_screen.dart';
import 'package:flutter/material.dart';

/// Settings tab. Preferences (theme, currency, ...) land here in a future
/// phase — for now this only hosts the entry point into Backup & Restore,
/// since that needs to be reachable from somewhere.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.backup_outlined),
            title: const Text('Backup & Restore'),
            subtitle: const Text('Export or restore your data'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BackupScreen()),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Text(
                'More settings coming in future phases',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
