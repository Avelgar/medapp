import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import 'tracker_view_model.dart';
import '../models/user_profile.dart';

class NotificationViewModel extends ChangeNotifier {
  final NotificationService _service = NotificationService();

  Future<void> init(Future<void> Function(String?) onNotificationClick) async {
    await _service.init(onNotificationClick);
  }

  Future<void> onSleepStart(TrackerViewModel tracker, UserProfile user) async {
    await cancelAllAwakeReminders();
    await _planWakeUpNotifications(tracker, user);
  }

  Future<void> onWakeUp(TrackerViewModel tracker, UserProfile user) async {
    await _cancelWakeUpNotifications();
    await _sendImmediateWakeUpAlerts(tracker, user);
    await _planAwakeNotifications(tracker, user);
  }

  Future<void> onDataAdded(TrackerViewModel tracker, UserProfile user) async {
    if (tracker.isSleeping) return;

    await _planFoodReminders(tracker, user);
    await _planWaterReminders(tracker, user);
  }

  Future<void> _planAwakeNotifications(
    TrackerViewModel tracker,
    UserProfile user,
  ) async {
    await _planFoodReminders(tracker, user);
    await _planWaterReminders(tracker, user);
    await _planSportReminders();
    await _planGoToSleepReminders(tracker, user);
  }

  Future<void> _planFoodReminders(
    TrackerViewModel tracker,
    UserProfile user,
  ) async {
    for (int i = 100; i < 200; i++) {
      await _service.cancel(i);
    }

    final lastFood =
        tracker.lastCalorieTime ??
        DateTime.now().subtract(const Duration(hours: 4));

    DateTime nextFoodTime = lastFood.add(const Duration(hours: 4));

    if (nextFoodTime.isBefore(DateTime.now())) {
      nextFoodTime = DateTime.now().add(const Duration(minutes: 15));
    }

    int calNorm = tracker.calculateDailyCalorieGoal(user);
    int snackSize = (calNorm / 4).round();

    for (int i = 0; i < 3; i++) {
      await _service.scheduleNotification(
        id: 100 + i,
        title: "Пора подкрепиться!",
        body: _getFoodMessage(snackSize, i),
        scheduledDate: nextFoodTime.add(Duration(hours: i)),
        payload: 'calories',
      );
    }
  }

  Future<void> _planWaterReminders(
    TrackerViewModel tracker,
    UserProfile user,
  ) async {
    for (int i = 200; i < 300; i++) {
      await _service.cancel(i);
    }

    final lastWater =
        tracker.lastWaterTime ??
        DateTime.now().subtract(const Duration(hours: 2));
    DateTime nextWaterTime = lastWater.add(const Duration(hours: 2));

    if (nextWaterTime.isBefore(DateTime.now())) {
      nextWaterTime = DateTime.now().add(const Duration(minutes: 10));
    }

    int waterNorm = tracker.calculateDailyWaterGoal(user);
    int cupSize = (waterNorm / 8).round();

    for (int i = 0; i < 3; i++) {
      await _service.scheduleNotification(
        id: 200 + i,
        title: "Водный баланс",
        body: _getWaterMessage(cupSize, i),
        scheduledDate: nextWaterTime.add(Duration(hours: i)),
        payload: 'water',
      );
    }
  }

  Future<void> _planSportReminders() async {
    for (int i = 400; i < 500; i++) {
      await _service.cancel(i);
    }

    final now = DateTime.now();

    await _service.scheduleNotification(
      id: 400,
      title: "Время движения!",
      body: "Разминка 5 минут зарядит энергией.",
      scheduledDate: now.add(const Duration(hours: 2)),
      payload: 'activity',
    );
    await _service.scheduleNotification(
      id: 401,
      title: "Спорт-брейк",
      body: "Как насчет небольшой прогулки?",
      scheduledDate: now.add(const Duration(hours: 6)),
      payload: 'activity',
    );
    await _service.scheduleNotification(
      id: 402,
      title: "Вечерняя активность",
      body: "Закройте кольца активности сегодня!",
      scheduledDate: now.add(const Duration(hours: 10)),
      payload: 'activity',
    );
  }

  Future<void> _planGoToSleepReminders(
    TrackerViewModel tracker,
    UserProfile user,
  ) async {
    for (int i = 300; i < 400; i++) {
      await _service.cancel(i);
    }

    double sleepDebt = tracker.getAverageSleepDeficit(user.sleepNorm);
    double awakeLimitHours = 16.0 - sleepDebt;
    if (awakeLimitHours < 12) {
      awakeLimitHours = 12;
    }

    DateTime wakeUpTime = DateTime.now();
    DateTime bedTime = wakeUpTime.add(
      Duration(minutes: (awakeLimitHours * 60).round()),
    );

    for (int i = 0; i < 5; i++) {
      await _service.scheduleNotification(
        id: 300 + i,
        title: "Пора спать!",
        body: _getSleepMessage((awakeLimitHours + i).round()),
        scheduledDate: bedTime.add(Duration(hours: i)),
        payload: 'sleep',
      );
    }
  }

  Future<void> _planWakeUpNotifications(
    TrackerViewModel tracker,
    UserProfile user,
  ) async {
    DateTime sleepStart = DateTime.now();
    double norm = user.sleepNorm;
    DateTime wakeTime = sleepStart.add(Duration(minutes: (norm * 60).round()));

    for (int i = 0; i < 5; i++) {
      await _service.scheduleNotification(
        id: 500 + i,
        title: "Доброе утро!",
        body: i == 0
            ? "Вы выспали свою норму ($norm ч). Пора вставать!"
            : "Хватит валяться! День проходит!",
        scheduledDate: wakeTime.add(Duration(hours: i)),
        payload: 'sleep',
      );
    }
  }

  Future<void> cancelAllAwakeReminders() async {
    for (int i = 100; i < 500; i++) {
      await _service.cancel(i);
    }
  }

  Future<void> _cancelWakeUpNotifications() async {
    for (int i = 500; i < 600; i++) {
      await _service.cancel(i);
    }
  }

  Future<void> _sendImmediateWakeUpAlerts(
    TrackerViewModel tracker,
    UserProfile user,
  ) async {
    int calNorm = tracker.calculateDailyCalorieGoal(user);
    int waterNorm = tracker.calculateDailyWaterGoal(user);

    await _service.showInstantNotification(
      id: 901,
      title: "С пробуждением!",
      body:
          "Вы долго не ели. Съешьте ${(calNorm / 4).round()} ккал. Например, овсянку или омлет.",
      payload: 'calories',
    );

    await Future.delayed(const Duration(seconds: 2));

    await _service.showInstantNotification(
      id: 902,
      title: "Вода",
      body:
          "Организм обезвожен. Выпейте ${(waterNorm / 8).round()} мл воды или чаю.",
      payload: 'water',
    );
    await Future.delayed(const Duration(seconds: 2));

    await _service.showInstantNotification(
      id: 903,
      title: "Зарядка",
      body: "Сделайте легкую разминку!",
      payload: 'activity',
    );
  }

  String _getFoodMessage(int amount, int index) {
    if (index == 0) {
      return "Вам нужно перекусить (~$amount ккал). Это может быть йогурт с орехами.";
    }
    if (index == 1) {
      return "Вы пропустили перекус! Энергия падает. Съешьте ~$amount ккал.";
    }
    return "SOS! Организм начинает есть сам себя! Срочно поешьте!";
  }

  String _getWaterMessage(int amount, int index) {
    if (index == 0) {
      return "Время пить! Выпейте ~$amount мл воды или зеленого чая.";
    }
    if (index == 1) return "Пустыня Сахара отдыхает. Выпейте воды!";
    return "Вы превращаетесь в изюм. СРОЧНО ВОДЫ!";
  }

  String _getSleepMessage(int hoursAwake) {
    if (hoursAwake < 18) {
      return "Вы бодрствуете уже $hoursAwake ч. Пора восстановить силы.";
    }
    if (hoursAwake < 24) {
      return "Глаза закрываются... Идите в кровать, $hoursAwake ч без сна это много.";
    }
    if (hoursAwake < 30) return "Вы не спите $hoursAwake часов. Вы зомби?";
    return "Вы не спите уже $hoursAwake часов, вы труп... 💀";
  }
}
