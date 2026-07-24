import "package:flutter/foundation.dart";
import "../../domain/entities/prediction_types.dart";
import "../../domain/services/prediction_engine.dart";

/// Drives a "Predictions" panel — today's success/failure forecast,
/// per-habit drop risk, return-after-absence estimate, fatigue and
/// burnout probabilities, and the proactive solutions attached to
/// whichever of those crossed its threshold. Same Shadow Mode gating
/// convention as BehaviorViewModel: call [refresh] after Shadow Mode
/// has cleared, since predictions need at least a few days of real
/// history to mean anything.
class PredictionViewModel extends ChangeNotifier {
  final PredictionEngine predictionEngine;
  PredictionViewModel({required this.predictionEngine});

  bool isLoading = true;
  PredictionBundle? bundle;

  Future<void> refresh() async {
    isLoading = true;
    notifyListeners();
    bundle = await predictionEngine.computeAll();
    isLoading = false;
    notifyListeners();
  }
}
