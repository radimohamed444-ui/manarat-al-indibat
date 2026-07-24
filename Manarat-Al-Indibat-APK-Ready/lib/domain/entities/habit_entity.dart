import 'package:equatable/equatable.dart';

enum HabitType { positive, negative }

enum HabitDifficulty { easy, medium, hard }

/// A single day's log entry for a habit.
class HabitLogEntity extends Equatable {
  final DateTime date;
  final bool success;
  final String? triggerNote; // for negative habits: what triggered it
  final int? hourOfDay; // for pattern analysis

  const HabitLogEntity({
    required this.date,
    required this.success,
    this.triggerNote,
    this.hourOfDay,
  });

  @override
  List<Object?> get props => [date, success, triggerNote, hourOfDay];
}

class HabitEntity extends Equatable {
  final String id;
  final String title;
  final String? description;
  final HabitType type;
  final HabitDifficulty difficulty;
  final String? reminderTime; // "HH:mm"
  final DateTime createdAt;
  final List<HabitLogEntity> logs;

  const HabitEntity({
    required this.id,
    required this.title,
    this.description,
    this.type = HabitType.positive,
    this.difficulty = HabitDifficulty.medium,
    this.reminderTime,
    required this.createdAt,
    this.logs = const [],
  });

  int get currentStreak {
    if (logs.isEmpty) return 0;
    final sorted = [...logs]..sort((a, b) => b.date.compareTo(a.date));
    int streak = 0;
    DateTime cursor = DateTime.now();
    for (final log in sorted) {
      final sameDay = log.date.year == cursor.year &&
          log.date.month == cursor.month &&
          log.date.day == cursor.day;
      final expectedSuccess = type == HabitType.positive ? true : true; // avoiding it counts as success for negative habits too
      if (sameDay && log.success == expectedSuccess) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
      } else if (sameDay) {
        break;
      } else {
        break;
      }
    }
    return streak;
  }

  double get successRate {
    if (logs.isEmpty) return 0;
    final successes = logs.where((l) => l.success).length;
    return successes / logs.length;
  }

  /// Behavior Engine input: most frequent hour this (negative) habit occurs,
  /// used to detect triggers and time-box interventions.
  int? get mostFrequentTriggerHour {
    if (type != HabitType.negative) return null;
    final failures = logs.where((l) => !l.success && l.hourOfDay != null);
    if (failures.isEmpty) return null;
    final counts = <int, int>{};
    for (final f in failures) {
      counts[f.hourOfDay!] = (counts[f.hourOfDay!] ?? 0) + 1;
    }
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  HabitEntity copyWith({
    String? title,
    String? description,
    HabitType? type,
    HabitDifficulty? difficulty,
    String? reminderTime,
    List<HabitLogEntity>? logs,
  }) {
    return HabitEntity(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      difficulty: difficulty ?? this.difficulty,
      reminderTime: reminderTime ?? this.reminderTime,
      createdAt: createdAt,
      logs: logs ?? this.logs,
    );
  }

  @override
  List<Object?> get props =>
      [id, title, description, type, difficulty, reminderTime, createdAt, logs];
}
