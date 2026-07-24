import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "../../../core/widgets/glass_card.dart";
import "../../../core/theme/app_colors.dart";
import "../../../domain/entities/task_entity.dart";
import "../../viewmodels/task_viewmodel.dart";
import "../../../core/di/injection.dart";

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => sl<TaskViewModel>(),
      child: const _TasksBody(),
    );
  }
}

class _TasksBody extends StatelessWidget {
  const _TasksBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TaskViewModel>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text("المهام")),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
        onPressed: () => _showAddTaskSheet(context, vm),
        child: const Icon(Icons.add),
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : vm.tasks.isEmpty
              ? const Center(
                  child: Text(
                    "لا توجد مهام بعد — أضف أول مهمة لك",
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: vm.tasks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final task = vm.tasks[i];
                    return _TaskCard(task: task, vm: vm);
                  },
                ),
    );
  }

  void _showAddTaskSheet(BuildContext context, TaskViewModel vm) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
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
            const Text("مهمة جديدة", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(hintText: "عنوان المهمة"),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (controller.text.trim().isEmpty) return;
                  vm.addTask(title: controller.text.trim(), deadline: DateTime.now());
                  Navigator.pop(ctx);
                },
                child: const Text("إضافة"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final TaskEntity task;
  final TaskViewModel vm;
  const _TaskCard({required this.task, required this.vm});

  @override
  Widget build(BuildContext context) {
    final isDone = task.status == TaskStatus.completed;
    return GlassCard(
      onTap: () => vm.completeTask(task.id),
      child: Row(
        children: [
          Icon(
            isDone ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isDone ? AppColors.success : AppColors.textMuted,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    color: isDone ? AppColors.textMuted : AppColors.textPrimary,
                  ),
                ),
                if (task.shouldSuggestDecomposition)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      "أُجّلت هذه المهمة عدة مرات — جرّب تقسيمها لخطوات أصغر",
                      style: TextStyle(color: AppColors.warning, fontSize: 11.5),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.textMuted, size: 20),
            onPressed: () => vm.deleteTask(task.id),
          ),
        ],
      ),
    );
  }
}
