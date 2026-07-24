import "package:equatable/equatable.dart";
import "message_types.dart";

/// Today's forward-looking outcome forecast — ported from spec section
/// 4 ("رابعاً: محرك التوقعات"), items "احتمال فشل اليوم" /
/// "احتمال نجاح اليوم". `confidence` reflects how much history backs
/// the estimate (0 with <3 days of data, rising toward 100).
class DayOutcomePrediction extends Equatable {
  final int successProbability; // 0-100
  final int failureProbability; // 0-100, not simply 100-success (floored)
  final int confidence; // 0-100 — how much this should be trusted

  const DayOutcomePrediction({
    required this.successProbability,
    required this.failureProbability,
    required this.confidence,
  });

  @override
  List<Object?> get props => [successProbability, failureProbability, confidence];
}

/// Per-habit drop-risk — "احتمال ترك عادة".
class HabitDropPrediction extends Equatable {
  final String habitId;
  final String title;
  final int dropProbability; // 0-100

  const HabitDropPrediction({
    required this.habitId,
    required this.title,
    required this.dropProbability,
  });

  @override
  List<Object?> get props => [habitId, title, dropProbability];
}

/// "احتمال العودة بعد الانقطاع" — only meaningful once the user is
/// already in an unusual absence window (see checkSilenceAnomaly).
class ReturnPrediction extends Equatable {
  final bool isCurrentlyAbsent;
  final int returnProbability; // 0-100 — likelihood they come back at all
  final int estimatedDaysToReturn;

  const ReturnPrediction({
    required this.isCurrentlyAbsent,
    required this.returnProbability,
    required this.estimatedDaysToReturn,
  });

  @override
  List<Object?> get props => [isCurrentlyAbsent, returnProbability, estimatedDaysToReturn];
}

/// "احتمال الإرهاق" — short-horizon (this week) fatigue signal.
class FatiguePrediction extends Equatable {
  final int fatigueProbability; // 0-100

  const FatiguePrediction({required this.fatigueProbability});

  @override
  List<Object?> get props => [fatigueProbability];
}

/// "احتمال الاحتراق الذهني" — longer-horizon, cumulative overload.
class BurnoutPrediction extends Equatable {
  final int burnoutProbability; // 0-100

  const BurnoutPrediction({required this.burnoutProbability});

  @override
  List<Object?> get props => [burnoutProbability];
}

/// A concrete, proactive suggestion attached to whichever prediction(s)
/// crossed a risk threshold — spec: "ثم يعرض حلولاً قبل وقوع المشكلة."
class ProactiveSolution extends Equatable {
  final String icon;
  final String text;
  final MessageCategory relatedTo;

  const ProactiveSolution({
    required this.icon,
    required this.text,
    required this.relatedTo,
  });

  @override
  List<Object?> get props => [icon, text, relatedTo];
}

/// Everything the Prediction Engine produces in one pass, ready for a
/// dashboard/insights panel to render.
class PredictionBundle extends Equatable {
  final DayOutcomePrediction dayOutcome;
  final List<HabitDropPrediction> habitDrops; // sorted, highest risk first
  final ReturnPrediction returnPrediction;
  final FatiguePrediction fatigue;
  final BurnoutPrediction burnout;
  final List<ProactiveSolution> solutions;

  const PredictionBundle({
    required this.dayOutcome,
    required this.habitDrops,
    required this.returnPrediction,
    required this.fatigue,
    required this.burnout,
    required this.solutions,
  });

  @override
  List<Object?> get props =>
      [dayOutcome, habitDrops, returnPrediction, fatigue, burnout, solutions];
}
