import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'viewmodels/profile_view_model.dart';
import 'viewmodels/auth_view_model.dart';
import 'viewmodels/tracker_view_model.dart';
import 'viewmodels/notification_view_model.dart';
import 'viewmodels/sync_view_model.dart';

import 'views/main_screen.dart';
import 'views/onboarding_screen.dart';
import 'views/data_entry_screen.dart';

class PageViewModel extends ChangeNotifier {
  int _currentIndex = 1;
  final PageController pageController = PageController(initialPage: 1);

  int get currentIndex => _currentIndex;

  void setPage(int index) {
    if (_currentIndex == index) return;
    _currentIndex = index;
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    notifyListeners();
  }

  void onPageChanged(int index) {
    _currentIndex = index;
    notifyListeners();
  }
}

class AppColors {
  static const Color bg = Color(0xFFF6F8FB);
  static const Color primary = Color(0xFF4361EE);
  static const Color card = Colors.white;
  static const Color textMain = Color(0xFF2B2B2B);
  static const Color textSec = Color(0xFF8E99A8);
  static const Color accentLime = Color(0xFFD6E774);
  static const Color accentFire = Color(0xFFFF7F50);
  static const Color accentWater = Color(0xFF4CC9F0);
}

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru', null);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => TrackerViewModel()),
        ChangeNotifierProvider(create: (_) => NotificationViewModel()),
        ChangeNotifierProvider(create: (_) => SyncViewModel()),
        ChangeNotifierProvider(create: (_) => PageViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Health Sync',
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      theme: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.bg,
        fontFamily: 'Roboto',
        useMaterial3: true,

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
          labelStyle: const TextStyle(color: AppColors.textSec),
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.bg,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: AppColors.textMain,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: AppColors.textMain),
        ),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ru', 'RU')],
      home: const AuthCheckWrapper(),
    );
  }
}

class AuthCheckWrapper extends StatefulWidget {
  const AuthCheckWrapper({super.key});

  @override
  State<AuthCheckWrapper> createState() => _AuthCheckWrapperState();
}

class _AuthCheckWrapperState extends State<AuthCheckWrapper> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  bool _isProcessingLink = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileViewModel>().loadProfile();
      context.read<AuthViewModel>().checkAuth();
      context.read<TrackerViewModel>().loadData();
      _initDeepLinks();

      final notifVM = context.read<NotificationViewModel>();
      notifVM.init(_onNotificationClick);
    });
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();
    try {
      final Uri? initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) _handleDeepLink(initialUri);
    } catch (e) {
      debugPrint('DeepLink Error: $e');
    }
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri? uri) {
        if (uri != null) _handleDeepLink(uri);
      },
      onError: (err) {
        debugPrint('DeepLink Stream Error: $err');
      },
    );
  }

  void _handleDeepLink(Uri uri) {
    if (_isProcessingLink) return;
    if (uri.path.contains('/registration')) {
      final String? token = uri.queryParameters['token'];
      if (token != null && token.isNotEmpty) {
        _isProcessingLink = true;
        _confirmAccount(token);
      }
    }
  }

  Future<void> _onNotificationClick(String? payload) async {
    if (payload != null) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => DataEntryScreen(initialDialog: payload),
        ),
      );
    }
  }

  Future<void> _confirmAccount(String token) async {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final url = Uri.parse(
        'https://health-sync.online/registration/api/confirm',
      );
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'token': token}),
          )
          .timeout(const Duration(seconds: 10));

      if (mounted && Navigator.canPop(context)) Navigator.of(context).pop();

      final data = jsonDecode(response.body);
      final bool success = data['success'] ?? false;
      final String message = data['message'] ?? 'Нет описания';

      if (!mounted) return;

      if (success) {
        final String jwt = data['token'];
        final String email = data['email'];
        final String role = data['role'];
        await context.read<AuthViewModel>().login(email, jwt, role);
        _showResultDialog("Успех!", "Аккаунт подтвержден. Роль: $role", true);
      } else {
        _showResultDialog("Ошибка", message, false);
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.of(context).pop();
      _showResultDialog("Ошибка сети", "Не удалось соединиться: $e", false);
    } finally {
      _isProcessingLink = false;
    }
  }

  void _showResultDialog(String title, String content, bool isSuccess) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          title,
          style: TextStyle(color: isSuccess ? Colors.green : Colors.red),
        ),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileVM = context.watch<ProfileViewModel>();

    if (profileVM.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return profileVM.hasProfile ? const MainScreen() : const OnboardingScreen();
  }
}
