import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../services/database_helper.dart';
import '../services/storage_service.dart';
import '../models/user_profile.dart';
import 'auth_view_model.dart';
import 'profile_view_model.dart';
import 'tracker_view_model.dart';
import 'package:http/http.dart' as http;

enum SyncState {
  idle,
  connecting,
  createdWait,
  connectedHost,
  connectedGuest,
  syncing,
  success,
  error,
}

class SyncViewModel extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  static const String _baseUrl = 'https://health-sync.online';
  static const String _wsUrl = 'wss://health-sync.online/ws/';

  SyncState _state = SyncState.idle;
  String? _generatedPin;
  String _statusMessage = "";
  WebSocketChannel? _channel;
  bool _isHost = false;

  SyncState get state => _state;
  String? get generatedPin => _generatedPin;
  String get statusMessage => _statusMessage;
  bool get isHost => _isHost;

  Future<void> startHostSession() async {
    _reset();
    _state = SyncState.connecting;
    _isHost = true;
    notifyListeners();
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));
      _channel!.stream.listen(
        (msg) => _handleMsg(msg),
        onError: (e) => _handleError("$e"),
        onDone: () => _handleDone(),
      );
      _channel!.sink.add(jsonEncode({"action": "create_room"}));
    } catch (e) {
      _handleError("Ошибка сети");
    }
  }

  Future<void> joinSession(String pin) async {
    _reset();
    _state = SyncState.connecting;
    _isHost = false;
    notifyListeners();
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));
      _channel!.stream.listen(
        (msg) => _handleMsg(msg),
        onError: (e) => _handleError("$e"),
        onDone: () => _handleDone(),
      );
      _channel!.sink.add(jsonEncode({"action": "join_room", "pin": pin}));
    } catch (e) {
      _handleError("Ошибка сети");
    }
  }

  void kickGuest() {
    if (_channel != null && _isHost) {
      _channel!.sink.add(jsonEncode({"action": "kick_peer"}));
    }
  }

  void closeRoom() {
    if (_channel != null) {
      _channel!.sink.add(jsonEncode({"action": "close_room"}));
    } else {
      _reset();
    }
  }

  void leaveRoom() {
    _channel?.sink.close();
    _reset();
  }

  Future<void> startSync(
    BuildContext context, {
    required bool isMeMaster,
  }) async {
    if (_channel == null) return;

    _state = SyncState.syncing;
    _statusMessage = "Сбор данных...";
    notifyListeners();

    final data = await _collectLocalData(context);
    String masterRole = isMeMaster
        ? (_isHost ? 'host' : 'joiner')
        : (_isHost ? 'joiner' : 'host');

    _channel!.sink.add(
      jsonEncode({
        "action": "sync_data",
        "master_role": masterRole,
        "payload": data,
      }),
    );

    _statusMessage = "Отправка...";
    notifyListeners();
  }

  void _handleMsg(String message) {
    debugPrint("WS: $message");
    final data = jsonDecode(message);
    final status = data['status'];

    if (status == 'created') {
      _generatedPin = data['pin'];
      _state = SyncState.createdWait;
    } else if (status == 'joined') {
      _state = SyncState.connectedGuest;
    } else if (status == 'peer_joined') {
      _state = SyncState.connectedHost;
    } else if (status == 'peer_disconnected') {
      if (_isHost) {
        _state = SyncState.createdWait;
        _statusMessage = "Устройство отключено";
      }
    } else if (status == 'kicked' || status == 'room_closed') {
      _handleError(status == 'kicked' ? "Вас исключили" : "Комната закрыта");
    } else if (status == 'closed_by_me') {
      _reset();
    } else if (status == 'request_data') {
      _statusMessage = "Синхронизация...";
      _sendDataBack(data['master_role']);
    } else if (status == 'sync_complete') {
      // !!! ВАЖНО !!! Мы не можем передать контекст сюда, чтобы обновить UI.
      // Поэтому сохраняем в БД, а UI обновится, если пользователь перезайдет на экраны
      _applyResult(data['data']);
    } else if (status == 'error') {
      _handleError(data['message']);
    }
    notifyListeners();
  }

  void _handleError(String msg) {
    _state = SyncState.error;
    _statusMessage = msg;
    _channel?.sink.close();
    notifyListeners();
  }

  void _handleDone() {
    if (_state != SyncState.idle && _state != SyncState.error) {
      _reset();
    }
  }

  void _reset() {
    _channel?.sink.close();
    _channel = null;
    _generatedPin = null;
    _statusMessage = "";
    _state = SyncState.idle;
    _isHost = false;
    notifyListeners();
  }

  Future<void> _sendDataBack(String m) async {
    final profileJson = await StorageService().loadProfile();
    final profile = profileJson != null ? jsonDecode(profileJson) : null;
    final allCalories = await _dbHelper.getRecordsForRange(
      'Calories_Records',
      DateTime(2000),
      DateTime(2100),
    );
    final allWater = await _dbHelper.getRecordsForRange(
      'Water_Records',
      DateTime(2000),
      DateTime(2100),
    );
    final allSleep = await _dbHelper.getRecordsForRange(
      'Sleep_Records',
      DateTime(2000),
      DateTime(2100),
    );
    final allMood = await _dbHelper.getRecordsForRange(
      'Mood_Records',
      DateTime(2000),
      DateTime(2100),
    );
    final allActivity = await _dbHelper.getRecordsForRange(
      'Activity_Records',
      DateTime(2000),
      DateTime(2100),
    );

    final payload = {
      "profile": profile,
      "calories": allCalories,
      "water": allWater,
      "sleep": allSleep,
      "mood": allMood,
      "activity": allActivity,
    };
    _channel!.sink.add(
      jsonEncode({
        "action": "return_data",
        "master_role": m,
        "payload": payload,
      }),
    );
  }

  Future<Map<String, dynamic>> _collectLocalData(BuildContext context) async {
    final profile = context.read<ProfileViewModel>().user;
    final allCalories = await _dbHelper.getRecordsForRange(
      'Calories_Records',
      DateTime(2000),
      DateTime(2100),
    );
    final allWater = await _dbHelper.getRecordsForRange(
      'Water_Records',
      DateTime(2000),
      DateTime(2100),
    );
    final allSleep = await _dbHelper.getRecordsForRange(
      'Sleep_Records',
      DateTime(2000),
      DateTime(2100),
    );
    final allMood = await _dbHelper.getRecordsForRange(
      'Mood_Records',
      DateTime(2000),
      DateTime(2100),
    );
    final allActivity = await _dbHelper.getRecordsForRange(
      'Activity_Records',
      DateTime(2000),
      DateTime(2100),
    );
    return {
      "profile": profile != null ? jsonDecode(profile.toJson()) : null,
      "calories": allCalories,
      "water": allWater,
      "sleep": allSleep,
      "mood": allMood,
      "activity": allActivity,
    };
  }

  Future<void> _applyResult(Map<String, dynamic> data) async {
    await _dbHelper.clearAllTables();
    if (data['profile'] != null) {
      await StorageService().saveProfile(jsonEncode(data['profile']));
    }
    final db = await _dbHelper.database;
    final batch = db.batch();
    for (var r in data['calories']) {
      batch.insert('Calories_Records', r);
    }
    for (var r in data['water']) {
      batch.insert('Water_Records', r);
    }
    for (var r in data['sleep']) {
      batch.insert('Sleep_Records', r);
    }
    for (var r in data['mood']) {
      batch.insert('Mood_Records', r);
    }
    for (var r in data['activity']) {
      batch.insert('Activity_Records', r);
    }
    await batch.commit(noResult: true);

    _state = SyncState.success;
    _statusMessage = "Успешно!";

    notifyListeners();
  }

  Future<bool> saveToCloud(BuildContext context) async {
    final auth = context.read<AuthViewModel>().auth;
    if (auth == null) return false;

    final profile = context.read<ProfileViewModel>().user;
    final allCalories = await _dbHelper.getRecordsForRange(
      'Calories_Records',
      DateTime(2000),
      DateTime(2100),
    );
    final allWater = await _dbHelper.getRecordsForRange(
      'Water_Records',
      DateTime(2000),
      DateTime(2100),
    );
    final allSleep = await _dbHelper.getRecordsForRange(
      'Sleep_Records',
      DateTime(2000),
      DateTime(2100),
    );
    final allMood = await _dbHelper.getRecordsForRange(
      'Mood_Records',
      DateTime(2000),
      DateTime(2100),
    );
    final allActivity = await _dbHelper.getRecordsForRange(
      'Activity_Records',
      DateTime(2000),
      DateTime(2100),
    );

    final body = {
      "profile": profile != null ? jsonDecode(profile.toJson()) : null,
      "calories": allCalories,
      "water": allWater,
      "sleep": allSleep,
      "mood": allMood,
      "activity": allActivity,
    };

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/backup/upload'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${auth.token}',
        },
        body: jsonEncode(body),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Sync Error: $e");
      return false;
    }
  }

  Future<bool> loadFromCloud(BuildContext context) async {
    final auth = context.read<AuthViewModel>().auth;
    if (auth == null) return false;

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/backup/download'),
        headers: {'Authorization': 'Bearer ${auth.token}'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (context.mounted) {
          await _applyCloudDataLocally(context, data);
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> syncWithCloud(
    BuildContext context, {
    required bool isMeMaster,
  }) async {
    final auth = context.read<AuthViewModel>().auth;
    if (auth == null) return false;

    final profile = context.read<ProfileViewModel>().user;
    final allCalories = await _dbHelper.getRecordsForRange(
      'Calories_Records',
      DateTime(2000),
      DateTime(2100),
    );
    final allWater = await _dbHelper.getRecordsForRange(
      'Water_Records',
      DateTime(2000),
      DateTime(2100),
    );
    final allSleep = await _dbHelper.getRecordsForRange(
      'Sleep_Records',
      DateTime(2000),
      DateTime(2100),
    );
    final allMood = await _dbHelper.getRecordsForRange(
      'Mood_Records',
      DateTime(2000),
      DateTime(2100),
    );
    final allActivity = await _dbHelper.getRecordsForRange(
      'Activity_Records',
      DateTime(2000),
      DateTime(2100),
    );

    final requestBody = {
      "master": isMeMaster ? "client" : "server",
      "data": {
        "profile": profile != null ? jsonDecode(profile.toJson()) : null,
        "calories": allCalories,
        "water": allWater,
        "sleep": allSleep,
        "mood": allMood,
        "activity": allActivity,
      },
    };

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/backup/sync'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${auth.token}',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (context.mounted) {
          await _applyCloudDataLocally(context, responseData);
        }
        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint("Sync Net Error: $e");
      return false;
    }
  }

  Future<void> _applyCloudDataLocally(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    await _dbHelper.clearAllTables();

    if (data['profile'] != null) {
      final pData = data['profile'];
      final user = UserProfile(
        name: pData['name'],
        birthDate: pData['birthDate'],
        gender: pData['gender'],
        height: (pData['height'] as num).toDouble(),
        weight: (pData['weight'] as num).toDouble(),
        weightGoal: pData['weightGoal'] ?? 'maintain',
      );
      if (context.mounted) {
        await context.read<ProfileViewModel>().saveUserProfile(user);
      }
    }

    final db = await _dbHelper.database;
    final batch = db.batch();

    for (var r in data['calories']) {
      batch.insert('Calories_Records', r);
    }
    for (var r in data['water']) {
      batch.insert('Water_Records', r);
    }
    for (var r in data['sleep']) {
      batch.insert('Sleep_Records', r);
    }
    for (var r in data['mood']) {
      batch.insert('Mood_Records', r);
    }
    for (var r in data['activity']) {
      batch.insert('Activity_Records', r);
    }

    await batch.commit(noResult: true);

    if (context.mounted) {
      context.read<TrackerViewModel>().loadData();
    }
  }
}
