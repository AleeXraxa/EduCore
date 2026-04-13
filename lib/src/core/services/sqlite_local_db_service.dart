import 'package:educore/src/core/services/local_db_service.dart';

/// Placeholder for the SQLite implementation.
///
/// For desktop, the recommended approach is `sqflite_common_ffi` (Windows/macOS/Linux).
/// This class is intentionally non-functional until the SQLite dependency is added.
class SqliteLocalDbService implements LocalDbService {
  @override
  Future<void> close() async {
    throw UnimplementedError('SQLite not integrated yet.');
  }

  @override
  Future<void> init() async {
    throw UnimplementedError('SQLite not integrated yet.');
  }
}
