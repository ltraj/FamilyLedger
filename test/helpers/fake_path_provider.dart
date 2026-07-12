import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Fakes `path_provider`'s platform channel for tests: every path it can
/// be asked for resolves to [rootPath], a temp directory the test owns
/// and cleans up itself.
///
/// Needed because `BackupServiceImpl`/`RestoreServiceImpl`/
/// `ImportValidatorImpl` call `getTemporaryDirectory()`/
/// `getApplicationDocumentsDirectory()` directly — without this, those
/// calls throw `MissingPluginException` under `flutter test`, which has
/// no real platform channels wired up.
class FakePathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  FakePathProviderPlatform(this.rootPath);

  final String rootPath;

  @override
  Future<String?> getTemporaryPath() async => rootPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => rootPath;

  @override
  Future<String?> getApplicationSupportPath() async => rootPath;

  @override
  Future<String?> getLibraryPath() async => rootPath;
}
