import 'dart:convert';
import 'package:educore/src/core/mvc/base_controller.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/core/services/feature_service.dart';
import 'package:educore/src/core/services/plan_service.dart';
import 'package:educore/src/features/plans_import/models/plan_import_models.dart';

enum PlanImportSource { json, csv }

class PlansImportController extends BaseController {
  PlansImportController() {
    _init();
  }

  PlanService? _planService;
  FeatureService? _featureService;

  PlanImportSource source = PlanImportSource.json;
  String rawInput = '';
  PlanImportParseResult parseResult =
      const PlanImportParseResult(drafts: [], errors: []);
  PlanImportValidationResult? validation;
  PlanImportCommitResult? lastCommit;
  String? errorMessage;

  bool get ready => _planService != null && _featureService != null;
  bool get canImport => validation?.canImport == true && !busy;

  void _init() {
    _planService = AppServices.instance.planService;
    _featureService = AppServices.instance.featureService;
    if (_planService == null || _featureService == null) {
      errorMessage = 'Plan import requires Cloud Firestore services.';
    }
    notifyListeners();
  }

  Future<void> retryInit() async {
    await AppServices.instance.init();
    _init();
  }

  void setSource(PlanImportSource next) {
    source = next;
    parseResult = const PlanImportParseResult(drafts: [], errors: []);
    validation = null;
    lastCommit = null;
    notifyListeners();
  }

  void setInput(String value) {
    rawInput = value;
  }

  Future<void> preview() async {
    if (!ready) return;
    await runBusy(() async {
      lastCommit = null;
      parseResult = _parseInput();
      if (parseResult.drafts.isEmpty && parseResult.errors.isEmpty) {
        parseResult = PlanImportParseResult(
          drafts: [],
          errors: ['No plans found in input.'],
        );
      }

      if (parseResult.drafts.isNotEmpty) {
        validation = await _validateDrafts(parseResult.drafts);
      } else {
        validation = null;
      }
    });
  }

  PlanImportParseResult _parseInput() {
    if (rawInput.trim().isEmpty) {
      return const PlanImportParseResult(drafts: [], errors: []);
    }

    if (source == PlanImportSource.json) {
      return _parseJson();
    } else {
      return _parseCsv();
    }
  }

  PlanImportParseResult _parseJson() {
    final List<PlanImportDraft> drafts = [];
    final List<String> errors = [];

    try {
      final decoded = json.decode(rawInput);
      if (decoded is! List) {
        return PlanImportParseResult(drafts: [], errors: ['JSON must be an array of plans.']);
      }

      for (var i = 0; i < decoded.length; i++) {
        final item = decoded[i];
        if (item is! Map<String, dynamic>) {
          errors.add('Item at index $i is not an object.');
          continue;
        }

        try {
          drafts.add(PlanImportDraft(
            key: (item['key'] ?? '').toString(),
            name: (item['name'] ?? '').toString(),
            description: (item['description'] ?? '').toString(),
            price: num.tryParse(item['price']?.toString() ?? '0') ?? 0,
            features: List<String>.from(item['features'] ?? []),
            limits: Map<String, num>.from(item['limits'] ?? {}),
            isActive: item['isActive'] == true,
          ));
        } catch (e) {
          errors.add('Error parsing item at index $i: $e');
        }
      }
    } catch (e) {
      errors.add('Invalid JSON: $e');
    }

    return PlanImportParseResult(drafts: drafts, errors: errors);
  }

  PlanImportParseResult _parseCsv() {
    final List<PlanImportDraft> drafts = [];
    final List<String> errors = [];

    final lines = rawInput.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.length < 2) {
      return PlanImportParseResult(drafts: [], errors: ['CSV must have a header and at least one data row.']);
    }

    // Basic CSV parser (comma separated, no quotes support for simplicity in this admin tool)
    final headers = lines[0].split(',').map((h) => h.trim().toLowerCase()).toList();
    
    for (var i = 1; i < lines.length; i++) {
      final parts = lines[i].split(',');
      if (parts.length < headers.length) {
        errors.add('Line ${i + 1} has insufficient columns.');
        continue;
      }

      final Map<String, String> row = {};
      for (var j = 0; j < headers.length; j++) {
        row[headers[j]] = parts[j].trim();
      }

      try {
        // Parse features (semicolon separated)
        final features = (row['features'] ?? '')
            .split(';')
            .map((f) => f.trim())
            .where((f) => f.isNotEmpty)
            .toList();

        // Parse limits (key=value;key2=value2)
        final limits = <String, num>{};
        final limitParts = (row['limits'] ?? '').split(';').where((p) => p.contains('='));
        for (final p in limitParts) {
          final kv = p.split('=');
          if (kv.length == 2) {
            limits[kv[0].trim()] = num.tryParse(kv[1].trim()) ?? 0;
          }
        }

        drafts.add(PlanImportDraft(
          key: row['key'] ?? '',
          name: row['name'] ?? '',
          description: row['description'] ?? '',
          price: num.tryParse(row['price'] ?? '0') ?? 0,
          features: features,
          limits: limits,
          isActive: (row['isactive'] ?? 'true').toLowerCase() == 'true',
        ));
      } catch (e) {
        errors.add('Error parsing line ${i + 1}: $e');
      }
    }

    return PlanImportParseResult(drafts: drafts, errors: errors);
  }

  Future<PlanImportValidationResult> _validateDrafts(List<PlanImportDraft> drafts) async {
    final List<String> errors = [];
    final Map<String, List<String>> invalidFeatures = {};
    final Set<String> keys = {};
    final Set<String> duplicates = {};

    // Get existing plans to check for keys
    final existingPlans = await _planService!.watchPlans().first;
    final existingKeys = existingPlans.map((p) => p.id.toLowerCase()).toSet();
    
    // Get registry features
    final registry = await _featureService!.watchFeatures().first;
    final registryKeys = registry.map((f) => f.key.toLowerCase()).toSet();

    for (final draft in drafts) {
      final key = draft.key.toLowerCase();
      if (key.isEmpty) {
        errors.add('Plan "${draft.name}" is missing a unique key.');
      } else {
        if (keys.contains(key)) {
          duplicates.add(key);
        }
        keys.add(key);
      }

      if (draft.name.trim().isEmpty) {
        errors.add('Plan with key "${draft.key}" is missing a name.');
      }

      // Check features
      final invalid = draft.features
          .where((f) => !registryKeys.contains(f.toLowerCase()))
          .toList();
      if (invalid.isNotEmpty) {
        invalidFeatures[key] = invalid;
      }
    }

    if (duplicates.isNotEmpty) {
      errors.add('Duplicate keys found in input: ${duplicates.join(', ')}');
    }

    return PlanImportValidationResult(
      drafts: drafts,
      errors: errors,
      invalidFeaturesByPlan: invalidFeatures,
      duplicateKeys: duplicates,
      existingKeys: keys.intersection(existingKeys),
    );
  }

  Future<void> importPlans() async {
    if (!canImport) return;

    await runBusy(() async {
      final items = validation!.drafts.map((d) => {
        'name': d.name,
        'description': d.description,
        'price': d.price,
        'features': d.features,
        'limits': d.limits,
        'isActive': d.isActive,
      }).toList();

      await _planService!.createPlansBatch(items);

      lastCommit = PlanImportCommitResult(
        created: items.length,
        updated: 0, // Currently create only logic in batch
      );

      // Clear after success
      parseResult = const PlanImportParseResult(drafts: [], errors: []);
      validation = null;
    });
  }
}
