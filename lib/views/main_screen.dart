import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/tracker_view_model.dart';
import '../main.dart';
import 'home_screen.dart';
import 'data_entry_screen.dart';
import 'recommendations_screen.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pageVM = context.watch<PageViewModel>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final List<Widget> screens = [
      const RecommendationsScreen(),
      const HomeScreen(),
      const DataEntryScreen(),
    ];

    return Scaffold(
      body: PageView(
        controller: pageVM.pageController,
        onPageChanged: (index) {
          pageVM.onPageChanged(index);
          if (index == 1) {
            context.read<TrackerViewModel>().loadDashboardData();
          }
        },
        children: screens,
      ),

      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorColor: AppColors.primary.withValues(alpha: 0.15),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              );
            }
            return TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
            );
          }),
        ),
        child: NavigationBar(
          height: 65,
          backgroundColor: theme.cardColor,
          surfaceTintColor: Colors.transparent,
          elevation: 16,
          shadowColor: Colors.black.withValues(alpha: 0.3),
          selectedIndex: pageVM.currentIndex,
          onDestinationSelected: (index) {
            pageVM.setPage(index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.lightbulb_outline),
              selectedIcon: Icon(Icons.lightbulb, color: AppColors.primary),
              label: 'Советы',
            ),
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: AppColors.primary),
              label: 'Главная',
            ),
            NavigationDestination(
              icon: Icon(Icons.add_circle_outline),
              selectedIcon: Icon(Icons.add_circle, color: AppColors.primary),
              label: 'Внести',
            ),
          ],
        ),
      ),
    );
  }
}
