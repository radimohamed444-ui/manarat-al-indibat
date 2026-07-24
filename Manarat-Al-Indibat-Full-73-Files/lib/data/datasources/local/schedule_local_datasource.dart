import "package:hive/hive.dart";
import "../../models/scheduled_task_model.dart";
import "../../models/task_log_entry_model.dart";
import "../../../core/constants/app_constants.dart";

/// Hive-backed data source for the daily schedule system.
/// Three boxes, mirroring the original `S.sched.base`,
/// `S.sched.overrides`, and `S.log`:
///   - boxScheduleBase: id -> ScheduledTaskModel
///   - boxScheduleOverrides: "0".."6" -> List<ScheduledTaskModel>
///   - boxDayLogs: dayKey -> DayLogModel
class ScheduleLocalDataSource {
  Box<ScheduledTaskModel> get _baseBox =>
      Hive.box<ScheduledTaskModel>(AppConstants.boxScheduleBase);
  Box get _overridesBox => Hive.box(AppConstants.boxScheduleOverrides);
  Box<DayLogModel> get _dayLogsBox => Hive.box<DayLogModel>(AppConstants.boxDayLogs);

  // ── base schedule ──
  List<ScheduledTaskModel> getBase() => _baseBox.values.toList()
    ..sort((a, b) => a.hour.compareTo(b.hour));

  Future<void> setBase(List<ScheduledTaskModel> tasks) async {
    await _baseBox.clear();
    for (final t in tasks) {
      await _baseBox.put(t.id, t);
    }
  }

  Future<void> putBaseTask(ScheduledTaskModel task) => _baseBox.put(task.id, task);
  Future<void> deleteBaseTask(String id) => _baseBox.delete(id);

  // ── weekday overrides ──
  List<ScheduledTaskModel>? getOverride(int weekday) {
    final raw = _overridesBox.get(weekday.toString());
    if (raw == null) return null;
    return (raw as List).cast<ScheduledTaskModel>();
  }

  Future<void> setOverride(int weekday, List<ScheduledTaskModel> tasks) =>
      _overridesBox.put(weekday.toString(), tasks);

  Future<void> clearOverride(int weekday) => _overridesBox.delete(weekday.toString());

  /// Mirrors `getSchedForDay()`: override if present & non-empty, else base.
  List<ScheduledTaskModel> getScheduleForDay(int weekday) {
    final ov = getOverride(weekday);
    if (ov != null && ov.isNotEmpty) return ov..sort((a, b) => a.hour.compareTo(b.hour));
    return getBase();
  }

  // ── day logs ──
  DayLogModel? getDayLogRaw(String dayKey) => _dayLogsBox.get(dayKey);

  Map<String, TaskLogEntryModel> getDayLog(String dayKey) =>
      _dayLogsBox.get(dayKey)?.entries ?? {};

  Future<void> setTaskStatus(String dayKey, String taskId, TaskLogEntryModel entry) async {
    final existing = _dayLogsBox.get(dayKey) ?? DayLogModel(dayKey: dayKey, entries: {});
    existing.entries[taskId] = entry;
    await _dayLogsBox.put(dayKey, existing);
  }

  Map<String, DayLogModel> getAllDayLogs() {
    final map = <String, DayLogModel>{};
    for (final key in _dayLogsBox.keys) {
      map[key as String] = _dayLogsBox.get(key)!;
    }
    return map;
  }

  Stream<Map<String, TaskLogEntryModel>> watchDayLog(String dayKey) async* {
    yield getDayLog(dayKey);
    yield* _dayLogsBox.watch(key: dayKey).map((_) => getDayLog(dayKey));
  }
}
