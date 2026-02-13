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

      bottomNavigationBar: NavigationBar(
        selectedIndex: pageVM.currentIndex,
        onDestinationSelected: (index) {
          pageVM.setPage(index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.lightbulb_outline),
            selectedIcon: Icon(Icons.lightbulb),
            label: 'Советы',
          ),
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Главная',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Внести',
          ),
        ],
      ),
    );
  }
}
