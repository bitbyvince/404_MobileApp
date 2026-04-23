import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'calendar_screen.dart';
import 'notifications_screen.dart';

class MainNavigationWrapper extends StatefulWidget {
  const MainNavigationWrapper({super.key});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _currentIndex = 0;
  bool _tasksCompleted = false;

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(
        tasksCompleted: _tasksCompleted,
        onTasksCompleted: _setTasksCompleted,
      ),
      CalendarScreen(
        tasksCompleted: _tasksCompleted,
        onTasksCompleted: _setTasksCompleted,
      ),
      const NotificationsScreen(),
    ];
  }

  void _setTasksCompleted() {
    setState(() {
      _tasksCompleted = true;
      _screens[0] = HomeScreen(
        tasksCompleted: _tasksCompleted,
        onTasksCompleted: _setTasksCompleted,
      );
      _screens[1] = CalendarScreen(
        tasksCompleted: _tasksCompleted,
        onTasksCompleted: _setTasksCompleted,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Colors.white,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
        ],
      ),
    );
  }
}
