import 'package:educore/src/core/mvc/base_controller.dart';
import 'package:educore/src/features/plans_import/models/plan_import_models.dart';

enum PlanImportSource { json, csv }

class PlansImportController extends BaseController {
  PlansImportController() {
    errorMessage = 'Plan import module removed.';
  }

  PlanImportSource source = PlanImportSource.json;
  String rawInput = '';
  PlanImportParseResult parseResult =
      const PlanImportParseResult(drafts: [], errors: []);
  PlanImportValidationResult? validation;
  PlanImportCommitResult? lastCommit;
  String? errorMessage;

  bool get ready => false;
  bool get canImport => false;

  Future<void> retryInit() async {
    // No-op. Kept for API compatibility with older UI code.
    notifyListeners();
  }

  void setSource(PlanImportSource next) {
    source = next;
    parseResult = const PlanImportParseResult(drafts: [], errors: []);
    validation = null;
    lastCommit = null;
    errorMessage = null;
    notifyListeners();
  }

  void setInput(String value) {
    rawInput = value;
  }

  Future<void> preview() async {
    throw UnsupportedError('Plan import module removed.');
  }

  Future<void> importPlans() async {
    throw UnsupportedError('Plan import module removed.');
  }
}
