import "dart:math";
import "../entities/message_category.dart";

/// A generated message plus the combination hash that produced it, so
/// the caller can persist it and avoid repeating the exact same
/// combination again soon.
class GeneratedText {
  final String text;
  final int hash;
  const GeneratedText(this.text, this.hash);
}

class _Bank {
  final List<String> openers;
  final List<String> bodies;
  final List<String> closers;
  const _Bank(this.openers, this.bodies, this.closers);

  int get size => openers.length * bodies.length * closers.length;
}

/// Fully offline, rule-based dynamic message generator.
///
/// Instead of one fixed string per detected state (the old approach),
/// each [MessageCategory] has three independent pools of Arabic phrase
/// fragments — opener / observation / closing-suggestion — written in
/// different tones (direct, analytical, warm). One random, non-repeating
/// combination is picked each time, so the *meaning* stays accurate to
/// the detected state while the *wording* varies. With ~8-12 fragments
/// per pool per category, each category alone has several hundred to a
/// few thousand distinct combinations, and there are 14 categories.
///
/// No network calls, nothing pre-generated or stored remotely — pure
/// local string composition, same "no data leaves the device" guarantee
/// as the rest of the Behavior Engine.
class MessageTemplateEngine {
  static final Random _rng = Random();

  /// Generates one message for [category], substituting `{token}`
  /// placeholders from [vars]. [recentHashes] is the list of the last
  /// combination-hashes already used for this category (persisted on
  /// [BehaviorProfileEntity].recentMsgHashes) — the engine retries until
  /// it finds a combination not in that list, or gives up after 30 tries
  /// (pool exhausted) and reuses one anyway rather than looping forever.
  static GeneratedText generate({
    required MessageCategory category,
    Map<String, String> vars = const {},
    List<int> recentHashes = const [],
  }) {
    final bank = _banks[category]!;
    int oi = 0, bi = 0, ci = 0, hash = 0;
    for (int attempt = 0; attempt < 30; attempt++) {
      oi = _rng.nextInt(bank.openers.length);
      bi = _rng.nextInt(bank.bodies.length);
      ci = _rng.nextInt(bank.closers.length);
      hash = oi * 10000 + bi * 100 + ci;
      if (!recentHashes.contains(hash)) break;
    }
    final raw = "${bank.openers[oi]} ${bank.bodies[bi]} ${bank.closers[ci]}".trim();
    return GeneratedText(_substitute(raw, vars), hash);
  }

  /// Total distinct combinations available for [category] — useful for
  /// diagnostics/tests, not used at runtime.
  static int poolSize(MessageCategory category) => _banks[category]!.size;

  static String _substitute(String s, Map<String, String> vars) {
    var out = s;
    vars.forEach((k, v) => out = out.replaceAll("{$k}", v));
    return out;
  }

  static final Map<MessageCategory, _Bank> _banks = {
    // ── procrastinationSpike: {count} tasks skipped today ──
    MessageCategory.procrastinationSpike: const _Bank(
      [
        "رصدنا نمطاً واضحاً اليوم:",
        "انتبه —",
        "ملاحظة سريعة:",
        "تحليل اليوم يشير إلى شيء مهم:",
        "قبل أن يفوت الوقت:",
        "تنبيه سلوكي:",
        "من المفيد أن تعرف هذا الآن:",
        "لحظة تأمل قصيرة:",
      ],
      [
        "{count} مهام تراكمت دون تنفيذ اليوم بلا سبب واضح",
        "التأجيل المتكرر لـ {count} مهام اليوم بدأ يشكّل نمطاً وليس حادثة عابرة",
        "عدد المهام المؤجلة اليوم ({count}) أعلى من المعتاد بوضوح",
        "بدأت تؤجل أكثر من المعتاد، و{count} مهام لا تزال معلّقة",
        "{count} مهام بانتظارك منذ ساعات دون أي تحرك",
        "التأجيل تحوّل اليوم إلى سلوك متكرر مع {count} مهام معلّقة",
        "لاحظ النظام تباطؤاً واضحاً: {count} مهام لم تُلمس بعد",
        "هذا اليوم يشبه بداية نمط تسويف مع {count} مهام مؤجلة",
        "مؤشرات اليوم تُظهر {count} مهام متوقفة عند نفس النقطة",
        "التوقف المتكرر أمام {count} مهام يستحق وقفة قصيرة معه",
      ],
      [
        "هل تريد تقسيمها إلى أجزاء أصغر لتسهيل البدء؟",
        "ابدأ بأصغرها فقط، الحجم لا يهم بقدر ما يهم البدء.",
        "خمس دقائق فقط في أي واحدة منها كفيلة بكسر الجمود.",
        "لا داعي لإنجازها كلها الآن، واحدة فقط تكفي لتغيير الاتجاه.",
        "التأجيل يكبر كل ساعة يمر — خطوة صغيرة الآن تكفي.",
        "جرّب البدء بالأسهل، الزخم يأتي بعدها تلقائياً.",
        "لا حكم هنا، فقط ملاحظة يمكن البناء عليها الآن.",
        "الوقت لا يزال كافياً لتغيير مسار اليوم.",
      ],
    ),

    // ── streakRisk: {streak} days ──
    MessageCategory.streakRisk: const _Bank(
      [
        "تنبيه بخصوص سلسلتك:",
        "قبل أن تفقد ما بنيته:",
        "احتمالية مرتفعة اليوم:",
        "ملاحظة مهمة عن استمراريتك:",
        "انتبه لهذا التفصيل:",
        "رسالة سريعة عن السلسلة:",
      ],
      [
        "احتمالية كسر سلسلة {streak} يوم مرتفعة في الساعات القادمة",
        "سلسلتك الحالية ({streak} يوماً) في نقطة حرجة اليوم",
        "المؤشرات تشير إلى خطر حقيقي على استمرارية {streak} يوم متواصلة",
        "نمط اليوم يختلف عن الأيام التي حافظت فيها على {streak} يوم",
        "بعد {streak} يوماً من الالتزام، اليوم يحتاج انتباهاً إضافياً",
        "الاستمرارية التي بنيتها على مدى {streak} يوم تستحق حماية اليوم",
      ],
      [
        "إنجاز مهمة واحدة فقط الآن يحمي السلسلة كاملة.",
        "لا يلزم إنجاز كل شيء، مهمة صغيرة تكفي للحفاظ عليها.",
        "خطوة واحدة تفصل بين استمرار السلسلة وانقطاعها.",
        "الحفاظ على الزخم أسهل بكثير من إعادة بنائه لاحقاً.",
        "استثمار خمس دقائق الآن يوفر عليك البدء من الصفر غداً.",
      ],
    ),

    // ── greatProgress: {percent}, {count} ──
    MessageCategory.greatProgress: const _Bank(
      [
        "أداء لافت الآن:",
        "هذا يستحق الإشارة إليه:",
        "لحظة زخم حقيقية:",
        "المؤشرات ممتازة حالياً:",
        "تستحق أن تعرف هذا:",
      ],
      [
        "معدل إنجازك الآن {percent}٪ مع {count} مهام مكتملة",
        "تركيزك مرتفع بوضوح اليوم بمعدل {percent}٪",
        "هذه الساعة من أقوى ساعاتك، بمعدل {percent}٪ وإنجاز {count} مهام",
        "وتيرة اليوم أعلى من متوسطك المعتاد بفارق ملحوظ",
        "{count} مهام أُنجزت بثبات، وهذا نمط يستحق الاستمرار عليه",
      ],
      [
        "استغل هذه الساعة لإنجاز أصعب مهمة في قائمتك.",
        "وقت مثالي للانتقال إلى المهمة التي كنت تؤجلها.",
        "حافظ على هذا الزخم لأطول فترة ممكنة اليوم.",
        "هذا هو الوقت المناسب لمهمة تحتاج تركيزاً أعلى.",
        "استثمر هذا التركيز قبل أن تنخفض الطاقة لاحقاً في اليوم.",
      ],
    ),

    // ── worstHourWarning: {hour} ──
    MessageCategory.worstHourWarning: const _Bank(
      [
        "تنبيه توقيت:",
        "بحسب سجلك السابق:",
        "ملاحظة من التحليل التاريخي:",
        "انتبه لهذا التوقيت تحديداً:",
      ],
      [
        "الساعة {hour} كانت تاريخياً من أكثر الأوقات التي تفشل فيها",
        "بياناتك السابقة تُظهر أن الساعة {hour} نقطة ضعف متكررة",
        "في أوقات مشابهة للساعة {hour} سابقاً، كان معدل التراجع أعلى من المعتاد",
      ],
      [
        "وعيك بهذا النمط الآن كفيل بتغييره.",
        "انتبه أكثر من العادة في هذه الساعة تحديداً.",
        "معرفة النمط مسبقاً نصف الطريق لكسره.",
        "جرّب مهمة أخف في هذا التوقيت إذا لاحظت تراجعاً.",
      ],
    ),

    // ── habitMilestone: {title}, {streak} ──
    MessageCategory.habitMilestone: const _Bank(
      [
        "إنجاز يستحق التوقف عنده:",
        "علامة فارقة:",
        "خطوة أقرب لهدفك:",
        "هذا تقدّم حقيقي:",
      ],
      [
        "عادة \"{title}\" بلغت {streak} يوم متواصل بدون انقطاع",
        "{streak} يوماً متتالياً في \"{title}\" — استمرارية نادراً ما تتكرر",
        "وصلت إلى {streak} يوماً في \"{title}\"، وهذا أقرب بكثير من هدفك",
      ],
      [
        "استمرارية بهذا الشكل لا تحدث بالصدفة.",
        "بقيت خطوات قليلة فقط لتثبيت هذه العادة نهائياً.",
        "هذا هو الاتساق الذي يصنع فرقاً حقيقياً على المدى الطويل.",
        "استمر بنفس الوتيرة، النتيجة أقرب مما تتصور.",
      ],
    ),

    // ── eveningPressure ──
    MessageCategory.eveningPressure: const _Bank(
      [
        "قرب نهاية اليوم:",
        "قبل منتصف الليل:",
        "ملاحظة مسائية:",
        "لا يزال هناك وقت:",
      ],
      [
        "اليوم يقترب من الانتهاء بمعدل إنجاز منخفض عن المعتاد",
        "جدول اليوم أصبح مزدحماً في ساعاته الأخيرة",
        "الوقت المتبقي من اليوم قليل، ومعدل الإنجاز لا يزال منخفضاً",
      ],
      [
        "لا يزال هناك وقت لتحسينه ولو قليلاً قبل منتصف الليل.",
        "أقترح تقليل عدد المهام مؤقتاً بدل إلغاء اليوم بالكامل.",
        "مهمة واحدة الآن أفضل من ترك اليوم بلا أي إنجاز.",
        "لا داعي للضغط، إنجاز بسيط الآن يكفي لإنهاء اليوم بشكل لائق.",
      ],
    ),

    // ── disappearance: {days} ──
    MessageCategory.disappearance: const _Bank(
      [
        "غبت لفترة:",
        "لاحظنا انقطاعاً:",
        "مرحباً بعودتك:",
        "ملاحظة عن غيابك الأخير:",
      ],
      [
        "مرّ ما يقارب {days} يوم منذ آخر استخدام لك، وهذا يختلف عن نمطك المعتاد",
        "غياب استمر نحو {days} يوم، أطول من المعتاد بالنسبة لك",
        "انقطاع {days} يوم عن التطبيق يستحق الانتباه إليه دون قلق",
      ],
      [
        "العودة اليوم أفضل من الانتظار لأسبوع آخر.",
        "لا داعي للشعور بالذنب، البداية من جديد الآن كافية.",
        "خطوة صغيرة اليوم تكفي لاستعادة الإيقاع تدريجياً.",
        "كل عودة بعد انقطاع هي بداية جديدة، لا امتداد للفشل.",
      ],
    ),

    // ── hiddenAvoidance ──
    MessageCategory.hiddenAvoidance: const _Bank(
      [
        "قراءة سلوكية:",
        "يبدو أن هناك نمطاً هنا:",
        "ملاحظة تحليلية:",
      ],
      [
        "يبدو أنك تتجنب تحديداً المهام التي تتطلب مجهوداً ذهنياً مرتفعاً اليوم",
        "التأجيل يتركز في المهام الصعبة تحديداً، وليس في كل المهام",
        "هناك تجنّب واضح للمهام الأكثر تعقيداً مقارنة بالمهام البسيطة",
      ],
      [
        "هذا أقرب لتجنّب معرفي منه لكسل حقيقي.",
        "تقسيم المهمة الصعبة إلى خطوة أولى صغيرة قد يكسر هذا التجنب.",
        "الوعي بهذا النمط أول خطوة لتجاوزه.",
      ],
    ),

    // ── hiddenBurnout ──
    MessageCategory.hiddenBurnout: const _Bank(
      [
        "قراءة سلوكية أعمق:",
        "ملاحظة تستحق الانتباه:",
        "تفسير محتمل:",
      ],
      [
        "تكرار الفشل المتتالي مؤخراً قد يعكس إرهاقاً ذهنياً تراكمياً",
        "النمط الحالي أقرب إلى استنزاف تدريجي منه إلى ضعف إرادة",
        "الفشل المتكرر في وقت قصير غالباً إشارة على حمل زائد وليس تقصيراً",
      ],
      [
        "قد تحتاج لتخفيف الحمل مؤقتاً بدل زيادة الضغط على نفسك.",
        "الراحة القصيرة الآن قد تكون أجدى من الدفع أكثر.",
        "الاعتراف بالإرهاق ليس تراجعاً، بل خطوة ذكية.",
      ],
    ),

    // ── hiddenProcrastination ──
    MessageCategory.hiddenProcrastination: const _Bank(
      [
        "ملاحظة دقيقة:",
        "الفرق هنا مهم:",
        "تحليل النمط الحالي:",
      ],
      [
        "النمط أقرب إلى تأجيل قرار البدء نفسه، لا تجنّب المهمة بذاتها",
        "التسويف الحالي يتعلق بلحظة الانطلاق أكثر مما يتعلق بصعوبة المهمة",
        "التردد قبل البدء هو العائق الفعلي، وليس المهمة في حد ذاتها",
      ],
      [
        "قاعدة الدقائق الخمس قد تكسر هذا التردد بسرعة.",
        "بمجرد البدء الفعلي، المقاومة عادة تتراجع سريعاً.",
        "التزم بالبدء فقط، لا بإنهاء المهمة كاملة.",
      ],
    ),

    // ── hiddenOverload ──
    MessageCategory.hiddenOverload: const _Bank(
      [
        "قراءة للحمل الحالي:",
        "ملاحظة عن الازدحام:",
        "تحليل الضغط الحالي:",
      ],
      [
        "تراكم عدة مهام دون تنفيذ الآن قد يعكس شعوراً بالإثقال الذهني",
        "عدد المهام المتراكمة حالياً أعلى مما يمكن معالجته دفعة واحدة",
        "الكم الحالي من المهام المعلّقة قد يفسر التوقف أكثر من ضعف الدافعية",
      ],
      [
        "تقليل عدد المهام المتزامنة قد يعيد الوضوح للاتجاه.",
        "التركيز على مهمة واحدة فقط الآن قد يكون أجدى من محاولة إنجاز الكل.",
        "إعادة ترتيب الأولويات قد تخفف هذا الشعور بسرعة.",
      ],
    ),

    // ── hiddenHesitation ──
    MessageCategory.hiddenHesitation: const _Bank(
      [
        "ملاحظة سلوكية دقيقة:",
        "نمط لافت في الاستخدام:",
        "تحليل قصير:",
      ],
      [
        "فتح التطبيق وإغلاقه بسرعة عدة مرات متتالية نمط تردد واضح",
        "الدخول والخروج المتكرر خلال دقائق قليلة يعكس تردداً قبل الالتزام",
        "هناك تردد ملحوظ قبل مواجهة المهمة الفعلية",
      ],
      [
        "اتخاذ قرار سريع، حتى لو بسيط، قد يكسر هذا التردد.",
        "أحياناً القرار نفسه أصعب من التنفيذ — جرّب البدء مباشرة.",
        "لا داعي للتفكير الطويل، خطوة واحدة تكفي للبدء.",
      ],
    ),

    // ── hiddenMotivationCollapse: {streak} ──
    MessageCategory.hiddenMotivationCollapse: const _Bank(
      [
        "ملاحظة نفسية دقيقة:",
        "تفسير محتمل للتردد الحالي:",
        "قراءة أعمق للموقف:",
      ],
      [
        "الاقتراب من كسر سلسلة {streak} يوم قد يولّد ضغطاً نفسياً يدفع للتجنب بدل المواجهة",
        "الخوف من فقدان إنجاز {streak} يوم قد يكون هو ما يعيقك الآن، لا نقص الدافعية",
        "الضغط الناتج عن قرب كسر سلسلة طويلة أحياناً يصنع تجنباً معاكساً تماماً للمطلوب",
      ],
      [
        "إنجاز مهمة صغيرة الآن يكسر هذه الحلقة النفسية فوراً.",
        "التركيز على خطوة واحدة بدل التفكير في السلسلة كاملة يخفف الضغط.",
        "المهمة البسيطة الآن أهم من إنجاز مثالي لاحقاً.",
      ],
    ),

    // ── hiddenFatigue ──
    MessageCategory.hiddenFatigue: const _Bank(
      [
        "ملاحظة عن التوقيت:",
        "قراءة مرتبطة بالوقت الحالي:",
        "تفسير محتمل للأداء الآن:",
      ],
      [
        "وقت متأخر من الليل مع أداء منخفض غالباً يعكس إرهاقاً جسدياً حقيقياً",
        "الساعة الحالية المتأخرة قد تفسر ضعف الأداء أكثر من أي سبب آخر",
        "التراجع في هذا التوقيت المتأخر أقرب إلى تعب طبيعي منه إلى تقصير",
      ],
      [
        "الراحة الآن قد تكون القرار الأصوب، لا الاستمرار بالضغط.",
        "تأجيل المهام المتبقية لصباح الغد قد يكون الخيار الأذكى.",
        "الاستماع للجسد هنا أهم من إنهاء كل شيء الليلة.",
      ],
    ),
  };
}
