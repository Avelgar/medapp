import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../viewmodels/tracker_view_model.dart';
import '../viewmodels/auth_view_model.dart';
import '../models/tracker_records.dart';
import '../models/user_profile.dart';
import '../services/ai_service.dart';
import 'dart:convert';
import 'dart:io';
import '../viewmodels/notification_view_model.dart';
import '../viewmodels/profile_view_model.dart';

class DataEntryScreen extends StatefulWidget {
  final String? initialDialog;
  const DataEntryScreen({super.key, this.initialDialog});

  @override
  State<DataEntryScreen> createState() => _DataEntryScreenState();
}

class _DataEntryScreenState extends State<DataEntryScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.initialDialog != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _checkAndOpenDialog(
          context.read<TrackerViewModel>(),
          widget.initialDialog!,
        );
      });
    }
  }

  void _checkAndOpenDialog(TrackerViewModel vm, String type) {
    if (type == 'calories') {
      _showCaloriesDialog(context, vm);
    } else if (type == 'water') {
      _showWaterDialog(context, vm);
    } else if (type == 'sleep') {
      _showSleepDialog(context, vm);
    } else if (type == 'mood') {
      _showMoodDialog(context, vm);
    } else if (type == 'activity') {
      _showActivityDialog(context, vm);
    }
  }

  Future<void> _pickDate(BuildContext context, TrackerViewModel vm) async {
    FocusScope.of(context).unfocus();
    await Future.delayed(const Duration(milliseconds: 300));
    if (!context.mounted) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: vm.entryDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale("ru", "RU"),
    );
    if (picked != null) {
      vm.setEntryDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = context.watch<AuthViewModel>().isPremium;

    return Consumer<TrackerViewModel>(
      builder: (context, vm, child) {
        if (vm.pendingDialogType != null) {
          final type = vm.pendingDialogType!;
          vm.clearPendingDialog();
          Future.microtask(() => _checkAndOpenDialog(vm, type));
        }

        final dateStr = DateFormat('d MMMM yyyy', 'ru').format(vm.entryDate);

        return Scaffold(
          appBar: AppBar(
            title: Text(dateStr),
            actions: [
              IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () => _pickDate(context, vm),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                _buildAICameraCard(context, isPremium, vm),
                const SizedBox(height: 20),
                _buildCategoryCard(
                  title: "Питание",
                  totalValue: "${vm.totalEntryCalories} ккал",
                  color: Colors.orange,
                  icon: Icons.local_fire_department,
                  onAdd: () => _showCaloriesDialog(context, vm),
                  items: vm.calorieRecords
                      .map(
                        (e) => _buildRecordItem(
                          context,
                          "${e.calories} ккал",
                          DateFormat('HH:mm').format(e.date),
                          () => _showCaloriesDialog(context, vm, record: e),
                          () => vm.deleteCalories(e.id),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 15),
                _buildCategoryCard(
                  title: "Вода",
                  totalValue: "${vm.totalEntryWater} мл",
                  color: Colors.blue,
                  icon: Icons.local_drink,
                  onAdd: () => _showWaterDialog(context, vm),
                  items: vm.waterRecords
                      .map(
                        (e) => _buildRecordItem(
                          context,
                          "${e.amount} мл",
                          DateFormat('HH:mm').format(e.date),
                          () => _showWaterDialog(context, vm, record: e),
                          () => vm.deleteWater(e.id),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 15),
                _buildSleepSection(
                  context,
                  vm,
                  context.read<NotificationViewModel>(),
                  context.read<ProfileViewModel>().user,
                ),
                const SizedBox(height: 15),
                _buildCategoryCard(
                  title: "Настроение",
                  totalValue: "Среднее: ${vm.avgEntryMood.toStringAsFixed(1)}",
                  color: Colors.green,
                  icon: Icons.emoji_emotions,
                  onAdd: () => _showMoodDialog(context, vm),
                  items: vm.moodRecords
                      .map(
                        (e) => _buildRecordItem(
                          context,
                          _getMoodEmoji(e.score),
                          DateFormat('HH:mm').format(e.date),
                          () => _showMoodDialog(context, vm, record: e),
                          () => vm.deleteMood(e.id),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 15),
                _buildCategoryCard(
                  title: "Спорт",
                  totalValue: "${vm.dailyMetMinutes.round()} MET-мин",
                  color: Colors.purple,
                  icon: Icons.fitness_center,
                  onAdd: () => _showActivityDialog(context, vm),
                  items: vm.activityRecords
                      .map(
                        (e) => _buildRecordItem(
                          context,
                          e.sportName,
                          "${e.minutes} мин (${e.met} MET)",
                          () => _showActivityDialog(context, vm, record: e),
                          () => vm.deleteActivity(e.id),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAICameraCard(
    BuildContext context,
    bool isPremium,
    TrackerViewModel vm,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: isPremium
            ? const LinearGradient(
                colors: [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
              )
            : const LinearGradient(colors: [Colors.grey, Colors.blueGrey]),
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () {
            if (isPremium) {
              _showImageSourceDialog(context, vm);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Функция доступна только в Premium"),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                const Icon(Icons.camera_enhance, color: Colors.white, size: 40),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPremium ? "AI Сканер еды" : "AI Сканер (Premium)",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        isPremium
                            ? "Сделайте фото обеда — AI посчитает калории и воду"
                            : "Разблокируйте, чтобы считать калории по фото",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isPremium) const Icon(Icons.lock, color: Colors.amber),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSleepSection(
    BuildContext context,
    TrackerViewModel vm,
    NotificationViewModel notifyVM,
    UserProfile? user,
  ) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 10),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: vm.isSleeping ? Colors.redAccent : Colors.indigo,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: Icon(
              vm.isSleeping ? Icons.alarm_off : Icons.bedtime,
              color: Colors.white,
            ),
            label: Text(
              vm.isSleeping ? "Проснулся" : "Иду спать",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () async {
              if (user == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Сначала заполните профиль")),
                );
                return;
              }

              if (vm.isSleeping) {
                await vm.endSleepSession();
                notifyVM.onWakeUp(vm, user);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Доброе утро! Сон записан.")),
                  );
                }
              } else {
                await vm.startSleepSession();
                notifyVM.onSleepStart(vm, user);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Спокойной ночи! Таймер запущен."),
                    ),
                  );
                }
              }
            },
          ),
        ),

        _buildCategoryCard(
          title: "Сон",
          totalValue: "${vm.totalEntrySleep.toStringAsFixed(1)} ч",
          color: Colors.indigo,
          icon: Icons.bedtime,
          onAdd: () => _showSleepDialog(context, vm),
          items: vm.sleepRecords
              .map(
                (e) => _buildRecordItem(
                  context,
                  "${e.duration.toStringAsFixed(1)} ч",
                  "${DateFormat('HH:mm').format(e.startTime)} - ${DateFormat('HH:mm').format(e.endTime)}",
                  () => _showSleepDialog(context, vm, record: e),
                  () => vm.deleteSleep(e.id),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  // --- UI Helpers ---
  String _getMoodEmoji(int score) =>
      "${{1: "😞", 2: "😐", 3: "🙂", 4: "😄", 5: "🤩"}[score] ?? '?'} ($score)";

  Widget _buildCategoryCard({
    required String title,
    required String totalValue,
    required Color color,
    required IconData icon,
    required VoidCallback onAdd,
    required List<Widget> items,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.transparent : Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: Text(
              totalValue,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          if (items.isNotEmpty)
            ...items
          else
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: Text("Нет записей", style: TextStyle(color: Colors.grey)),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text("Добавить запись"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordItem(
    BuildContext context,
    String title,
    String subtitle,
    VoidCallback onEdit,
    VoidCallback onDelete,
  ) {
    return ListTile(
      dense: true,
      title: Text(title),
      subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 18, color: Colors.red),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }

  // --- ДИАЛОГИ ---

  EdgeInsets _getModalPadding(BuildContext context) {
    return EdgeInsets.only(
      bottom:
          MediaQuery.of(context).viewInsets.bottom +
          MediaQuery.of(context).padding.bottom +
          20,
      top: 20,
      left: 20,
      right: 20,
    );
  }

  void _showImageSourceDialog(BuildContext context, TrackerViewModel vm) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Сделать фото'),
              onTap: () {
                Navigator.pop(ctx);
                _processImage(context, ImageSource.camera, vm);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Выбрать из галереи'),
              onTap: () {
                Navigator.pop(ctx);
                _processImage(context, ImageSource.gallery, vm);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processImage(
    BuildContext context,
    ImageSource source,
    TrackerViewModel vm,
  ) async {
    final ImagePicker picker = ImagePicker();
    final authVM = context.read<AuthViewModel>();

    try {
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 30,
      );
      if (image == null) return;

      if (!context.mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: Colors.purple),
        ),
      );

      final bytes = await File(image.path).readAsBytes();
      final base64String = base64Encode(bytes);

      final aiService = AIService();

      final result = await aiService.analyzeFoodImage(
        authVM.auth!.token,
        base64String,
      );

      if (!context.mounted) return;
      Navigator.pop(context);

      final int detectedCal = result['calories'] ?? 0;
      final int detectedWater = result['water_ml'] ?? 0;
      final String detectedName = result['name'] ?? "";

      if (detectedCal == 0 && detectedWater == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("AI не нашел еду или напитки")),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Результат AI"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (detectedName.isNotEmpty)
                Text(
                  "На фото: $detectedName",
                  style: const TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              const SizedBox(height: 10),

              if (detectedCal > 0)
                Text(
                  "🍔 Калории: ~$detectedCal ккал",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              if (detectedWater > 0)
                Text(
                  "🥤 Вода: ~$detectedWater мл",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Отмена"),
            ),
            ElevatedButton(
              onPressed: () {
                if (detectedCal > 0) {
                  vm.addCalories(detectedCal);
                }
                if (detectedWater > 0) {
                  vm.addWater(detectedWater);
                }

                final user = context.read<ProfileViewModel>().user;
                if (user != null) {
                  context.read<NotificationViewModel>().onDataAdded(vm, user);
                }

                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Добавлено: $detectedName"),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text("Добавить"),
            ),
          ],
        ),
      );
    } catch (e) {
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Ошибка: $e")));
    }
  }

  void _showCaloriesDialog(
    BuildContext context,
    TrackerViewModel vm, {
    CalorieRecord? record,
  }) {
    final controller = TextEditingController(
      text: record != null ? record.calories.toString() : '',
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: _getModalPadding(ctx),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              record == null ? "Добавить калории" : "Изменить калории",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "ккал",
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final val = int.tryParse(controller.text);
                  if (val != null) {
                    if (record == null) {
                      vm.addCalories(val);
                    } else {
                      vm.updateCalories(record.id, val);
                    }
                    final user = context.read<ProfileViewModel>().user;
                    if (user != null) {
                      context.read<NotificationViewModel>().onDataAdded(
                        vm,
                        user,
                      );
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                  }
                },
                child: Text(record == null ? "Добавить" : "Сохранить"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showWaterDialog(
    BuildContext context,
    TrackerViewModel vm, {
    WaterRecord? record,
  }) {
    final controller = TextEditingController(
      text: record != null ? record.amount.toString() : '',
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: _getModalPadding(ctx),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              record == null ? "Добавить воду" : "Изменить воду",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "мл",
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            if (record == null) ...[
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [100, 250, 500]
                    .map(
                      (e) => OutlinedButton(
                        onPressed: () => controller.text = e.toString(),
                        child: Text("+$e"),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final val = int.tryParse(controller.text);
                  if (val != null) {
                    if (record == null) {
                      vm.addWater(val);
                    } else {
                      vm.updateWater(record.id, val);
                    }
                    final user = context.read<ProfileViewModel>().user;
                    if (user != null) {
                      context.read<NotificationViewModel>().onDataAdded(
                        vm,
                        user,
                      );
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                  }
                },
                child: Text(record == null ? "Добавить" : "Сохранить"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSleepDialog(
    BuildContext context,
    TrackerViewModel vm, {
    SleepRecord? record,
  }) {
    DateTime initStart =
        record?.startTime ??
        DateTime(
          vm.entryDate.year,
          vm.entryDate.month,
          vm.entryDate.day - 1,
          23,
          0,
        );

    DateTime initEnd =
        record?.endTime ??
        DateTime(vm.entryDate.year, vm.entryDate.month, vm.entryDate.day, 7, 0);

    DateTime selectedStart = initStart;
    DateTime selectedEnd = initEnd;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final diffMinutes = selectedEnd.difference(selectedStart).inMinutes;
            final duration = diffMinutes / 60.0;

            bool isInvalid = diffMinutes <= 0;

            return Padding(
              padding: _getModalPadding(ctx),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    record == null ? "Добавить сон" : "Изменить сон",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildTimePickerBtn(
                        context,
                        "Лег",
                        selectedStart,
                        (val) => setModalState(() => selectedStart = val),
                      ),
                      const Icon(Icons.arrow_forward, color: Colors.grey),
                      _buildTimePickerBtn(
                        context,
                        "Встал",
                        selectedEnd,
                        (val) => setModalState(() => selectedEnd = val),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  if (isInvalid)
                    const Text(
                      "Ошибка: Время пробуждения раньше времени засыпания!",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  else
                    Text(
                      "Длительность: ${duration.toStringAsFixed(1)} ч",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isInvalid
                          ? null
                          : () {
                              if (record == null) {
                                vm.addSleep(selectedStart, selectedEnd);
                              } else {
                                vm.updateSleep(
                                  record.id,
                                  selectedStart,
                                  selectedEnd,
                                );
                              }

                              if (ctx.mounted) Navigator.pop(ctx);
                            },
                      child: Text(record == null ? "Добавить" : "Сохранить"),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showMoodDialog(
    BuildContext context,
    TrackerViewModel vm, {
    MoodRecord? record,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: _getModalPadding(ctx),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              record == null ? "Как настроение?" : "Изменить настроение",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMoodBtn(ctx, vm, 1, "😞", Colors.red, record),
                _buildMoodBtn(ctx, vm, 2, "😐", Colors.orange, record),
                _buildMoodBtn(ctx, vm, 3, "🙂", Colors.yellow.shade700, record),
                _buildMoodBtn(ctx, vm, 4, "😄", Colors.green, record),
                _buildMoodBtn(ctx, vm, 5, "🤩", Colors.blue, record),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showActivityDialog(
    BuildContext context,
    TrackerViewModel vm, {
    ActivityRecord? record,
  }) {
    String selectedSport =
        record?.sportName ?? TrackerViewModel.sportsDictionary.keys.first;
    final minsController = TextEditingController(
      text: record != null ? record.minutes.toString() : '',
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: _getModalPadding(ctx),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    record == null ? "Добавить спорт" : "Изменить спорт",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    initialValue:
                        TrackerViewModel.sportsDictionary.containsKey(
                          selectedSport,
                        )
                        ? selectedSport
                        : TrackerViewModel.sportsDictionary.keys.first,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: "Вид активности",
                      border: OutlineInputBorder(),
                    ),
                    items: TrackerViewModel.sportsDictionary.keys.map((
                      String key,
                    ) {
                      return DropdownMenuItem<String>(
                        value: key,
                        child: Text(
                          "$key (MET ${TrackerViewModel.sportsDictionary[key]})",
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => selectedSport = val);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: minsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Время (минуты)",
                      border: OutlineInputBorder(),
                    ),
                    autofocus: false,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final mins = int.tryParse(minsController.text);
                        if (mins != null && mins > 0) {
                          final met =
                              TrackerViewModel.sportsDictionary[selectedSport]!;
                          if (record == null) {
                            vm.addActivity(selectedSport, mins, met);
                          } else {
                            vm.updateActivity(
                              record.id,
                              selectedSport,
                              mins,
                              met,
                            );
                          }
                          if (ctx.mounted) Navigator.pop(ctx);
                        }
                      },
                      child: Text(record == null ? "Добавить" : "Сохранить"),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTimePickerBtn(
    BuildContext context,
    String label,
    DateTime dateTime,
    Function(DateTime) onChanged,
  ) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),

        TextButton(
          onPressed: () async {
            final timeOfDay = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.fromDateTime(dateTime),
              builder: (BuildContext context, Widget? child) {
                return MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(alwaysUse24HourFormat: true),
                  child: child!,
                );
              },
            );
            if (timeOfDay != null) {
              final newDateTime = DateTime(
                dateTime.year,
                dateTime.month,
                dateTime.day,
                timeOfDay.hour,
                timeOfDay.minute,
              );
              onChanged(newDateTime);
            }
          },
          child: Text(
            DateFormat('HH:mm').format(dateTime),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
        ),

        InkWell(
          borderRadius: BorderRadius.circular(5),
          onTap: () async {
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: dateTime,
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 1)),
              locale: const Locale("ru", "RU"),
            );

            if (pickedDate != null) {
              final newDateTime = DateTime(
                pickedDate.year,
                pickedDate.month,
                pickedDate.day,
                dateTime.hour,
                dateTime.minute,
              );
              onChanged(newDateTime);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('d MMM', 'ru').format(dateTime),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.edit_calendar, size: 14, color: Colors.blue),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMoodBtn(
    BuildContext ctx,
    TrackerViewModel vm,
    int score,
    String emoji,
    Color color,
    MoodRecord? record,
  ) {
    return GestureDetector(
      onTap: () {
        if (record == null) {
          vm.addMood(score);
        } else {
          vm.updateMood(record.id, score);
        }
        if (ctx.mounted) Navigator.pop(ctx);
      },
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 5),
          Text(
            "$score",
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
