import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/ai_service.dart';
import '../../viewmodels/auth_view_model.dart';
import '../../viewmodels/tracker_view_model.dart';
import '../../viewmodels/profile_view_model.dart';
import '../../main.dart';

class AICardWidget extends StatefulWidget {
  const AICardWidget({super.key});

  @override
  State<AICardWidget> createState() => _AICardWidgetState();
}

class _AICardWidgetState extends State<AICardWidget> {
  final AIService _aiService = AIService();
  String _advice =
      "Нажмите кнопку, чтобы получить персональный совет на основе ваших данных.";
  bool _isLoading = false;

  Future<void> _generateAdvice() async {
    final authVM = context.read<AuthViewModel>();
    final trackerVM = context.read<TrackerViewModel>();
    final user = context.read<ProfileViewModel>().user;

    if (!authVM.isLoggedIn || authVM.auth?.token == null || user == null) {
      return;
    }

    setState(() => _isLoading = true);

    String goalText = "поддержание веса";
    if (user.weightGoal == 'lose') goalText = "похудение";
    if (user.weightGoal == 'gain') goalText = "набор массы";

    final int calNorm = trackerVM.calculateDailyCalorieGoal(user);
    final int waterNorm = trackerVM.calculateDailyWaterGoal(user);
    final double sleepNorm = user.sleepNorm;

    double avgCal = 0;
    if (trackerVM.stableWeeklyCalories.isNotEmpty) {
      avgCal =
          trackerVM.stableWeeklyCalories.fold(
            0.0,
            (sum, spot) => sum + spot.y,
          ) /
          7;
    }
    double avgSleep = 0;
    if (trackerVM.stableWeeklySleep.isNotEmpty) {
      avgSleep =
          trackerVM.stableWeeklySleep.fold(0.0, (sum, spot) => sum + spot.y) /
          7;
    }
    final int todayCal = trackerVM.totalEntryCalories;
    final int todayWater = trackerVM.totalEntryWater;
    final double todaySleep = trackerVM.totalEntrySleep;

    final prompt =
        "Я пользователь приложения здоровья. Моя цель: $goalText. "
        "Мои нормы: Калории $calNorm, Вода $waterNorm мл, Сон $sleepNorm ч. "
        "Сегодня: Еда $todayCal ккал, Вода $todayWater мл, Сон $todaySleep ч. "
        "В среднем за неделю: Еда ${avgCal.round()} ккал, Сон ${avgSleep.toStringAsFixed(1)} ч. "
        "Настроение сегодня: ${trackerVM.avgEntryMood.toStringAsFixed(1)}/5. "
        "Дай 1 короткий, полезный совет (макс 2 предложения) на русском, учитывая мои нормы и тренды.";

    try {
      final result = await _aiService.getAdvice(authVM.auth!.token, prompt);
      if (mounted) {
        setState(() => _advice = result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ошибка получения совета")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.white),
              SizedBox(width: 10),
              Text(
                "AI Тренер",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),

          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _isLoading
                ? const Center(
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : Text(
                    _advice,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
          ),

          const SizedBox(height: 15),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isLoading ? null : _generateAdvice,
              child: const Text("Получить совет"),
            ),
          ),
        ],
      ),
    );
  }
}
