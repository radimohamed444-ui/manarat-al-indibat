import "package:equatable/equatable.dart";

/// One day's aggregate — ported 1:1 from computeStats(): {key, date,
/// done, failed, total, rate}.
class DayStat extends Equatable {
  final String key; // yyyy-MM-dd
  final DateTime date;
  final int done;
  final int failed;
  final int total;
  final double rate;

  const DayStat({
    required this.key,
    required this.date,
    required this.done,
    required this.failed,
    required this.total,
    required this.rate,
  });

  @override
  List<Object?> get props => [key, date, done, failed, total, rate];
}
