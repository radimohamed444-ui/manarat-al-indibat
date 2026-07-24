import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:uuid/uuid.dart";
import "../../../core/widgets/glass_card.dart";
import "../../../core/theme/app_colors.dart";
import "../../../domain/entities/habit_entity.dart";
import "../../viewmodels/habit_viewmodel.dart";
import "../../../core/di/injection.dart";

class HabitsScreen extends StatelessWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => sl<HabitViewModel>(),
      child: const _HabitsBody(),
    );
  }
}

class _HabitsBody extends StatelessWidget {
  const _HabitsBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HabitViewModel>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text("العادات")),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.secondary,
        onPressed: () => _showAddHabitSheet(context, vm),
        child: const Icon(Icons.add),
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : vm.habits.isEmpty
              ? const Center(
                  child: Text(
                    "لا توجد عادات بعد",
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: vm.habits.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _HabitCard(habit: vm.habits[i], vm: vm),
                ),
    );
  }

  void _showAddHabitSheet(BuildContext context, HabitViewModel vm) {
    final controller = TextEditingController();
    HabitType type = HabitType.positive;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("عادة جديدة", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(hintText: "اسم العادة"),
              ),
              const SizedBox(height: 12),
              SegmentedButton<HabitType>(
                segments: const [
                  ButtonSegment(value: HabitType.positive, label: Text("إيجابية")),
                  ButtonSegment(value: HabitType.negative, label: Text("سلبية")),
                ],
                selected: {type},
                onSelectionChanged: (s) => setState(() => type = s.first),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (controller.text.trim().isEmpty) return;
                    vm.createHabit(HabitEntity(
                      id: const Uuid().v4(),
                      title: controller.text.trim(),
                      type: type,
                      createdAt: DateTime.now(),
                    ));
                    Navigator.pop(ctx);
                  },
                  child: const Text("إضافة"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HabitCard extends StatelessWidget {
  final HabitEntity habit;
  final HabitViewModel vm;
  const _HabitCard({required this.habit, required this.vm});

  @override
  Widget build(BuildContext context) {
    final isNegative = habit.type == HabitType.negative;
    return GlassCard(
      child: Row(
        children: [
          Icon(
            isNegative ? Icons.block : Icons.local_fire_department,
            color: isNegative ? AppColors.danger : AppColors.tertiary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(habit.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  "سلسلة ${habit.currentStreak} يوم · نجاح ${(habit.successRate * 100).toStringAsFixed(0)}%",
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.danger, size: 20),
                onPressed: () => vm.logToday(habit.id, false),
              ),
              IconButton(
                icon: const Icon(Icons.check, color: AppColors.success, size: 20),
                onPressed: () => vm.logToday(habit.id, true),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
