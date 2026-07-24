class AppConstants {
  AppConstants._();

  static const String appNameAr = 'منارة الانضباط';
  static const String appNameEn = 'Manarat Al-Indibat';

  /// Shadow Mode: silent behavioral observation window before the app
  /// starts offering advice, nudges, or judgments.
  static const int shadowModeDays = 14;

  // Hive box identifiers
  static const String boxTasks = 'box_tasks';
  static const String boxHabits = 'box_habits';
  static const String boxHabitLogs = 'box_habit_logs';
  static const String boxGoals = 'box_goals';
  static const String boxBehaviorEvents = 'box_behavior_events';
  static const String boxBehaviorProfile = 'box_behavior_profile';
  static const String boxSettings = 'box_settings';
  static const String boxScheduleBase = 'box_schedule_base';
  static const String boxScheduleOverrides = 'box_schedule_overrides';
  static const String boxDayLogs = 'box_day_logs';

  // SharedPreferences keys (lightweight flags only)
  static const String prefFirstLaunchDate = 'pref_first_launch_date';
  static const String prefOnboardingComplete = 'pref_onboarding_complete';
  static const String prefThemeMode = 'pref_theme_mode';
}
