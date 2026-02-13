class SleepRecord extends TrackerRecord {
  final DateTime startTime;
  final DateTime endTime;

  SleepRecord({
    required super.id,
    required super.date,
    required this.startTime,
    required this.endTime,
  });

  double get duration {
    final diff = endTime.difference(startTime).inMinutes;
    return diff / 60.0;
  }

  factory SleepRecord.fromMap(Map<String, dynamic> map) {
    return SleepRecord(
      id: map['id'],
      date: DateTime.parse(map['datetime']),
      startTime: DateTime.parse(map['start_time']),
      endTime: DateTime.parse(map['end_time']),
    );
  }
}

class TrackerRecord {
  final int id;
  final DateTime date;
  TrackerRecord({required this.id, required this.date});
}

class CalorieRecord extends TrackerRecord {
  final int calories;
  CalorieRecord({
    required super.id,
    required super.date,
    required this.calories,
  });
  factory CalorieRecord.fromMap(Map<String, dynamic> map) {
    return CalorieRecord(
      id: map['id'],
      date: DateTime.parse(map['datetime']),
      calories: map['calories'],
    );
  }
}

class WaterRecord extends TrackerRecord {
  final int amount;
  WaterRecord({required super.id, required super.date, required this.amount});
  factory WaterRecord.fromMap(Map<String, dynamic> map) {
    return WaterRecord(
      id: map['id'],
      date: DateTime.parse(map['datetime']),
      amount: map['amount_ml'],
    );
  }
}

class MoodRecord extends TrackerRecord {
  final int score;
  MoodRecord({required super.id, required super.date, required this.score});
  factory MoodRecord.fromMap(Map<String, dynamic> map) {
    return MoodRecord(
      id: map['id'],
      date: DateTime.parse(map['datetime']),
      score: map['score'],
    );
  }
}

class ActivityRecord extends TrackerRecord {
  final String sportName;
  final int minutes;
  final double met;
  ActivityRecord({
    required super.id,
    required super.date,
    required this.sportName,
    required this.minutes,
    required this.met,
  });
  factory ActivityRecord.fromMap(Map<String, dynamic> map) {
    return ActivityRecord(
      id: map['id'],
      date: DateTime.parse(map['datetime']),
      sportName: map['sport_name'],
      minutes: map['minutes'],
      met: map['met'],
    );
  }
}
