import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The app's top-level bottom-navigation tabs.
enum AppTab { home, people, reports, settings }

/// Which tab [AppShell] currently shows.
///
/// A provider rather than [AppShell]'s own local state, specifically so
/// screens nested inside one tab can switch to another — e.g. the
/// Dashboard's "People" quick action, or its Settings app bar action —
/// without needing a reference to `AppShell` itself.
class AppTabController extends Notifier<AppTab> {
  @override
  AppTab build() => AppTab.home;

  void select(AppTab tab) => state = tab;
}

final appTabProvider = NotifierProvider<AppTabController, AppTab>(
  AppTabController.new,
);
