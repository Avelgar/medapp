import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../models/user_profile.dart';
import '../models/auth_data.dart';
import '../viewmodels/profile_view_model.dart';
import '../viewmodels/auth_view_model.dart';
import '../viewmodels/sync_view_model.dart';
import '../viewmodels/tracker_view_model.dart';
import '../viewmodels/theme_view_model.dart';
import 'register_screen.dart';
import 'login_screen.dart';
import '../main.dart';

enum SyncAction { upload, download, syncMeMaster, syncServerMaster, p2p }

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _dobController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  String _selectedGender = 'Мужской';

  final maskFormatter = MaskTextInputFormatter(
    mask: '##.##.####',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _dobController = TextEditingController();
    _weightController = TextEditingController();
    _heightController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _startEditing(UserProfile user) {
    setState(() {
      _isEditing = true;
      _nameController.text = user.name;
      _dobController.text = user.birthDate;
      _weightController.text = user.weight.toString();
      _heightController.text = user.height.toString();
      _selectedGender = user.gender;
    });
  }

  Future<void> _saveChanges() async {
    FocusScope.of(context).unfocus();
    final updatedUser = UserProfile(
      name: _nameController.text,
      birthDate: _dobController.text,
      gender: _selectedGender,
      height: double.tryParse(_heightController.text) ?? 0,
      weight: double.tryParse(_weightController.text) ?? 0,
      weightGoal:
          context.read<ProfileViewModel>().user?.weightGoal ?? 'maintain',
    );
    await context.read<ProfileViewModel>().saveUserProfile(updatedUser);
    if (mounted) setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ProfileViewModel>();
    final user = viewModel.user;
    final authModel = context.watch<AuthViewModel>();
    final auth = authModel.auth;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Нет данных")));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Редактирование' : 'Профиль'),
        centerTitle: true,
        leading: _isEditing
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _isEditing = false),
              )
            : null,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: _isEditing ? _buildEditForm() : _buildViewInfo(user, auth),
          ),
        ),
      ),
    );
  }

  Widget _buildViewInfo(UserProfile user, AuthData? auth) {
    final themeVM = context.watch<ThemeViewModel>();
    final isDark = themeVM.isDarkMode;
    final theme = Theme.of(context);

    return Column(
      children: [
        const SizedBox(height: 20),
        Center(
          child: CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Text(
              user.name.isNotEmpty ? user.name[0] : "?",
              style: const TextStyle(
                fontSize: 40,
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            user.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),

        const SizedBox(height: 30),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              _buildProfileRow("Пол", user.gender),
              const Divider(),
              _buildProfileRow("Дата рождения", user.birthDate),
              const Divider(),
              _buildProfileRow("Вес", "${user.weight} кг"),
              const Divider(),
              _buildProfileRow("Рост", "${user.height} см"),
            ],
          ),
        ),

        const SizedBox(height: 20),

        Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: SwitchListTile(
            title: const Text(
              "Тёмная тема",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            secondary: Icon(
              isDark ? Icons.dark_mode : Icons.light_mode,
              color: isDark ? Colors.amber : AppColors.primary,
            ),
            value: isDark,
            onChanged: (value) => themeVM.toggleTheme(value),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),

        const SizedBox(height: 20),

        if (auth != null) ...[
          _buildProfileButton(
            "Резервное копирование",
            Icons.cloud_upload,
            () => _showCloudBackupDialog(context),
          ),
          const SizedBox(height: 10),
          _buildProfileButton(
            "Синхронизация устройств",
            Icons.devices,
            () => _showP2PSyncDialog(context),
          ),
        ],

        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _startEditing(user),
            child: const Text("Редактировать данные"),
          ),
        ),

        const SizedBox(height: 20),

        if (auth == null) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
                side: BorderSide(
                  color: Theme.of(
                    context,
                  ).textTheme.bodyLarge!.color!.withValues(alpha: 0.3),
                ),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RegisterScreen()),
              ),
              child: const Text("Регистрация"),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              ),
              child: const Text("Войти"),
            ),
          ),
        ] else ...[
          _buildProfileButton(
            "Выйти из аккаунта",
            Icons.logout,
            () => context.read<AuthViewModel>().logout(),
            isDestructive: true,
          ),
        ],
        const SizedBox(height: 40),
      ],
    );
  }
  // --- WIDGETS ---

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildProfileButton(
    String text,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).cardColor,
        foregroundColor: isDestructive
            ? Colors.red
            : Theme.of(context).textTheme.bodyLarge?.color,
        elevation: 0,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      onPressed: onTap,
      child: Row(
        children: [
          Icon(icon, color: isDestructive ? Colors.red : AppColors.primary),
          const SizedBox(width: 15),
          Text(text),
          const Spacer(),
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ],
      ),
    );
  }

  void _showCloudBackupDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Резервное копирование",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.cloud_upload),
                label: const Text("Сохранить на сервер"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _performAction(context, SyncAction.upload);
                },
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.cloud_download),
                label: const Text("Загрузить с сервера"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _performAction(context, SyncAction.download);
                },
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.sync),
                label: const Text("Синхронизировать с сервером"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _showMasterSelectionDialog(context, isCloud: true);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showP2PSyncDialog(BuildContext context) {
    final pinController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SafeArea(
              child: Consumer<SyncViewModel>(
                builder: (context, syncVM, child) {
                  return Padding(
                    padding: EdgeInsets.only(
                      left: 20,
                      right: 20,
                      top: 20,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                    ),
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "P2P Синхронизация",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (syncVM.state != SyncState.idle)
                                IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    if (syncVM.isHost) {
                                      syncVM.closeRoom();
                                    } else {
                                      syncVM.leaveRoom();
                                    }
                                    Navigator.pop(ctx);
                                  },
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          if (syncVM.state == SyncState.idle ||
                              syncVM.state == SyncState.error) ...[
                            _buildHostOption(syncVM),
                            const Divider(height: 40, thickness: 1),
                            _buildGuestOption(syncVM, pinController),

                            if (syncVM.state == SyncState.error)
                              Padding(
                                padding: const EdgeInsets.only(top: 20),
                                child: Text(
                                  syncVM.statusMessage,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],

                          if (syncVM.isHost &&
                              syncVM.state != SyncState.idle) ...[
                            Text(
                              "Ваш код:",
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              syncVM.generatedPin ?? "...",
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 5,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 30),

                            if (syncVM.state == SyncState.createdWait) ...[
                              const CircularProgressIndicator(),
                              const SizedBox(height: 20),
                              const Text(
                                "Ожидание подключения второго устройства...",
                                textAlign: TextAlign.center,
                              ),
                            ],

                            if (syncVM.state == SyncState.connectedHost) ...[
                              Container(
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.green),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.phone_android,
                                      color: Colors.green,
                                    ),
                                    const SizedBox(width: 10),
                                    const Expanded(
                                      child: Text(
                                        "Устройство подключено!",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () => syncVM.kickGuest(),
                                      child: const Text(
                                        "Отключить",
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 30),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.sync),
                                label: const Text("Начать синхронизацию"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 50),
                                ),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (alertCtx) => AlertDialog(
                                      title: const Text("Приоритет данных"),
                                      content: const Text(
                                        "Чьи данные сохранить при конфликте?",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(alertCtx);
                                            syncVM.startSync(
                                              context,
                                              isMeMaster: true,
                                            );
                                          },
                                          child: const Text("Мои (Главные)"),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(alertCtx);
                                            syncVM.startSync(
                                              context,
                                              isMeMaster: false,
                                            );
                                          },
                                          child: const Text("Второго устр."),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],

                            const SizedBox(height: 40),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.delete),
                              label: const Text("Удалить комнату"),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                              ),
                              onPressed: () {
                                syncVM.closeRoom();
                              },
                            ),
                          ],

                          if (!syncVM.isHost &&
                              syncVM.state != SyncState.idle) ...[
                            if (syncVM.state == SyncState.connecting)
                              const CircularProgressIndicator(),

                            if (syncVM.state == SyncState.connectedGuest) ...[
                              const Icon(
                                Icons.link,
                                size: 60,
                                color: Colors.green,
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                "Успешное подключение!",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                "Ожидайте, пока хост начнет синхронизацию.\nНе закрывайте это окно.",
                                textAlign: TextAlign.center,
                              ),
                            ],

                            const SizedBox(height: 40),
                            OutlinedButton(
                              onPressed: () {
                                syncVM.leaveRoom();
                              },
                              child: const Text("Выйти из комнаты"),
                            ),
                          ],

                          if (syncVM.state == SyncState.syncing) ...[
                            const SizedBox(height: 30),
                            const CircularProgressIndicator(),
                            const SizedBox(height: 10),
                            Text(syncVM.statusMessage),
                          ],

                          if (syncVM.state == SyncState.success) ...[
                            const SizedBox(height: 30),
                            const Icon(
                              Icons.check_circle,
                              size: 60,
                              color: Colors.green,
                            ),
                            const Text(
                              "Готово!",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text("Закрыть"),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    ).then((_) {
      if (!context.mounted) return;

      final syncVM = context.read<SyncViewModel>();
      if (syncVM.state != SyncState.idle) {
        if (syncVM.isHost) {
          syncVM.closeRoom();
        } else {
          syncVM.leaveRoom();
        }
      }

      context.read<TrackerViewModel>().loadData();
      context.read<ProfileViewModel>().loadProfile();
    });
  }

  void _showMasterSelectionDialog(
    BuildContext context, {
    required bool isCloud,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Конфликт данных"),
        content: const Text(
          "При совпадении дат, чьи данные считать приоритетными?",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (isCloud) {
                _performAction(context, SyncAction.syncMeMaster);
              } else {
                _performAction(context, SyncAction.p2p, isMeMaster: true);
              }
            },
            child: const Text(
              "Это устройство",
              style: TextStyle(color: Colors.green),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (isCloud) {
                _performAction(context, SyncAction.syncServerMaster);
              } else {
                _performAction(context, SyncAction.p2p, isMeMaster: false);
              }
            },
            child: Text(
              isCloud ? "Сервер" : "Второе устройство",
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performAction(
    BuildContext context,
    SyncAction action, {
    bool isMeMaster = true,
  }) async {
    if (action != SyncAction.p2p) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
    }

    final syncVM = context.read<SyncViewModel>();
    bool success = false;

    switch (action) {
      case SyncAction.upload:
        success = await syncVM.saveToCloud(context);
        break;
      case SyncAction.download:
        success = await syncVM.loadFromCloud(context);
        break;
      case SyncAction.syncMeMaster:
        success = await syncVM.syncWithCloud(context, isMeMaster: true);
        break;
      case SyncAction.syncServerMaster:
        success = await syncVM.syncWithCloud(context, isMeMaster: false);
        break;
      case SyncAction.p2p:
        await syncVM.startSync(context, isMeMaster: isMeMaster);
        return;
    }

    if (!context.mounted) return;
    Navigator.pop(context);

    if (action != SyncAction.p2p && success) {
      context.read<TrackerViewModel>().loadData();
      context.read<ProfileViewModel>().loadProfile();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? "Успешно!" : "Ошибка операции"),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  Widget _buildHostOption(SyncViewModel vm) {
    return InkWell(
      onTap: () => vm.startHostSession(),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.add_circle_outline, size: 32, color: Colors.blue),
            SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Создать комнату",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Получить код для второго устройства",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestOption(SyncViewModel vm, TextEditingController controller) {
    return Column(
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Или присоединиться:",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: const InputDecoration(
                  hintText: "Введите код (4 цифры)",
                  border: OutlineInputBorder(),
                  counterText: "",
                  contentPadding: EdgeInsets.symmetric(horizontal: 10),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {
                if (controller.text.length == 4) {
                  vm.joinSession(controller.text);
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 15,
                  horizontal: 20,
                ),
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
              child: const Text("Войти"),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEditForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          "Ваши данные",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        const Text(
          "Измените параметры для перерасчета норм",
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 30),

        TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Имя'),
        ),
        const SizedBox(height: 20),

        DropdownButtonFormField<String>(
          initialValue: _selectedGender,
          decoration: const InputDecoration(labelText: 'Пол'),
          items: ['Мужской', 'Женский'].map((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
          onChanged: (val) => setState(() => _selectedGender = val!),
        ),
        const SizedBox(height: 20),

        TextField(
          controller: _dobController,
          keyboardType: TextInputType.number,
          inputFormatters: [maskFormatter],
          decoration: const InputDecoration(
            labelText: 'Дата рождения (дд.мм.гггг)',
            hintText: '01.01.1990',
          ),
        ),
        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Вес (кг)'),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: TextField(
                controller: _heightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Рост (см)'),
              ),
            ),
          ],
        ),

        const SizedBox(height: 40),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saveChanges,
            child: const Text('Сохранить изменения'),
          ),
        ),
      ],
    );
  }
}
