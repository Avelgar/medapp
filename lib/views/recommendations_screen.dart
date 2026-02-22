import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../viewmodels/profile_view_model.dart';
import '../viewmodels/tracker_view_model.dart';
import '../models/user_profile.dart';
import '../viewmodels/auth_view_model.dart';
import 'widgets/ai_card.dart';

class RecommendationsScreen extends StatelessWidget {
  const RecommendationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profileVM = context.watch<ProfileViewModel>();
    final trackerVM = context.watch<TrackerViewModel>();
    final user = profileVM.user;
    final isPremium = context.watch<AuthViewModel>().isPremium;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Нет данных профиля")));
    }

    final double heightM = user.height / 100.0;
    final double bmi = (heightM > 0) ? user.weight / pow(heightM, 2) : 0;
    final double minIdealWeight = 18.5 * pow(heightM, 2);
    final double maxIdealWeight = 24.9 * pow(heightM, 2);

    String status = "Норма";
    Color statusColor = Colors.green;
    if (bmi < 18.5) {
      status = "Дефицит";
      statusColor = Colors.orange;
    } else if (bmi > 25 && bmi <= 29.9) {
      status = "Избыток";
      statusColor = Colors.orange;
    } else if (bmi > 29.9) {
      status = "Ожирение";
      statusColor = Colors.red;
    }

    double getAvg(List<dynamic> list) =>
        list.isEmpty ? 0 : list.fold(0.0, (sum, spot) => sum + spot.y) / 7;

    final double avgCal = getAvg(trackerVM.stableWeeklyCalories);
    final double normCal = trackerVM
        .calculateAverageWeeklyCalorieGoal(user)
        .toDouble();
    final double avgWater = getAvg(trackerVM.stableWeeklyWater);
    final double normWater = trackerVM.calculateDailyWaterGoal(user).toDouble();
    final double avgSleep = getAvg(trackerVM.stableWeeklySleep);
    final double normSleep = user.sleepNorm;
    final double avgMood = getAvg(trackerVM.stableWeeklyMood);
    final double avgSport = getAvg(trackerVM.stableWeeklyActivity);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Анализ здоровья',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isPremium)
              const AICardWidget()
            else
              _buildPremiumPromo(theme, isDark),
            const SizedBox(height: 30),

            const Text(
              "Моё тело",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Индекс массы (BMI)",
                          style: TextStyle(
                            color: theme.textTheme.bodySmall?.color,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              bmi.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 60,
                    width: 60,
                    child: CircularProgressIndicator(
                      value: (bmi / 40).clamp(0.0, 1.0),
                      color: statusColor,
                      backgroundColor: isDark
                          ? Colors.grey.shade800
                          : Colors.grey.shade100,
                      strokeWidth: 6,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.stars, color: Colors.blue, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    "Идеальный вес: ${minIdealWeight.round()} - ${maxIdealWeight.round()} кг",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            Row(
              children: [
                Expanded(
                  child: _buildMiniCard(
                    theme,
                    "Вес",
                    "${user.weight} кг",
                    Icons.monitor_weight,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMiniCard(
                    theme,
                    "Рост",
                    "${user.height} см",
                    Icons.height,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMiniCard(
                    theme,
                    "Возраст",
                    "${user.age} лет",
                    Icons.cake,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            Text(
              "Ваша цель:",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  _buildToggleBtn(
                    context,
                    theme,
                    isDark,
                    user,
                    "Похудение",
                    "lose",
                    Colors.orange,
                  ),
                  _buildToggleBtn(
                    context,
                    theme,
                    isDark,
                    user,
                    "Норма",
                    "maintain",
                    Colors.green,
                  ),
                  _buildToggleBtn(
                    context,
                    theme,
                    isDark,
                    user,
                    "Набор",
                    "gain",
                    Colors.blue,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              "В среднем за неделю",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            _buildHabitRow(
              theme,
              isDark,
              "Питание",
              "${avgCal.round()} / ${normCal.round()}",
              "ккал",
              Icons.local_fire_department,
              Colors.orange,
              avgCal / normCal,
            ),
            _buildHabitRow(
              theme,
              isDark,
              "Вода",
              "${avgWater.round()} / ${normWater.round()}",
              "мл",
              Icons.water_drop,
              Colors.blue,
              avgWater / normWater,
            ),
            _buildHabitRow(
              theme,
              isDark,
              "Сон",
              "${avgSleep.toStringAsFixed(1)} / ${normSleep.toStringAsFixed(1)}",
              "ч",
              Icons.bedtime,
              Colors.indigo,
              avgSleep / normSleep,
            ),
            _buildHabitRow(
              theme,
              isDark,
              "Настроение",
              avgMood.toStringAsFixed(1),
              "/ 5.0",
              Icons.emoji_emotions,
              Colors.green,
              avgMood / 5.0,
            ),
            _buildHabitRow(
              theme,
              isDark,
              "Активность",
              "${avgSport.round()} / 100",
              "MET",
              Icons.fitness_center,
              Colors.purple,
              (avgSport / 100).clamp(0.0, 1.0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniCard(
    ThemeData theme,
    String title,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.grey.shade400, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(
            title,
            style: TextStyle(
              color: theme.textTheme.bodySmall?.color,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleBtn(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    UserProfile user,
    String title,
    String value,
    Color activeColor,
  ) {
    final bool isSelected = user.weightGoal == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          final updatedUser = user.copyWith(weightGoal: value);
          context.read<ProfileViewModel>().saveUserProfile(updatedUser);
          context.read<TrackerViewModel>().loadData();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.grey.shade600 : Colors.grey.shade400),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHabitRow(
    ThemeData theme,
    bool isDark,
    String title,
    String val,
    String unit,
    IconData icon,
    Color color,
    double percent,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(fontFamily: 'Roboto'),
                        children: [
                          TextSpan(
                            text: val,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                          TextSpan(
                            text: " $unit",
                            style: TextStyle(
                              color: theme.textTheme.bodySmall?.color,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percent.isNaN ? 0.0 : percent.clamp(0.0, 1.0),
                    backgroundColor: isDark
                        ? Colors.grey.shade800
                        : Colors.grey.shade100,
                    color: color,
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumPromo(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock, color: Colors.orange),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "AI Аналитика",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  "Разблокируйте Premium для персональных советов",
                  style: TextStyle(
                    color: theme.textTheme.bodySmall?.color,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
