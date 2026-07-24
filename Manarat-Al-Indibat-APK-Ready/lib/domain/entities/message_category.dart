/// Categories understood by [MessageTemplateEngine]. Each one maps to an
/// existing detection trigger already computed elsewhere in
/// [BehaviorEngine] (skip counts, risk scores, focus rate, etc.) — this
/// enum does not add new detection logic, it only gives each existing
/// trigger a stable key so the engine can generate varied text for it
/// and remember which combinations were already used.
enum MessageCategory {
  /// Repeated postponement detected "today" (skippedNow >= 3).
  procrastinationSpike,

  /// High risk of breaking an active streak.
  streakRisk,

  /// Strong focus/completion rate right now.
  greatProgress,

  /// Current hour matches the historically worst hour.
  worstHourWarning,

  /// A habit just crossed a 7-day multiple.
  habitMilestone,

  /// Late evening with a low completion rate for the day.
  eveningPressure,

  /// Unusual absence compared to the user's normal open pattern.
  disappearance,

  /// Avoiding high-effort tasks specifically (cognitive avoidance).
  hiddenAvoidance,

  /// Repeated consecutive failures suggesting burnout.
  hiddenBurnout,

  /// Repeated delay of the *decision to start*, not the task itself.
  hiddenProcrastination,

  /// Several tasks piled up unfinished — cognitive overload.
  hiddenOverload,

  /// Rapid open/close app cycles — hesitation before commitment.
  hiddenHesitation,

  /// Close to breaking a long streak — pressure-driven avoidance.
  hiddenMotivationCollapse,

  /// Late night with low performance — physical fatigue.
  hiddenFatigue,
}
