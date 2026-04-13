import 'package:educore/src/core/services/local_db_service.dart';

class NoopLocalDbService implements LocalDbService {
  @override
  Future<void> close() async {}

  @override
  Future<void> init() async {}
}
