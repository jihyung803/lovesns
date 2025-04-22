import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:new_couple_app/config/app_theme.dart';
import 'package:new_couple_app/services/auth_service.dart';
import 'package:new_couple_app/screens/feed/magical_feed_screen.dart';
import 'package:new_couple_app/screens/calendar/calendar_screen.dart';
import 'package:new_couple_app/screens/couple_room/mystical_room_screen.dart';
import 'package:new_couple_app/screens/profile/profile_screen.dart';
import 'package:new_couple_app/services/notification_service.dart';

class MysticalMainScreen extends StatefulWidget {
  const MysticalMainScreen({Key? key}) : super(key: key);

  @override
  State<MysticalMainScreen> createState() => _MysticalMainScreenState();
}

class _MysticalMainScreenState extends State<MysticalMainScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  late AnimationController _animationController;

  final List<Widget> _screens = [
    const MagicalFeedScreen(),
    const CalendarScreen(),
    const MysticalRoomScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onItemTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    // Check if user is connected with a partner
    if (user == null || user.partnerId == null || user.coupleId == null) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF2C1F4A), // Deep purple
                Color(0xFF0F0A1F), // Almost black with a hint of purple
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Cosmic illustration
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black12,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.person_search,
                    size: 50,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Message
                Text(
                  'Your cosmic journey awaits',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Connect with your partner to explore the universe together',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Connect button
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/magical-couple-connect');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 8,
                    shadowColor: AppTheme.primaryColor.withOpacity(0.5),
                  ),
                  child: const Text(
                    'Connect with Partner',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: _screens,
        physics: const NeverScrollableScrollPhysics(),
      ),
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              color: Colors.black.withOpacity(0.3),
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: _onItemTapped,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: AppTheme.primaryColor,
              unselectedItemColor: Colors.white70,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 11,
              ),
              items: [
                _buildNavItem(Icons.auto_awesome, Icons.home, 'Timeline', 0),
                _buildNavItem(Icons.calendar_today, Icons.calendar_today, 'Calendar', 1),
                _buildNavItem(Icons.weekend, Icons.weekend, 'Space', 2),
                _buildNavItem(Icons.person, Icons.person, 'Profile', 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData activeIcon, IconData inactiveIcon, String label, int index) {
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            Icon(
              _currentIndex == index ? activeIcon : inactiveIcon,
              size: _currentIndex == index ? 24 : 22,
            ),
            if (_currentIndex == index)
              Container(
                width: 5,
                height: 5,
                margin: const EdgeInsets.only(top: 3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryColor,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.5),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      label: label,
    );
  }
}
