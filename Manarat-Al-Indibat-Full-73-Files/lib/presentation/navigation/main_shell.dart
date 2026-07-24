import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "../screens/dashboard/dashboard_screen.dart";
import "../screens/schedule/schedule_screen.dart";
import "../screens/habits/habits_screen.dart";
import "../../core/theme/app_colors.dart";

/// Root navigation shell — bottom nav across the three primary sections.
/// Goals/Statistics/Achievements/Notebook/Settings tabs are next in the
/// roadmap (see README).
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  final _screens = const [
    DashboardScreen(),
    ScheduleScreen(),
    HabitsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        extendBody: true,
        body: Container(
          decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
          child: SafeArea(child: _screens[_index]),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) {
            HapticFeedback.selectionClick();
            setState(() => _index = i);
          },
          backgroundColor: AppColors.surfaceElevated,
          indicatorColor: AppColors.primary.withOpacity(0.18),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: "الرئيسية",
            ),
            NavigationDestination(
              icon: Icon(Icons.today_outlined),
              selectedIcon: Icon(Icons.today),
              label: "اليوم",
            ),
            NavigationDestination(
              icon: Icon(Icons.local_fire_department_outlined),
              selectedIcon: Icon(Icons.local_fire_department),
              label: "العادات",
            ),
          ],
        ),
      ),
    );
  }
}
