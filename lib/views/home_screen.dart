import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import '../viewmodels/profile_view_model.dart';
import '../viewmodels/tracker_view_model.dart';
import '../main.dart';
import 'profile_screen.dart';
import 'widgets/chart_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TrackerViewModel>().loadDashboardData();
    });
  }

  void _navigateToEntry(BuildContext context, String type) {
    final trackerVM = context.read<TrackerViewModel>();
    trackerVM.setEntryDate(trackerVM.dashboardDate);
    trackerVM.setPendingDialog(type);
    context.read<PageViewModel>().setPage(2);
  }

  Future<void> _pickDate(BuildContext context) async {
    final vm = context.read<TrackerViewModel>();
    final picked = await showDatePicker(
      context: context,
      initialDate: vm.dashboardDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale("ru", "RU"),
    );
    if (picked != null) {
      vm.setDashboardDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileVM = context.watch<ProfileViewModel>();
    final trackerVM = context.watch<TrackerViewModel>();
    final user = profileVM.user;
    final ChartPeriod period = trackerVM.selectedPeriod;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final int todayCal = trackerVM.dashboardCalories;
    final int todayCalNorm = trackerVM.calculateDailyCalorieGoal(user);
    final int todayWater = trackerVM.dashboardWater;
    final int todayWaterNorm = trackerVM.calculateDailyWaterGoal(user);
    final double todaySleep = trackerVM.dashboardSleep;
    final double todayMood = trackerVM.dashboardMood;
    final double todayActivity = trackerVM.dashboardActivity;
    const double todayActivityNorm = 100.0;

    final double graphCalNorm = trackerVM.calculateBaseCalorieGraphNorm(user);
    final double graphWaterNorm = trackerVM.calculateBaseWaterGraphNorm(user);
    final double graphSleepNorm = user.sleepNorm;
    const double graphMoodNorm = 3.0;
    const double graphActivityNorm = 100.0;

    final isToday = DateUtils.isSameDay(
      trackerVM.dashboardDate,
      DateTime.now(),
    );
    final dateText = isToday
        ? "Сегодня, ${DateFormat('d MMMM', 'ru').format(trackerVM.dashboardDate)}"
        : DateFormat('d MMMM yyyy', 'ru').format(trackerVM.dashboardDate);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Доброе утро,",
                        style: TextStyle(
                          color:
                              theme.textTheme.bodySmall?.color ??
                              AppColors.textSec,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        user.name,
                        style: TextStyle(
                          color: theme.textTheme.bodyLarge?.color,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, Color(0xFF9D4EDD)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors
                            .transparent, // Делаем прозрачным, чтобы было видно градиент
                        child: Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : "?",
                          style: const TextStyle(
                            fontSize: 22,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),
              GestureDetector(
                onTap: () => _pickDate(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.transparent
                            : Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_month,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        dateText,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Icon(
                        Icons.keyboard_arrow_down,
                        color:
                            theme.textTheme.bodySmall?.color ??
                            AppColors.textSec,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                "Прогресс дня",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              _buildArcCard(
                theme: theme,
                isDark: isDark,
                title: "Калории",
                value: "$todayCal",
                subValue: "из $todayCalNorm ккал",
                percent: (todayCal / (todayCalNorm == 0 ? 1 : todayCalNorm))
                    .clamp(0.0, 1.0),
                color: Colors.orange,
                icon: Icons.local_fire_department,
                onTap: () => _navigateToEntry(context, 'calories'),
                isBig: true,
              ),

              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: _buildArcCard(
                      theme: theme,
                      isDark: isDark,
                      title: "Вода",
                      value: "$todayWater",
                      subValue: "из $todayWaterNorm мл",
                      percent:
                          (todayWater /
                                  (todayWaterNorm == 0 ? 1 : todayWaterNorm))
                              .clamp(0.0, 1.0),
                      color: Colors.blue,
                      icon: Icons.water_drop,
                      onTap: () => _navigateToEntry(context, 'water'),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildArcCard(
                      theme: theme,
                      isDark: isDark,
                      title: "Сон",
                      value: todaySleep.toStringAsFixed(1),
                      subValue: "из ${user.sleepNorm} ч",
                      percent: (todaySleep / user.sleepNorm).clamp(0.0, 1.0),
                      color: Colors.indigo,
                      icon: Icons.bedtime,
                      onTap: () => _navigateToEntry(context, 'sleep'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: _buildArcCard(
                      theme: theme,
                      isDark: isDark,
                      title: "Настроение",
                      value: todayMood.toStringAsFixed(1),
                      subValue: "из 5",
                      percent: (todayMood / 5.0).clamp(0.0, 1.0),
                      color: Colors.green,
                      icon: Icons.emoji_emotions,
                      onTap: () => _navigateToEntry(context, 'mood'),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildArcCard(
                      theme: theme,
                      isDark: isDark,
                      title: "Спорт",
                      value: todayActivity.round().toString(),
                      subValue: "из $todayActivityNorm MET",
                      percent: (todayActivity / todayActivityNorm).clamp(
                        0.0,
                        1.0,
                      ),
                      color: Colors.purple,
                      icon: Icons.fitness_center,
                      onTap: () => _navigateToEntry(context, 'activity'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              const Text(
                "Подробная статистика",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              _buildPeriodSelector(trackerVM),
              const SizedBox(height: 20),

              _buildChartSection(
                "Калории",
                trackerVM.weeklyCalories,
                Colors.orange,
                graphCalNorm,
                period,
              ),
              _buildChartSection(
                "Вода",
                trackerVM.weeklyWater,
                Colors.blue,
                graphWaterNorm,
                period,
              ),
              _buildChartSection(
                "Сон",
                trackerVM.weeklySleep,
                Colors.indigo,
                graphSleepNorm,
                period,
              ),
              _buildChartSection(
                "Настроение",
                trackerVM.weeklyMood,
                Colors.green,
                graphMoodNorm,
                period,
                maxY: 5,
              ),
              _buildChartSection(
                "Активность",
                trackerVM.weeklyActivity,
                Colors.purple,
                graphActivityNorm,
                period,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArcCard({
    required ThemeData theme,
    required bool isDark,
    required String title,
    required String value,
    required String subValue,
    required double percent,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
    bool isBig = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          // Добавляем еле заметную обводку для премиального вида
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.transparent
                  : Colors.black.withValues(alpha: 0.04), // Тень мягче
              blurRadius: 20, // Радиус размытия больше
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Icon(icon, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 15),
            SizedBox(
              height: isBig ? 160 : 100,
              width: double.infinity,
              child: CustomPaint(
                painter: ArcPainter(
                  percent: percent,
                  color: color,
                  bgColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 30),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          value,
                          style: TextStyle(
                            fontSize: isBig ? 36 : 24,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.bodyLarge?.color,
                            height: 1,
                          ),
                        ),
                        Text(
                          subValue,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(TrackerViewModel vm) {
    return SegmentedButton<ChartPeriod>(
      segments: const [
        ButtonSegment(value: ChartPeriod.day, label: Text('День')),
        ButtonSegment(value: ChartPeriod.week, label: Text('Неделя')),
        ButtonSegment(value: ChartPeriod.month, label: Text('Месяц')),
      ],
      selected: {vm.selectedPeriod},
      onSelectionChanged: (Set<ChartPeriod> newSelection) {
        vm.setChartPeriod(newSelection.first);
      },
      style: const ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildChartSection(
    String title,
    List<FlSpot> points,
    Color color,
    double norm,
    ChartPeriod period, {
    double? maxY,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: ChartCard(
        title: title,
        points: points,
        color: color,
        normValue: norm,
        period: period,
        maxY: maxY,
      ),
    );
  }
}

class ArcPainter extends CustomPainter {
  final double percent;
  final Color color;
  final Color bgColor;
  const ArcPainter({
    required this.percent,
    required this.color,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.8);
    final radius = size.width / 2;

    final paintBg = Paint()
      ..color = bgColor
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final paintActive = Paint()
      ..color = color
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const int totalTicks = 40;
    const double startAngle = -math.pi;
    const double sweepAngle = math.pi;

    for (int i = 0; i < totalTicks; i++) {
      final double angle = startAngle + (sweepAngle * i / (totalTicks - 1));
      const double tickLen = 12;

      final p1 = Offset(
        center.dx + (radius - tickLen) * math.cos(angle),
        center.dy + (radius - tickLen) * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );

      final bool isActive = (i / totalTicks) < percent;
      canvas.drawLine(p1, p2, isActive ? paintActive : paintBg);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
