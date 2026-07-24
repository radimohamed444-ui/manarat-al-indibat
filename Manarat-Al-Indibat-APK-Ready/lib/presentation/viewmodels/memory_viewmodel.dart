import "package:flutter/foundation.dart";
import "../../domain/entities/memory_types.dart";
import "../../domain/services/behavior_memory_engine.dart";

/// Drives a "Behavior Memory" panel — the month / 6-months / year
/// past-vs-present comparison. Same Shadow Mode + lazy-refresh
/// convention as [PredictionViewModel]: call [refresh] once Shadow
/// Mode has cleared, since the further-out comparisons only mean
/// anything once enough daily snapshots exist.
class MemoryViewModel extends ChangeNotifier {
  final BehaviorMemoryEngine memoryEngine;
  MemoryViewModel({required this.memoryEngine});

  bool isLoading = true;
  MemoryReport? report;

  Future<void> refresh() async {
    isLoading = true;
    notifyListeners();
    report = await memoryEngine.getFullMemoryReport();
    isLoading = false;
    notifyListeners();
  }
}
