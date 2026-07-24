import "package:equatable/equatable.dart";

/// Every situation the Message Engine can compose a nudge for — maps
/// directly to section 3 of the spec (كسل / تقدم / انتكاسة / اختفاء /
/// قرب من هدف / ضغط) plus a few extra states the engine already
/// detects elsewhere (streak saved, comeback, steady calm).
enum MessageCategory {
  laziness, // بدأ يؤجل أكثر من المعتاد
  progress, // أفضل أسبوع/يوم حتى الآن
  relapse, // انتكاسة بعد نجاح
  disappearance, // غياب عن التطبيق
  nearGoal, // قريب من هدف
  overload, // جدول مزدحم / ضغط
  streakSaved, // أنقذ سلسلة كانت مهددة
  comeback, // عاد بعد غياب
  steady, // مستقر بدون حدث خاص
  habitRisk, // عادة معينة مهددة بالترك (من محرك التوقعات)
  fatigueWarning, // احتمال إرهاق مرتفع (من محرك التوقعات)
  burnoutWarning, // احتمال احتراق ذهني مرتفع (من محرك التوقعات)
  worstHourPattern, // الساعة الحالية هي تاريخياً أكثر ساعة فشل
  streakRisk, // احتمال كسر سلسلة نشطة مرتفع اليوم

  // ── "الأسباب الخفية" — ported from interpretHiddenReason(), each is
  // a psychological *why*, not just a *what* ──
  hiddenAvoidance, // تجنّب معرفي للمهام الصعبة تحديداً
  hiddenBurnout, // فشل متتالي يعكس إرهاقاً تراكمياً
  hiddenProcrastination, // تأجيل قرار البدء نفسه لا المهمة
  hiddenOverload, // تراكم مهام غير منفذة = إثقال ذهني
  hiddenHesitation, // فتح/إغلاق متكرر وسريع = تردد
  hiddenMotivationCollapse, // اقتراب كسر سلسلة طويلة يولّد ضغطاً
  hiddenFatigue, // وقت متأخر + أداء منخفض = تعب جسدي

  // ── Behavior Memory — past-vs-present comparison (Pass 4) ──
  memoryImproved, // أفضل من نفس الفترة قبل شهر/6 أشهر/سنة
  memoryDeclined, // أضعف من نفس الفترة قبل شهر/6 أشهر/سنة
  memoryStable, // شبه ثابت مقارنة بالماضي

  // ── Notification Intelligence — behavior-adaptive triggers (Pass 4) ──
  notifMissedUsualTime, // لم يفتح التطبيق في وقته المعتاد اليوم
  notifMorningBoost, // تحفيز صباحي مبني على ساعة الإنتاجية الفعلية للمستخدم
}

/// A single composed message — assembled from several independently
/// varying sentence pools, so the same category rarely produces the
/// same exact text twice in a row.
class GeneratedMessage extends Equatable {
  final String icon;
  final String text;
  final MessageCategory category;

  const GeneratedMessage({
    required this.icon,
    required this.text,
    required this.category,
  });

  @override
  List<Object?> get props => [icon, text, category];
}
