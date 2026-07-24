import "package:flutter/material.dart";
import "../../../../core/theme/app_colors.dart";
import "../../../../domain/entities/scheduled_task_entity.dart";
import "../../../viewmodels/schedule_viewmodel.dart";

void showAddScheduledTaskSheet(BuildContext context, ScheduleViewModel vm) {
  final titleCtrl = TextEditingController();
  final noteCtrl = TextEditingController();
  int hour = TimeOfDay.now().hour;
  SchedPriority priority = SchedPriority.medium;

  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surfaceElevated,
    isScrollControlled: true,
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
            const Text("مهمة جديدة في الجدول", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            TextField(
              controller: titleCtrl,
              autofocus: true,
              decoration: const InputDecoration(hintText: "عنوان المهمة"),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text("الساعة:", style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(width: 12),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(ctx).copyWith(activeTrackColor: AppColors.primary),
                    child: Slider(
                      value: hour.toDouble(),
                      min: 0,
                      max: 23,
                      divisions: 23,
                      label: "$hour:00",
                      onChanged: (v) => setState(() => hour = v.round()),
                    ),
                  ),
                ),
                SizedBox(width: 44, child: Text("$hour:00", textAlign: TextAlign.end)),
              ],
            ),
            const SizedBox(height: 8),
            SegmentedButton<SchedPriority>(
              segments: const [
                ButtonSegment(value: SchedPriority.low, label: Text("منخفضة")),
                ButtonSegment(value: SchedPriority.medium, label: Text("متوسطة")),
                ButtonSegment(value: SchedPriority.high, label: Text("عالية")),
              ],
              selected: {priority},
              onSelectionChanged: (s) => setState(() => priority = s.first),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(hintText: "ملاحظة (اختياري)"),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (titleCtrl.text.trim().isEmpty) return;
                  vm.addTask(
                    title: titleCtrl.text.trim(),
                    hour: hour,
                    priority: priority,
                    note: noteCtrl.text.trim(),
                  );
                  Navigator.pop(ctx);
                },
                child: const Text("إضافة للجدول"),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
