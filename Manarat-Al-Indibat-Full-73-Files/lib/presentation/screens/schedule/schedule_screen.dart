import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "../../../core/widgets/glass_card.dart";
import "../../../core/theme/app_colors.dart";
import "../../../core/utils/day_key.dart";
import "../../../domain/entities/scheduled_task_entity.dart";
import "../../../domain/entities/task_log_entry.dart";
import "../../viewmodels/schedule_viewmodel.dart";
import "../../../core/di/injection.dart";
import "widgets/add_scheduled_task_sheet.dart";

/// The Today screen — a faithful port of renderToday(): the effective
/// hourly schedule for the current weekday, joined with today's
/// completion log. This is the actual daily-driver screen of the app,
/// not a generic to-do list.
class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => sl<ScheduleViewModel>(),
      child: const _ScheduleBody(),
    );
  }
}

class _ScheduleBody extends StatelessWidget {
  const _ScheduleBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ScheduleViewModel>();
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text("اليوم · ${dayNamesAr[jsWeekday(now)]}"),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
        onPressed: () => showAddScheduledTaskSheet(context, vm),
        child: const Icon(Icons.add),
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: _TodayProgressBar(rate: vm.completionRate),
                ),
                Expanded(
                  child: vm.todaySchedule.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              "لا يوجد جدول بعد لهذا اليوم — أضف أول مهمة بوقتها المحدد.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                          itemCount: vm.todaySchedule.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final task = vm.todaySchedule[i];
                            return _ScheduledTaskCard(task: task, vm: vm);
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class _TodayProgressBar extends StatelessWidget {
  final double rate;
  const _TodayProgressBar({required this.rate});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: rate,
                minHeight: 8,
                backgroundColor: AppColors.glassFill,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text("${(rate * 100).round()}%", style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ScheduledTaskCard extends StatelessWidget {
  final ScheduledTaskEntity task;
  final ScheduleViewModel vm;
  const _ScheduledTaskCard({required this.task, required this.vm});

  Color get _priorityColor => switch (task.priority) {
        SchedPriority.high => AppColors.danger,
        SchedPriority.medium => AppColors.warning,
        SchedPriority.low => AppColors.textMuted,
      };

  @override
  Widget build(BuildContext context) {
    final status = vm.statusFor(task.id).status;
    final isDone = status == DayTaskStatus.done;
    final isFailed = status == DayTaskStatus.failed;
    final isSkipped = status == DayTaskStatus.skipped;

    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 44,
            alignment: Alignment.center,
            child: Column(
              children: [
                Text(
                  formatHour(task.hour).split(" ").first,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                Text(
                  formatHour(task.hour).split(" ").last,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                ),
              ],
            ),
          ),
          Container(width: 3, height: 34, margin: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(color: _priorityColor, borderRadius: BorderRadius.circular(4))),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    decoration: isDone || isSkipped ? TextDecoration.lineThrough : null,
                    color: isDone
                        ? AppColors.textMuted
                        : (isFailed ? AppColors.danger : AppColors.textPrimary),
                  ),
                ),
                if (task.note.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(task.note,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5)),
                  ),
              ],
            ),
          ),
          if (status == DayTaskStatus.pending) ...[
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.danger, size: 20),
              onPressed: () => vm.failTask(task),
            ),
            IconButton(
              icon: const Icon(Icons.check_circle, color: AppColors.success, size: 22),
              onPressed: () => vm.completeTask(task),
            ),
          ] else
            Icon(
              isDone ? Icons.check_circle : (isFailed ? Icons.cancel : Icons.remove_circle_outline),
              color: isDone ? AppColors.success : (isFailed ? AppColors.danger : AppColors.textMuted),
            ),
        ],
      ),
    );
  }
}
