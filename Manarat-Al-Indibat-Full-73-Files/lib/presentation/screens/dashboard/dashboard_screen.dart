import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "../../../core/widgets/glass_card.dart";
import "../../../core/theme/app_colors.dart";
import "../../../domain/entities/behavior_insight_types.dart";
import "../../viewmodels/schedule_viewmodel.dart";
import "../../viewmodels/habit_viewmodel.dart";
import "../../viewmodels/behavior_viewmodel.dart";
import "../../viewmodels/prediction_viewmodel.dart";
import "../../viewmodels/memory_viewmodel.dart";
import "../../../domain/entities/prediction_types.dart";
import "../../../domain/entities/memory_types.dart";
import "../../../core/di/injection.dart";

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => sl<ScheduleViewModel>()),
        ChangeNotifierProvider(create: (_) => sl<HabitViewModel>()),
        ChangeNotifierProvider(create: (_) => sl<BehaviorViewModel>()),
        ChangeNotifierProvider(create: (_) => sl<PredictionViewModel>()..refresh()),
        ChangeNotifierProvider(create: (_) => sl<MemoryViewModel>()..refresh()),
      ],
      child: const _DashboardBody(),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody();

  @override
  Widget build(BuildContext context) {
    final scheduleVm = context.watch<ScheduleViewModel>();
    final habitVm = context.watch<HabitViewModel>();
    final behaviorVm = context.watch<BehaviorViewModel>();
    final predictionVm = context.watch<PredictionViewModel>();
    final memoryVm = context.watch<MemoryViewModel>();

    return RefreshIndicator(
      onRefresh: () async {
        await behaviorVm.refresh();
        await predictionVm.refresh();
        await memoryVm.refresh();
      },
      color: AppColors.primary,
      backgroundColor: AppColors.surfaceElevated,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            title: const Text("منارة الانضباط"),
            actions: [
              IconButton(icon: const Icon(Icons.notifications_none), onPressed: () {}),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (behaviorVm.shadowModeActive)
                  _ShadowModeBanner(daysElapsed: behaviorVm.shadowModeDaysElapsed)
                else ...[
                  if (behaviorVm.smartNotification != null)
                    _SmartNotificationCard(notif: behaviorVm.smartNotification!),
                  if (behaviorVm.smartNotification != null) const SizedBox(height: 16),
                  if (behaviorVm.persona != null) _PersonaCard(persona: behaviorVm.persona!),
                  const SizedBox(height: 16),
                  if (behaviorVm.risk != null) _RiskCard(risk: behaviorVm.risk!),
                  const SizedBox(height: 16),
                ],
                _TodayProgressCard(rate: scheduleVm.completionRate),
                const SizedBox(height: 16),
                _QuickStatsRow(
                  pendingTasks: scheduleVm.todaySchedule.length,
                  activeHabits: habitVm.habits.length,
                ),
                if (!behaviorVm.shadowModeActive &&
                    !predictionVm.isLoading &&
                    predictionVm.bundle != null) ...[
                  const SizedBox(height: 16),
                  _PredictionsCard(bundle: predictionVm.bundle!),
                ],
                if (!behaviorVm.shadowModeActive &&
                    !memoryVm.isLoading &&
                    memoryVm.report != null &&
                    memoryVm.report!.comparisons.any((c) => c.hasData)) ...[
                  const SizedBox(height: 16),
                  _MemoryCard(report: memoryVm.report!),
                ],
                if (!behaviorVm.shadowModeActive && behaviorVm.patterns.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _PatternsCard(patterns: behaviorVm.patterns),
                ],
                if (!behaviorVm.shadowModeActive && behaviorVm.reasons.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _ReasonsCard(reasons: behaviorVm.reasons),
                ],
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShadowModeBanner extends StatelessWidget {
  final int daysElapsed;
  const _ShadowModeBanner({required this.daysElapsed});

  @override
  Widget build(BuildContext context) {
    final remaining = (14 - daysElapsed).clamp(0, 14);
    return GlassCard(
      borderRadius: 18,
      child: Row(
        children: [
          const Icon(Icons.visibility_outlined, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("وضع الملاحظة الصامتة نشط", style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  remaining > 0
                      ? "التطبيق يراقب سلوكك دون إصدار أحكام أو نصائح — تبقّى $remaining يوم قبل ظهور أول تحليل سلوكي."
                      : "اكتملت فترة الملاحظة — التحليل السلوكي جاهز الآن.",
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SmartNotificationCard extends StatelessWidget {
  final SmartNotification notif;
  const _SmartNotificationCard({required this.notif});

  Color get _color => switch (notif.kind) {
        NotifKind.danger => AppColors.danger,
        NotifKind.warn => AppColors.warning,
        NotifKind.gold => AppColors.secondary,
        NotifKind.success => AppColors.success,
      };

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 18,
      child: Row(
        children: [
          Text(notif.icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(notif.text, style: TextStyle(color: _color, fontSize: 13, height: 1.5)),
          ),
        ],
      ),
    );
  }
}

class _PersonaCard extends StatelessWidget {
  final PersonaModel persona;
  const _PersonaCard({required this.persona});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(
        children: [
          Text(persona.icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(persona.ar, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 4),
                Text(persona.desc, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RiskCard extends StatelessWidget {
  final RiskAssessment risk;
  const _RiskCard({required this.risk});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("مؤشرات المخاطر", style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _RiskRow(label: "خطر التوقف عن الاستخدام", value: risk.abandonRisk),
          const SizedBox(height: 8),
          _RiskRow(label: "خطر كسر السلسلة اليوم", value: risk.breakStreakRisk),
          const SizedBox(height: 8),
          _RiskRow(label: "خطر انتكاسة العادات", value: risk.relapseRisk),
        ],
      ),
    );
  }
}

class _MemoryCard extends StatelessWidget {
  final MemoryReport report;
  const _MemoryCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final withData = report.comparisons.where((c) => c.hasData).toList();
    return GlassCard(
      borderGradient: AppColors.primaryGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("الذاكرة السلوكية", style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text(
            "كيف كنت مقارنة بنفسك في الماضي",
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
          ),
          const SizedBox(height: 12),
          for (final c in withData) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.icon, style: const TextStyle(fontSize: 15)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.period.label,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        c.narrative,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (c != withData.last) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _PredictionsCard extends StatelessWidget {
  final PredictionBundle bundle;
  const _PredictionsCard({required this.bundle});

  @override
  Widget build(BuildContext context) {
    final habitRisk = bundle.habitDrops.isNotEmpty ? bundle.habitDrops.first : null;
    return GlassCard(
      borderGradient: AppColors.primaryGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("محرك التوقعات", style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _RiskRow(label: "احتمال نجاح اليوم", value: bundle.dayOutcome.successProbability),
          const SizedBox(height: 8),
          _RiskRow(label: "احتمال فشل اليوم", value: bundle.dayOutcome.failureProbability),
          if (habitRisk != null) ...[
            const SizedBox(height: 8),
            _RiskRow(
              label: "احتمال ترك عادة \"${habitRisk.title}\"",
              value: habitRisk.dropProbability,
            ),
          ],
          if (bundle.returnPrediction.isCurrentlyAbsent) ...[
            const SizedBox(height: 8),
            _RiskRow(
              label: "احتمال العودة بعد الانقطاع",
              value: bundle.returnPrediction.returnProbability,
            ),
          ],
          const SizedBox(height: 8),
          _RiskRow(label: "احتمال الإرهاق", value: bundle.fatigue.fatigueProbability),
          const SizedBox(height: 8),
          _RiskRow(label: "احتمال الاحتراق الذهني", value: bundle.burnout.burnoutProbability),
          if (bundle.solutions.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(color: AppColors.glassFill, height: 1),
            const SizedBox(height: 12),
            ...bundle.solutions.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.icon, style: const TextStyle(fontSize: 15)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          s.text,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12.5,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

class _RiskRow extends StatelessWidget {
  final String label;
  final int value;
  const _RiskRow({required this.label, required this.value});

  Color get _color => value >= 65 ? AppColors.danger : (value >= 35 ? AppColors.warning : AppColors.success);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            Text("$value%", style: TextStyle(color: _color, fontWeight: FontWeight.w600, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: value / 100,
            minHeight: 6,
            backgroundColor: AppColors.glassFill,
            valueColor: AlwaysStoppedAnimation(_color),
          ),
        ),
      ],
    );
  }
}

class _PatternsCard extends StatelessWidget {
  final List<PatternInsight> patterns;
  const _PatternsCard({required this.patterns});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("أنماط سلوكية مكتشفة", style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          ...patterns.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.icon, style: const TextStyle(fontSize: 15)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(p.text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.5)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _ReasonsCard extends StatelessWidget {
  final List<HiddenReason> reasons;
  const _ReasonsCard({required this.reasons});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderGradient: AppColors.primaryGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("لماذا يحدث هذا؟", style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          ...reasons.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.icon, style: const TextStyle(fontSize: 15)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(r.text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.5)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _TodayProgressCard extends StatelessWidget {
  final double rate;
  const _TodayProgressCard({required this.rate});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("إنجاز اليوم", style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: rate,
              minHeight: 10,
              backgroundColor: AppColors.glassFill,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "${(rate * 100).toStringAsFixed(0)}% من مهام اليوم مكتملة",
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

class _QuickStatsRow extends StatelessWidget {
  final int pendingTasks;
  final int activeHabits;
  const _QuickStatsRow({required this.pendingTasks, required this.activeHabits});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GlassCard(
            child: Column(
              children: [
                Text("$pendingTasks", style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 4),
                const Text("مهام اليوم", style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GlassCard(
            child: Column(
              children: [
                Text("$activeHabits", style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 4),
                const Text("عادات نشطة", style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
