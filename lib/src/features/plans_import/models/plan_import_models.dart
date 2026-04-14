import 'package:flutter/foundation.dart';

@immutable
class PlanImportDraft {
  const PlanImportDraft({
    required this.key,
    required this.name,
    required this.description,
    required this.price,
    required this.features,
    required this.limits,
    required this.isActive,
  });

  final String key;
  final String name;
  final String description;
  final num price;
  final List<String> features;
  final Map<String, num> limits;
  final bool isActive;
}

@immutable
class PlanImportParseResult {
  const PlanImportParseResult({
    required this.drafts,
    required this.errors,
  });

  final List<PlanImportDraft> drafts;
  final List<String> errors;
}

@immutable
class PlanImportValidationResult {
  const PlanImportValidationResult({
    required this.drafts,
    required this.errors,
    required this.invalidFeaturesByPlan,
    required this.duplicateKeys,
    required this.existingKeys,
  });

  final List<PlanImportDraft> drafts;
  final List<String> errors;
  final Map<String, List<String>> invalidFeaturesByPlan;
  final Set<String> duplicateKeys;
  final Set<String> existingKeys;

  bool get canImport => errors.isEmpty;
  int get totalPlans => drafts.length;
  int get invalidFeaturesCount => invalidFeaturesByPlan.values
      .fold<int>(0, (total, items) => total + items.length);
}

@immutable
class PlanImportCommitResult {
  const PlanImportCommitResult({
    required this.created,
    required this.updated,
  });

  final int created;
  final int updated;
}
