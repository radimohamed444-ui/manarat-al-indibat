import "package:flutter/foundation.dart";
import "../../domain/entities/behavior_insight_types.dart";
import "../../domain/services/behavior_engine.dart";

/// Drives the Intelligence / Insights panel — persona, risk, deep
/// patterns, hidden-reason interpretations, and the app's current
/// adaptive personality mode. All computed on-demand from the
/// BehaviorEngine (no network, no cloud AI).
class BehaviorViewModel extends ChangeNotifier {
  final BehaviorEngine behaviorEngine;
  BehaviorViewModel({required this.behaviorEngine}) {
    refresh();
  }

  bool isLoading = true;
  PersonaModel? persona;
  RiskAssessment? risk;
  List<PatternInsight> patterns = [];
  List<HiddenReason> reasons = [];
  AppPersonalityMode personality = AppPersonalityMode.calm;
  SmartNotification? smartNotification;
  List<PatternInsight>? weeklyMirror;
  int shadowModeDaysElapsed = 0;
  static const int shadowModeDays = 14;
  bool get shadowModeActive => shadowModeDaysElapsed < shadowModeDays;

  Future<void> refresh() async {
    isLoading = true;
    notifyListeners();

    final profile = await behaviorEngine.getProfile();
    shadowModeDaysElapsed = profile.firstOpenAt == null
        ? 0
        : DateTime.now().difference(profile.firstOpenAt!).inDays;

    if (shadowModeActive) {
      // Shadow Mode: silently observe, no advice, no judgments — per
      // the app'"'"'s philosophy, the engine still records data underneath
      // (analyzeBehavior/recordOpenEvent already ran on app open), but
      // we do not surface persona/risk/patterns/notifications yet.
      isLoading = false;
      notifyListeners();
      return;
    }

    persona = await behaviorEngine.computePersonaModel();
    risk = await behaviorEngine.computeRiskAssessment();
    patterns = await behaviorEngine.deepPatternScan();
    reasons = await behaviorEngine.interpretHiddenReason();
    personality = await behaviorEngine.computeAppPersonality();
    smartNotification = await behaviorEngine.generateSmartNotification();
    weeklyMirror = await behaviorEngine.maybeGenerateWeeklyMirror();
    await behaviorEngine.maybeLockIdentity();
    await behaviorEngine.checkSilenceAnomaly();

    isLoading = false;
    notifyListeners();
  }
}
