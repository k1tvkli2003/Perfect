import 'package:uuid/uuid.dart';

// Stage 36 bulk-action contract: preview first, then execute with one
// idempotency key per entity and a batch receipt.
//
// The plan is a pure preview: it splits the ordered selection into eligible
// vs skipped rows and issues no mutation keys. [PlannerTasksBulkPlan.execute]
// freezes that preview into a receipt carrying a `batchId`, per-entity
// idempotency keys, skipped reasons and Undo eligibility.
enum PlannerTasksBulkAction {
  complete,
  reopen,
  schedule,
  move,
  archive,
  restore,
  delete,
}

int _bulkBatchCounter = 0;

String _nextBulkBatchId() {
  _bulkBatchCounter += 1;
  return 'bulk-${DateTime.now().microsecondsSinceEpoch}-$_bulkBatchCounter';
}

/// One idempotency key per entity, deterministic for a batch. UUID v5 so
/// the store's RFC-UUID gate accepts it; retrying the same receipt reuses
/// the same key instead of duplicating the mutation.
String _bulkKey({required String batchId, required String entityId}) =>
    const Uuid().v5(Namespace.url.value, 'perfect:bulk:$batchId:$entityId');

/// Builds a preview-only bulk plan over [orderedIds] filtered by
/// [selectedIds]. Eligibility is decided by [isEligible]; skipped rows carry
/// the reason from [skipReason].
PlannerTasksBulkPlan planTasksBulk({
  required List<String> orderedIds,
  required Set<String> selectedIds,
  required bool Function(String id) isEligible,
  required String Function(String id) skipReason,
}) {
  final eligibleIds = <String>[];
  final skippedIds = <String>[];
  final skippedReasons = <String, String>{};
  for (final id in orderedIds) {
    if (!selectedIds.contains(id)) continue;
    if (isEligible(id)) {
      eligibleIds.add(id);
    } else {
      skippedIds.add(id);
      skippedReasons[id] = skipReason(id);
    }
  }
  return PlannerTasksBulkPlan._(
    eligibleIds: List.unmodifiable(eligibleIds),
    skippedIds: List.unmodifiable(skippedIds),
    skippedReasons: Map.unmodifiable(skippedReasons),
  );
}

/// Preview of one bulk run. Immutable; issues no mutation keys.
class PlannerTasksBulkPlan {
  const PlannerTasksBulkPlan._({
    required this.eligibleIds,
    required this.skippedIds,
    required this.skippedReasons,
  });

  /// Eligible IDs in stable result order.
  final List<String> eligibleIds;

  /// Skipped IDs in stable result order.
  final List<String> skippedIds;

  /// Skip reason per skipped ID.
  final Map<String, String> skippedReasons;

  /// Keys issued so far. Always empty: a plan never mutates.
  Map<String, String> get issuedKeys => const <String, String>{};

  /// A plan is never executed; [execute] returns a separate receipt.
  bool get executed => false;

  int get eligibleCount => eligibleIds.length;
  int get skippedCount => skippedIds.length;

  /// Freezes the preview into an executable receipt for [action], issuing
  /// exactly one idempotency key per eligible entity. Keys are RFC UUIDs
  /// (v5 over batch + entity) because the local store rejects any other
  /// mutation-ID shape.
  PlannerTasksBulkReceipt execute({required PlannerTasksBulkAction action}) {
    final batchId = _nextBulkBatchId();
    final perEntityKeys = <String, String>{
      for (final id in eligibleIds)
        id: _bulkKey(batchId: batchId, entityId: id),
    };
    return PlannerTasksBulkReceipt._(
      batchId: batchId,
      action: action,
      appliedIds: eligibleIds,
      perEntityKeys: Map.unmodifiable(perEntityKeys),
      skippedIds: skippedIds,
      skippedReasons: skippedReasons,
    );
  }
}

/// Receipt of one executed (or no-op) bulk run.
class PlannerTasksBulkReceipt {
  const PlannerTasksBulkReceipt._({
    required this.batchId,
    required this.action,
    required this.appliedIds,
    required this.perEntityKeys,
    required this.skippedIds,
    required this.skippedReasons,
  });

  final String batchId;
  final PlannerTasksBulkAction action;

  /// Eligible IDs the batch applied, in stable result order.
  final List<String> appliedIds;

  /// One idempotency key per applied entity.
  final Map<String, String> perEntityKeys;

  final List<String> skippedIds;
  final Map<String, String> skippedReasons;

  int get eligibleCount => appliedIds.length;
  int get skippedCount => skippedIds.length;

  /// Undo is offered only when the batch actually applied something.
  bool get undoEligible => appliedIds.isNotEmpty;
}

/// Report of one controller-executed bulk receipt: what applied, what was
/// skipped, and why. The controller owns this report; the domain receipt
/// stays the frozen preview the batch was built from.
class PlannerTasksBulkReport {
  const PlannerTasksBulkReport({
    required this.batchId,
    required this.action,
    required this.appliedIds,
    required this.skippedIds,
    required this.skippedReasons,
  });

  final String batchId;
  final PlannerTasksBulkAction action;
  final List<String> appliedIds;
  final List<String> skippedIds;
  final Map<String, String> skippedReasons;

  int get appliedCount => appliedIds.length;
  int get skippedCount => skippedIds.length;

  /// Undo is offered only when the batch actually applied something.
  bool get undoEligible => appliedIds.isNotEmpty;
}
