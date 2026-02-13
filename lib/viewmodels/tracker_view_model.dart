import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/tracker_records.dart';
import '../models/user_profile.dart';
import '../services/database_helper.dart';
import '../services/storage_service.dart';

enum ChartPeriod { day, week, month }

class TrackerViewModel extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final StorageService _storage = StorageService();

  static final Map<String, double> sportsDictionary = {
    'Йога / Растяжка': 2.5,
    'Ходьба (4 км/ч)': 3.0,
    'Качалка (Силовая)': 3.5,
    'Ходьба быстрая': 4.3,
    'Плавание': 6.0,
    'Футбол / Игры': 7.0,
    'Велосипед': 7.5,
    'Бег / HIIT': 8.0,
    'Бег быстрый': 10.0,
  };

  DateTime _entryDate = DateTime.now();
  DateTime _dashboardDate = DateTime.now();
  ChartPeriod _selectedPeriod = ChartPeriod.week;

  String? _pendingDialogType;
  String? get pendingDialogType => _pendingDialogType;

  void setPendingDialog(String type) {
    _pendingDialogType = type;
    notifyListeners();
  }

  void clearPendingDialog() {
    _pendingDialogType = null;
  }

  List<CalorieRecord> _entryCalories = [];
  List<WaterRecord> _entryWater = [];
  List<SleepRecord> _entrySleep = [];
  List<MoodRecord> _entryMood = [];
  List<ActivityRecord> _entryActivity = [];

  bool _isSleeping = false;
  DateTime? _sleepStartTime;

  int _dashboardCalories = 0;
  int _dashboardWater = 0;
  double _dashboardSleep = 0;
  double _dashboardMood = 0;
  double _dashboardActivity = 0;

  List<FlSpot> _chartCalories = [];
  List<FlSpot> _chartWater = [];
  List<FlSpot> _chartSleep = [];
  List<FlSpot> _chartMood = [];
  List<FlSpot> _chartActivity = [];

  List<FlSpot> _stableWeeklyCalories = [];
  List<FlSpot> _stableWeeklyWater = [];
  List<FlSpot> _stableWeeklySleep = [];
  List<FlSpot> _stableWeeklyMood = [];
  List<FlSpot> _stableWeeklyActivity = [];

  // --- ГЕТТЕРЫ ДЛЯ УВЕДОМЛЕНИЙ ---

  DateTime? get lastCalorieTime {
    if (_entryCalories.isEmpty) return null;
    final sorted = List<CalorieRecord>.from(_entryCalories);
    sorted.sort((a, b) => b.date.compareTo(a.date));
    return sorted.first.date;
  }

  DateTime? get lastWaterTime {
    if (_entryWater.isEmpty) return null;
    final sorted = List<WaterRecord>.from(_entryWater);
    sorted.sort((a, b) => b.date.compareTo(a.date));
    return sorted.first.date;
  }

  double getAverageSleepDeficit(double norm) {
    if (_stableWeeklySleep.isEmpty) return 0;
    double totalDuration = 0;
    for (var s in _stableWeeklySleep) {
      totalDuration += s.y;
    }
    double avg = totalDuration / 7;
    double deficit = norm - avg;
    return deficit > 0 ? deficit : 0;
  }

  // --- ОСТАЛЬНЫЕ ГЕТТЕРЫ ---
  DateTime get entryDate => _entryDate;
  DateTime get dashboardDate => _dashboardDate;
  ChartPeriod get selectedPeriod => _selectedPeriod;
  List<CalorieRecord> get calorieRecords => _entryCalories;
  List<WaterRecord> get waterRecords => _entryWater;
  List<SleepRecord> get sleepRecords => _entrySleep;
  List<MoodRecord> get moodRecords => _entryMood;
  List<ActivityRecord> get activityRecords => _entryActivity;
  bool get isSleeping => _isSleeping;
  DateTime? get sleepStartTime => _sleepStartTime;
  int get dashboardCalories => _dashboardCalories;
  int get dashboardWater => _dashboardWater;
  double get dashboardSleep => _dashboardSleep;
  double get dashboardMood => _dashboardMood;
  double get dashboardActivity => _dashboardActivity;
  List<FlSpot> get weeklyCalories => _chartCalories;
  List<FlSpot> get weeklyWater => _chartWater;
  List<FlSpot> get weeklySleep => _chartSleep;
  List<FlSpot> get weeklyMood => _chartMood;
  List<FlSpot> get weeklyActivity => _chartActivity;
  List<FlSpot> get stableWeeklyCalories => _stableWeeklyCalories;
  List<FlSpot> get stableWeeklyWater => _stableWeeklyWater;
  List<FlSpot> get stableWeeklySleep => _stableWeeklySleep;
  List<FlSpot> get stableWeeklyMood => _stableWeeklyMood;
  List<FlSpot> get stableWeeklyActivity => _stableWeeklyActivity;
  int get totalEntryCalories =>
      _entryCalories.fold(0, (sum, item) => sum + item.calories);
  int get totalEntryWater =>
      _entryWater.fold(0, (sum, item) => sum + item.amount);
  double get totalEntrySleep =>
      _entrySleep.fold(0.0, (sum, item) => sum + item.duration);
  double get avgEntryMood {
    if (_entryMood.isEmpty) return 0;
    final sum = _entryMood.fold(0, (sum, item) => sum + item.score);
    return sum / _entryMood.length;
  }

  double get dailyMetMinutes =>
      _entryActivity.fold(0.0, (sum, item) => sum + (item.met * item.minutes));
  double get totalEntryActivity => dailyMetMinutes;

  Future<void> loadData() async {
    await checkSleepStatus();
    await loadEntryData();
    await loadDashboardData();
    await loadStableWeeklyStats();
  }

  Future<void> checkSleepStatus() async {
    _sleepStartTime = await _storage.getSleepStart();
    _isSleeping = _sleepStartTime != null;
    notifyListeners();
  }

  Future<void> startSleepSession() async {
    final now = DateTime.now();
    await _storage.saveSleepStart(now);
    _sleepStartTime = now;
    _isSleeping = true;
    notifyListeners();
  }

  int calculateAverageWeeklyCalorieGoal(UserProfile? user) {
    if (user == null) return 0;
    double avgMetMinutes = 0;
    if (_stableWeeklyActivity.isNotEmpty) {
      double sum = _stableWeeklyActivity.fold(
        0.0,
        (prev, spot) => prev + spot.y,
      );
      avgMetMinutes = sum / 7;
    }
    double effectiveMETs = avgMetMinutes < 100 ? 100 : avgMetMinutes;
    double activityBurn = (effectiveMETs * user.weight) / 60;

    double base = (user.bmr * 1.2) + activityBurn;

    return (base * _getGoalMultiplier(user.weightGoal)).round();
  }

  Future<void> endSleepSession() async {
    if (_sleepStartTime == null) return;
    final endTime = DateTime.now();
    if (endTime.difference(_sleepStartTime!).inMinutes > 0) {
      await _dbHelper.insertSleep(_sleepStartTime!, endTime);
    }
    await _storage.clearSleepStart();
    _sleepStartTime = null;
    _isSleeping = false;
    await _refreshAll();
  }

  void setEntryDate(DateTime date) {
    _entryDate = date;
    loadEntryData();
  }

  void setDashboardDate(DateTime date) {
    _dashboardDate = date;
    loadDashboardData();
  }

  void setChartPeriod(ChartPeriod period) {
    _selectedPeriod = period;
    loadDashboardData();
  }

  Future<void> loadEntryData() async {
    final calMaps = await _dbHelper.getCaloriesForDay(_entryDate);
    _entryCalories = calMaps.map((e) => CalorieRecord.fromMap(e)).toList();
    final waterMaps = await _dbHelper.getWaterForDay(_entryDate);
    _entryWater = waterMaps.map((e) => WaterRecord.fromMap(e)).toList();
    final sleepMaps = await _dbHelper.getSleepForDay(_entryDate);
    _entrySleep = sleepMaps.map((e) => SleepRecord.fromMap(e)).toList();
    final moodMaps = await _dbHelper.getMoodForDay(_entryDate);
    _entryMood = moodMaps.map((e) => MoodRecord.fromMap(e)).toList();
    final actMaps = await _dbHelper.getActivityForDay(_entryDate);
    _entryActivity = actMaps.map((e) => ActivityRecord.fromMap(e)).toList();
    notifyListeners();
  }

  Future<void> loadStableWeeklyStats() async {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final start = end
        .subtract(const Duration(days: 6))
        .copyWith(hour: 0, minute: 0, second: 0);

    final calRaw = await _dbHelper.getRecordsForRange(
      'Calories_Records',
      start,
      end,
    );
    _stableWeeklyCalories = _processDailySum(calRaw, start, 'calories', 7);
    final waterRaw = await _dbHelper.getRecordsForRange(
      'Water_Records',
      start,
      end,
    );
    _stableWeeklyWater = _processDailySum(waterRaw, start, 'amount_ml', 7);
    final sleepRaw = await _dbHelper.getRecordsForRange(
      'Sleep_Records',
      start,
      end,
    );
    List<Map<String, dynamic>> sleepProcessed = sleepRaw.map((e) {
      final rec = SleepRecord.fromMap(e);
      return {'datetime': e['datetime'], 'duration': rec.duration};
    }).toList();
    _stableWeeklySleep = _processDailySum(sleepProcessed, start, 'duration', 7);
    final moodRaw = await _dbHelper.getRecordsForRange(
      'Mood_Records',
      start,
      end,
    );
    _stableWeeklyMood = _processDailyAvg(moodRaw, start, 'score', 7);
    final actRaw = await _dbHelper.getRecordsForRange(
      'Activity_Records',
      start,
      end,
    );
    _stableWeeklyActivity = _processDailyMetMinutes(actRaw, start, 7);
  }

  Future<void> loadDashboardData() async {
    final calMaps = await _dbHelper.getCaloriesForDay(_dashboardDate);
    _dashboardCalories = calMaps.fold(
      0,
      (sum, e) => sum + (e['calories'] as int),
    );
    final waterMaps = await _dbHelper.getWaterForDay(_dashboardDate);
    _dashboardWater = waterMaps.fold(
      0,
      (sum, e) => sum + (e['amount_ml'] as int),
    );
    final sleepMaps = await _dbHelper.getSleepForDay(_dashboardDate);
    _dashboardSleep = sleepMaps
        .map((e) => SleepRecord.fromMap(e))
        .fold(0.0, (sum, rec) => sum + rec.duration);
    final moodMaps = await _dbHelper.getMoodForDay(_dashboardDate);
    _dashboardMood = moodMaps.isEmpty
        ? 0
        : moodMaps.fold(0, (sum, e) => sum + (e['score'] as int)) /
              moodMaps.length;
    final actMaps = await _dbHelper.getActivityForDay(_dashboardDate);
    _dashboardActivity = actMaps.fold(
      0.0,
      (sum, e) => sum + ((e['met'] as num) * (e['minutes'] as num)),
    );

    DateTime start;
    DateTime end = DateTime(
      _dashboardDate.year,
      _dashboardDate.month,
      _dashboardDate.day,
      23,
      59,
      59,
    );

    if (_selectedPeriod == ChartPeriod.day) {
      start = DateTime(end.year, end.month, end.day, 0, 0, 0);
    } else if (_selectedPeriod == ChartPeriod.month) {
      start = end
          .subtract(const Duration(days: 29))
          .copyWith(hour: 0, minute: 0, second: 0);
    } else {
      start = end
          .subtract(const Duration(days: 6))
          .copyWith(hour: 0, minute: 0, second: 0);
    }

    final calRaw = await _dbHelper.getRecordsForRange(
      'Calories_Records',
      start,
      end,
    );
    final waterRaw = await _dbHelper.getRecordsForRange(
      'Water_Records',
      start,
      end,
    );
    final sleepRaw = await _dbHelper.getRecordsForRange(
      'Sleep_Records',
      start,
      end,
    );
    final moodRaw = await _dbHelper.getRecordsForRange(
      'Mood_Records',
      start,
      end,
    );
    final actRaw = await _dbHelper.getRecordsForRange(
      'Activity_Records',
      start,
      end,
    );

    if (_selectedPeriod == ChartPeriod.day) {
      _chartCalories = _processHourlyData(calRaw, 'calories');
      _chartWater = _processHourlyData(waterRaw, 'amount_ml');
      _chartSleep = _processHourlySleepIntervals(sleepRaw, _dashboardDate);
      _chartMood = _processHourlyData(moodRaw, 'score');
      _chartActivity = _processHourlyMetMinutes(actRaw);
    } else {
      int daysCount = _selectedPeriod == ChartPeriod.month ? 30 : 7;
      _chartCalories = _processDailySum(calRaw, start, 'calories', daysCount);
      _chartWater = _processDailySum(waterRaw, start, 'amount_ml', daysCount);
      List<Map<String, dynamic>> sleepProcessed = sleepRaw.map((e) {
        final rec = SleepRecord.fromMap(e);
        return {'datetime': e['datetime'], 'duration': rec.duration};
      }).toList();
      _chartSleep = _processDailySum(
        sleepProcessed,
        start,
        'duration',
        daysCount,
      );
      _chartMood = _processDailyAvg(moodRaw, start, 'score', daysCount);
      _chartActivity = _processDailyMetMinutes(actRaw, start, daysCount);
    }

    await loadStableWeeklyStats();
    notifyListeners();
  }

  List<FlSpot> _processHourlySleepIntervals(
    List<Map<String, dynamic>> rawData,
    DateTime targetDay,
  ) {
    List<SleepRecord> records = rawData
        .map((e) => SleepRecord.fromMap(e))
        .toList();
    List<FlSpot> spots = [];
    for (int hour = 0; hour <= 23; hour++) {
      DateTime hourStart = DateTime(
        targetDay.year,
        targetDay.month,
        targetDay.day,
        hour,
        0,
      );
      DateTime hourEnd = DateTime(
        targetDay.year,
        targetDay.month,
        targetDay.day,
        hour,
        59,
        59,
      );
      double value = 0.0;
      for (var rec in records) {
        if (rec.startTime.isBefore(hourEnd) && rec.endTime.isAfter(hourStart)) {
          value = 1.0;
          break;
        }
      }
      spots.add(FlSpot(hour.toDouble(), value));
    }
    return spots;
  }

  int _calculateTargetEAT(UserProfile? user) {
    if (user == null) return 0;
    double actualMETs = _dashboardActivity;
    double effectiveMETs = actualMETs < 100 ? 100 : actualMETs;
    double caloriesBurned = (effectiveMETs * user.weight) / 60;
    return caloriesBurned.round();
  }

  double _getGoalMultiplier(String goal) {
    switch (goal) {
      case 'lose':
        return 0.85;
      case 'gain':
        return 1.15;
      default:
        return 1.0;
    }
  }

  int calculateDailyCalorieGoal(UserProfile? user) {
    if (user == null) return 0;
    int targetEat = _calculateTargetEAT(user);
    double base = (user.bmr * 1.2) + targetEat;
    return (base * _getGoalMultiplier(user.weightGoal)).round();
  }

  int calculateDailyWaterGoal(UserProfile? user) {
    if (user == null) return 2000;
    int targetEat = _calculateTargetEAT(user);
    double additive = (targetEat / 100.0) * 200;
    double base = user.baseWaterNorm + additive;
    return (base * _getGoalMultiplier(user.weightGoal)).round();
  }

  int _calculateBaseEAT(UserProfile? user) {
    if (user == null) return 0;
    const double baseMETs = 100.0;
    double caloriesBurned = (baseMETs * user.weight) / 60;
    return caloriesBurned.round();
  }

  double calculateBaseCalorieGraphNorm(UserProfile? user) {
    if (user == null) return 0;
    double base = (user.bmr * 1.2) + _calculateBaseEAT(user);
    return base * _getGoalMultiplier(user.weightGoal);
  }

  double calculateBaseWaterGraphNorm(UserProfile? user) {
    if (user == null) return 0;
    double base = user.baseWaterNorm + (_calculateBaseEAT(user) * 2);
    return base * _getGoalMultiplier(user.weightGoal);
  }

  DateTime _getTimestampForRecord() {
    final now = DateTime.now();
    return DateTime(
      _entryDate.year,
      _entryDate.month,
      _entryDate.day,
      now.hour,
      now.minute,
    );
  }

  Future<void> _refreshAll() async {
    await loadEntryData();
    await loadDashboardData();
  }

  Future<void> addSleep(DateTime start, DateTime end) async {
    await _dbHelper.insertSleep(start, end);
    await _refreshAll();
  }

  Future<void> updateSleep(int id, DateTime start, DateTime end) async {
    await _dbHelper.updateSleep(id, start, end);
    await _refreshAll();
  }

  Future<void> deleteSleep(int id) async {
    await _dbHelper.deleteSleep(id);
    await _refreshAll();
  }

  Future<void> addCalories(int cal) async {
    await _dbHelper.insertCalories(cal, _getTimestampForRecord());
    await _refreshAll();
  }

  Future<void> updateCalories(int id, int cal) async {
    await _dbHelper.updateCalories(id, cal);
    await _refreshAll();
  }

  Future<void> deleteCalories(int id) async {
    await _dbHelper.deleteCalories(id);
    await _refreshAll();
  }

  Future<void> addWater(int ml) async {
    await _dbHelper.insertWater(ml, _getTimestampForRecord());
    await _refreshAll();
  }

  Future<void> updateWater(int id, int ml) async {
    await _dbHelper.updateWater(id, ml);
    await _refreshAll();
  }

  Future<void> deleteWater(int id) async {
    await _dbHelper.deleteWater(id);
    await _refreshAll();
  }

  Future<void> addMood(int score) async {
    await _dbHelper.insertMood(score, _getTimestampForRecord());
    await _refreshAll();
  }

  Future<void> updateMood(int id, int score) async {
    await _dbHelper.updateMood(id, score);
    await _refreshAll();
  }

  Future<void> deleteMood(int id) async {
    await _dbHelper.deleteMood(id);
    await _refreshAll();
  }

  Future<void> addActivity(String name, int mins, double met) async {
    await _dbHelper.insertActivity(name, mins, met, _getTimestampForRecord());
    await _refreshAll();
  }

  Future<void> updateActivity(int id, String name, int mins, double met) async {
    await _dbHelper.updateActivity(id, name, mins, met);
    await _refreshAll();
  }

  Future<void> deleteActivity(int id) async {
    await _dbHelper.deleteActivity(id);
    await _refreshAll();
  }

  List<FlSpot> _processHourlyData(
    List<Map<String, dynamic>> rawData,
    String key,
  ) {
    Map<int, double> hourlyMap = {};
    for (var i = 0; i <= 24; i++) {
      hourlyMap[i] = 0;
    }
    for (var rec in rawData) {
      final date = DateTime.parse(rec['datetime']);
      final val = (rec[key] as num).toDouble();
      hourlyMap[date.hour] = (hourlyMap[date.hour] ?? 0) + val;
    }
    List<FlSpot> spots = [];
    hourlyMap.forEach((hour, value) {
      spots.add(FlSpot(hour.toDouble(), value));
    });
    return spots;
  }

  List<FlSpot> _processHourlyMetMinutes(List<Map<String, dynamic>> rawData) {
    Map<int, double> hourlyMap = {};
    for (var i = 0; i <= 24; i++) {
      hourlyMap[i] = 0;
    }
    for (var rec in rawData) {
      final date = DateTime.parse(rec['datetime']);
      final val = (rec['met'] as num) * (rec['minutes'] as num);
      hourlyMap[date.hour] = (hourlyMap[date.hour] ?? 0) + val;
    }
    return hourlyMap.entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();
  }

  List<FlSpot> _processDailySum(
    List<Map<String, dynamic>> rawData,
    DateTime start,
    String valueKey,
    int daysCount,
  ) {
    List<FlSpot> spots = [];
    for (int i = 0; i < daysCount; i++) {
      final currentDay = start.add(Duration(days: i));
      final records = rawData.where((row) {
        final d = DateTime.parse(row['datetime']);
        return d.year == currentDay.year &&
            d.month == currentDay.month &&
            d.day == currentDay.day;
      });
      double sum = 0;
      for (var r in records) {
        sum += (r[valueKey] as num).toDouble();
      }
      spots.add(FlSpot(i.toDouble(), sum));
    }
    return spots;
  }

  List<FlSpot> _processDailyAvg(
    List<Map<String, dynamic>> rawData,
    DateTime start,
    String valueKey,
    int daysCount,
  ) {
    List<FlSpot> spots = [];
    for (int i = 0; i < daysCount; i++) {
      final currentDay = start.add(Duration(days: i));
      final records = rawData.where((row) {
        final d = DateTime.parse(row['datetime']);
        return d.year == currentDay.year &&
            d.month == currentDay.month &&
            d.day == currentDay.day;
      });
      double avg = 0;
      if (records.isNotEmpty) {
        double sum = 0;
        for (var r in records) {
          sum += (r[valueKey] as num).toDouble();
        }
        avg = sum / records.length;
      }
      spots.add(FlSpot(i.toDouble(), avg));
    }
    return spots;
  }

  List<FlSpot> _processDailyMetMinutes(
    List<Map<String, dynamic>> rawData,
    DateTime start,
    int daysCount,
  ) {
    List<FlSpot> spots = [];
    for (int i = 0; i < daysCount; i++) {
      final currentDay = start.add(Duration(days: i));
      final records = rawData.where((row) {
        final d = DateTime.parse(row['datetime']);
        return d.year == currentDay.year &&
            d.month == currentDay.month &&
            d.day == currentDay.day;
      });
      double sumMetMins = 0;
      for (var r in records) {
        sumMetMins += (r['met'] as num) * (r['minutes'] as num);
      }
      spots.add(FlSpot(i.toDouble(), sumMetMins));
    }
    return spots;
  }
}
