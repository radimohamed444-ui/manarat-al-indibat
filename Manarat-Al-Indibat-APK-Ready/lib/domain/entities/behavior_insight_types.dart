import "package:equatable/equatable.dart";

/// A single detected behavioral pattern — ported from deepPatternScan().
class PatternInsight extends Equatable {
  final String icon;
  final String text;
  const PatternInsight({required this.icon, required this.text});

  @override
  List<Object?> get props => [icon, text];
}

/// Behavioral persona classification — ported from computePersonaModel().
/// The seven personas map exactly to the HTML app's labels.
class PersonaModel extends Equatable {
  final String label; // English key, e.g. "Extreme Productive Mode"
  final String ar; // Arabic display label
  final String desc;
  final String icon;
  const PersonaModel({
    required this.label,
    required this.ar,
    required this.desc,
    required this.icon,
  });

  static const analyzing = PersonaModel(
    label: "قيد التحليل",
    ar: "قيد التحليل",
    desc: "يحتاج النظام لبيانات أكثر لتكوين نموذج دقيق لشخصيتك السلوكية.",
    icon: "🧬",
  );

  @override
  List<Object?> get props => [label, ar, desc, icon];
}

/// Three independent 0-100 risk scores — ported from computeRiskAssessment().
class RiskAssessment extends Equatable {
  final int abandonRisk; // risk the user stops using the app
  final int breakStreakRisk; // risk of losing today's streak
  final int relapseRisk; // risk of habit relapse

  const RiskAssessment({
    required this.abandonRisk,
    required this.breakStreakRisk,
    required this.relapseRisk,
  });

  @override
  List<Object?> get props => [abandonRisk, breakStreakRisk, relapseRisk];
}

enum NotifKind { danger, warn, gold, success }

/// A single proactive smart notification — ported from
/// generateSmartNotification(). `key` dedupes so the same nudge isn't
/// re-sent on the same day.
class SmartNotification extends Equatable {
  final String icon;
  final String text;
  final NotifKind kind;
  final String key;
  const SmartNotification({
    required this.icon,
    required this.text,
    required this.kind,
    required this.key,
  });

  @override
  List<Object?> get props => [icon, text, kind, key];
}

enum HiddenReasonType {
  avoidance,
  burnout,
  procrastination,
  overload,
  hesitation,
  motivationCollapse,
  fatigue,
}

/// A psychological interpretation of *why* a behavior is happening, not
/// just what happened — ported from interpretHiddenReason().
class HiddenReason extends Equatable {
  final String icon;
  final HiddenReasonType type;
  final String text;
  const HiddenReason({required this.icon, required this.type, required this.text});

  @override
  List<Object?> get props => [icon, type, text];
}

/// The app's five adaptive "moods" — ported from computeAppPersonality().
enum AppPersonalityMode { calm, strict, analytical, warning, recovery }

extension AppPersonalityModeX on AppPersonalityMode {
  String get label => switch (this) {
        AppPersonalityMode.calm => "هادئة",
        AppPersonalityMode.strict => "صارمة",
        AppPersonalityMode.analytical => "تحليلية",
        AppPersonalityMode.warning => "إنذارية",
        AppPersonalityMode.recovery => "داعمة وتعافي",
      };

  String get icon => switch (this) {
        AppPersonalityMode.calm => "🌤️",
        AppPersonalityMode.strict => "🛡️",
        AppPersonalityMode.analytical => "📊",
        AppPersonalityMode.warning => "🚨",
        AppPersonalityMode.recovery => "🌱",
      };

  String get description => switch (this) {
        AppPersonalityMode.calm => "النظام يتابعك بهدوء وبدون ضغط — استمر بوتيرتك الطبيعية.",
        AppPersonalityMode.strict => "لاحظ النظام تجاهلاً متكرراً للتنبيهات، لذا تحوّل إلى أسلوب أكثر مباشرة وحزماً.",
        AppPersonalityMode.analytical => "أداؤك مستقر وعالٍ، لذا يعتمد النظام الآن تحليلات دقيقة بدل التحفيز العام.",
        AppPersonalityMode.warning => "المؤشرات الحالية تستدعي انتباهاً أعلى — النظام في وضع تحذير نشط.",
        AppPersonalityMode.recovery => "رصد النظام إشارات إرهاق أو انتكاسة، وتحوّل لأسلوب داعم وهادئ لمساعدتك على العودة تدريجياً.",
      };
}

/// A locked-in long-term behavioral identity — ported from
/// maybeLockIdentity(), formed after 30 days / 18 active days.
class IdentityProfile extends Equatable {
  final String persona;
  final int? bestHour;
  final int? worstHour;
  final String weaknessType;
  final bool resilientAfterFail;
  final DateTime lockedAt;

  const IdentityProfile({
    required this.persona,
    this.bestHour,
    this.worstHour,
    required this.weaknessType,
    required this.resilientAfterFail,
    required this.lockedAt,
  });

  @override
  List<Object?> get props =>
      [persona, bestHour, worstHour, weaknessType, resilientAfterFail, lockedAt];
}
