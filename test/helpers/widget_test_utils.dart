import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Disposes the currently pumped widget tree and settles once more.
///
/// Call this as the last step of any `testWidgets` body that pumped a
/// widget tree depending on a reactive `StreamProvider` (anything watching
/// `transactionsStreamProvider`, directly or transitively).
///
/// Why this is needed: Drift's `.watch()` query streams schedule a
/// zero-duration `Timer` when cancelled, as part of their own internal
/// cleanup. If that cancellation only happens during `flutter_test`'s
/// automatic post-test teardown — which disposes the widget tree but does
/// not pump again afterward — the test framework's "no pending timers"
/// invariant check fails the test (and, in practice, can hang the whole
/// run rather than failing fast). Explicitly swapping in a trivial widget
/// and settling here, while still inside the test body, disposes the old
/// tree's provider subscriptions and gives that cleanup timer a chance to
/// fire under our control instead.
Future<void> disposeReactiveWidgetTree(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pumpAndSettle();
}

/// Grows the test surface so a long scrolling screen (the Dashboard,
/// Reports later) fits without scrolling.
///
/// `ListView`/slivers only inflate elements for children within the
/// viewport (plus a small cache extent) — this is true even for a plain
/// `ListView(children: [...])`, not just `.builder`. At the default
/// 800x600 test surface, content below a few cards' worth of scroll never
/// gets built at all, so `find.text(...)` genuinely finds nothing for it
/// — not because it's hidden, but because its element was never created.
/// Call this in `setUp` (paired with [resetTestViewport] in
/// `addTearDown`) instead of scrolling explicitly in every test.
void useTallTestViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 4000);
  tester.view.devicePixelRatio = 1.0;
}

/// Reverses [useTallTestViewport]. Call via `addTearDown` alongside it.
void resetTestViewport(WidgetTester tester) {
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
}
