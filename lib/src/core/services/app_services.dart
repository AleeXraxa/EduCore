import 'package:educore/src/core/services/local_db_service.dart';
import 'package:educore/src/core/services/noop_local_db_service.dart';
import 'package:educore/src/core/services/sqlite_local_db_service.dart';

class AppServices {
  AppServices._();

  static final AppServices instance = AppServices._();

  late final LocalDbService localDb;

  Future<void> init() async {
    // TODO: Switch to `SqliteLocalDbService` once SQLite is integrated.
    // Keep the default as a no-op to avoid breaking first-run development.
    final useSqlite =
        const bool.fromEnvironment('EDUCORE_USE_SQLITE', defaultValue: false);
    localDb = useSqlite ? SqliteLocalDbService() : NoopLocalDbService();
    await localDb.init();
  }
}
