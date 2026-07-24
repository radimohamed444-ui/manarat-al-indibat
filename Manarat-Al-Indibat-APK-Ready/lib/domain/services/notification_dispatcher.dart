/// Abstraction the domain layer talks to for delivering *actual* local
/// notifications — kept in `domain` (no Flutter import) so
/// [NotificationIntelligenceEngine] stays pure-Dart and unit-testable
/// with a fake, exactly like [BehaviorEngine] and [PredictionEngine].
/// The real implementation ([NotificationService] in `core/services`)
/// wraps `flutter_local_notifications` + `permission_handler` +
/// `timezone`.
abstract class NotificationDispatcher {
  /// Fire a notification immediately.
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    String? channelId,
  });

  /// Schedule a one-off notification at a specific local time. If the
  /// time has already passed today, implementations should either skip
  /// silently or roll to the next day, at the caller's discretion via
  /// [rollToNextDayIfPast].
  Future<void> scheduleAt({
    required int id,
    required DateTime when,
    required String title,
    required String body,
    String? channelId,
    bool rollToNextDayIfPast = true,
  });

  /// Cancel a previously scheduled/shown notification by id.
  Future<void> cancel(int id);

  /// True if the OS-level notification permission is currently granted.
  Future<bool> hasPermission();

  /// Requests the OS-level notification permission (Android 13+ POST_
  /// NOTIFICATIONS, iOS alert/badge/sound). Returns the granted state.
  Future<bool> requestPermission();
}

/// A no-op dispatcher used in tests and in any environment where
/// notification delivery isn't available/desired (keeps the engine
/// callable without a live Flutter plugin).
class NoopNotificationDispatcher implements NotificationDispatcher {
  final List<String> sent = [];

  @override
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    String? channelId,
  }) async {
    sent.add("show:$id:$title");
  }

  @override
  Future<void> scheduleAt({
    required int id,
    required DateTime when,
    required String title,
    required String body,
    String? channelId,
    bool rollToNextDayIfPast = true,
  }) async {
    sent.add("schedule:$id:$title@$when");
  }

  @override
  Future<void> cancel(int id) async {}

  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<bool> requestPermission() async => true;
}
