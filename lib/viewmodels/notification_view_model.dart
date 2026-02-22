import 'dart:math';
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
    final random = Random();

    final titles1 = ["Время движения!", "Разомнемся?", "Легкая пауза"];
    final bodies1 = [
      "Разминка 5 минут зарядит энергией.",
      "Потянитесь и сделайте пару глубоких вдохов.",
      "Встаньте со стула на пару минут.",
    ];

    final titles2 = ["Спорт-брейк", "Время активности", "Разогрев"];
    final bodies2 = [
      "Как насчет небольшой прогулки?",
      "Пройдитесь по лестнице или сделайте приседания.",
      "Тело скажет спасибо за 10 минут ходьбы.",
    ];

    final titles3 = [
      "Вечерняя активность",
      "Закрываем кольца",
      "Финальный рывок",
    ];
    final bodies3 = [
      "Закройте кольца активности сегодня!",
      "Отличный момент для вечерней растяжки или йоги.",
      "Пройдитесь перед сном, это улучшит отдых.",
    ];

    await _service.scheduleNotification(
      id: 400,
      title: titles1[random.nextInt(titles1.length)],
      body: bodies1[random.nextInt(bodies1.length)],
      scheduledDate: now.add(const Duration(hours: 2)),
      payload: 'activity',
    );

    await _service.scheduleNotification(
      id: 401,
      title: titles2[random.nextInt(titles2.length)],
      body: bodies2[random.nextInt(bodies2.length)],
      scheduledDate: now.add(const Duration(hours: 6)),
      payload: 'activity',
    );

    await _service.scheduleNotification(
      id: 402,
      title: titles3[random.nextInt(titles3.length)],
      body: bodies3[random.nextInt(bodies3.length)],
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
    final random = Random();

    if (index == 0) {
      final messages = [
        "Вам нужно перекусить (~$amount ккал). Это может быть йогурт с орехами.",
        "Время подкрепиться! Цель: ~$amount ккал. Как насчет фрукта или батончика?",
        "Ваш метаболизм ждет топлива! Съешьте что-нибудь на ~$amount ккал.",
        "Пора кушать! Оптимальная порция сейчас — около ~$amount ккал.",
        "Не забывайте питаться регулярно. Сейчас самое время для ~$amount ккал.",
      ];
      return messages[random.nextInt(messages.length)];
    }

    if (index == 1) {
      final messages = [
        "Вы пропустили перекус! Энергия падает. Съешьте ~$amount ккал.",
        "Уровень глюкозы снижается. Пожалуйста, найдите время на ~$amount ккал.",
        "Ваш организм просит еды! Желательно закинуть ~$amount ккал прямо сейчас.",
        "Тревога! Батарейка садится. Срочная подзарядка на ~$amount ккал!",
        "Вы слишком увлеклись делами. Сделайте паузу и съешьте ~$amount ккал.",
      ];
      return messages[random.nextInt(messages.length)];
    }

    final messages = [
      "SOS! Организм начинает есть сам себя! Срочно поешьте!",
      "Внимание! Внутренний голодный зверь проснулся и требует еды! 🦖",
      "Если вы сейчас же не поедите, ваш желудок объявит забастовку!",
      "Критический уровень энергии! Бросайте всё и бегите к холодильнику!",
      "Вы превращаетесь в голодного зомби. Спасите себя и окружающих — поешьте!",
    ];
    return messages[random.nextInt(messages.length)];
  }

  String _getWaterMessage(int amount, int index) {
    final random = Random();

    if (index == 0) {
      final messages = [
        "Время пить! Выпейте ~$amount мл воды или зеленого чая.",
        "Водный баланс сам себя не поддержит. Нужно ~$amount мл.",
        "Глоток свежести! Пора выпить ~$amount мл воды.",
        "Тело просит воды. Около ~$amount мл будут в самый раз.",
        "Немного чистой воды (~$amount мл) для ясного ума!",
      ];
      return messages[random.nextInt(messages.length)];
    }

    if (index == 1) {
      final messages = [
        "Пустыня Сахара отдыхает. Выпейте воды! (~$amount мл)",
        "Вы пропустили стакан воды. Восполните баланс: ~$amount мл.",
        "Клетки высыхают! Пора срочно выпить ~$amount мл воды.",
        "Ваш организм работает всухую. Нужно ~$amount мл прямо сейчас.",
        "Обезвоживание близко. Срочно выпейте ~$amount мл.",
      ];
      return messages[random.nextInt(messages.length)];
    }

    final messages = [
      "Вы превращаетесь в изюм. СРОЧНО ВОДЫ!",
      "Тревога! Уровень жидкости критически низок. Воду в студию!",
      "Мозг усыхает без воды! Выпейте хоть стакан немедленно!",
      "Кактус бы позавидовал вашей выдержке, но вы человек. Пейте!",
      "Организм подает сигнал SOS. Вода — это жизнь, не забывайте!",
    ];
    return messages[random.nextInt(messages.length)];
  }

  String _getSleepMessage(int hoursAwake) {
    final random = Random();

    if (hoursAwake < 18) {
      final messages = [
        "Вы бодрствуете уже $hoursAwake ч. Пора восстановить силы.",
        "День был долгим ($hoursAwake ч). Готовьтесь ко сну.",
        "Пора замедляться. Вы на ногах уже $hoursAwake часов.",
        "Мелатонин вырабатывается! Идеальное время лечь в кровать.",
        "Кровать скучает по вам. Прошло $hoursAwake ч с момента пробуждения.",
      ];
      return messages[random.nextInt(messages.length)];
    }

    if (hoursAwake < 24) {
      final messages = [
        "Глаза закрываются... Идите в кровать, $hoursAwake ч без сна это много.",
        "Переутомление близко. Вы не спите $hoursAwake ч. Отдыхайте!",
        "Мозг требует перезагрузки. Срочно в постель!",
        "Сон — лучшее лекарство, а вы пропустили прием. $hoursAwake ч бодрствования!",
        "Вы работаете на резервных батареях. Пора спать.",
      ];
      return messages[random.nextInt(messages.length)];
    }

    if (hoursAwake < 30) {
      final messages = [
        "Вы не спите $hoursAwake часов. Вы зомби?",
        "Критический недосып! $hoursAwake часов без сна разрушают организм.",
        "Вам срочно нужна подушка. Не издевайтесь над собой!",
        "Система перегружена. Экстренное выключение через 3.. 2.. 1..",
        "Вы бьете рекорды, которые не стоит бить. Идите спать!",
      ];
      return messages[random.nextInt(messages.length)];
    }

    final messages = [
      "Вы не спите уже $hoursAwake часов, вы труп... 💀",
      "Сбой матрицы. Человек не может не спать $hoursAwake часов.",
      "Пинг до реальности слишком высокий. Срочно в спящий режим!",
      "Если вы это читаете, значит вам пора к врачу или в кровать.",
      "Даже совы спят. А вы не спите $hoursAwake часов. Спокойной ночи!",
    ];
    return messages[random.nextInt(messages.length)];
  }
}
