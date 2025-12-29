import 'package:flutter/material.dart';
import 'home/__init__.dart';
import 'booking/__init__.dart';
import 'profile/__init__.dart';
import 'manage_slots/manage_slots_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late final PageController _pageController = PageController(initialPage: 0);
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;

  final List<Widget> _screens = [
    const HomeScreen(),
    const BookingsScreen(),
    const ManageSlotsScreen(),
    const ProfileScreen(),
  ];

  final List<String> _titles = [
    'Dashboard',
    'Manage Bookings',
    'Manage',
    'Profile',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeInOut,
    ));
    _animationController?.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController?.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });

      // Animate to the new page with smooth scrolling
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

      // Restart fade animation
      _animationController?.reset();
      _animationController?.forward();
    }
  }

  void _onPageChanged(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });

      // Restart fade animation
      _animationController?.reset();
      _animationController?.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient for smooth visual transition
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFAFAFA),
                  Colors.white,
                ],
              ),
            ),
          ),

          // PageView for smooth horizontal scrolling
          PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            physics: const NeverScrollableScrollPhysics(),
            children: _screens.map((screen) {
              return FadeTransition(
                opacity: _fadeAnimation ?? const AlwaysStoppedAnimation(1.0),
                child: screen,
              );
            }).toList(),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            selectedItemColor: const Color(0xFF6366F1),
            unselectedItemColor: const Color(0xFF6B7280),
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
            iconSize: 26,
            elevation: 0,
            items: [
            BottomNavigationBarItem(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(
                    scale: animation,
                    child: child,
                  );
                },
                child: Icon(
                  _selectedIndex == 0 ? Icons.home : Icons.home_outlined,
                  key: ValueKey<bool>(_selectedIndex == 0),
                  color: _selectedIndex == 0
                      ? const Color(0xFF6366F1)
                      : const Color(0xFF6B7280),
                ),
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(
                    scale: animation,
                    child: child,
                  );
                },
                child: Icon(
                  _selectedIndex == 1 ? Icons.local_parking : Icons.local_parking_outlined,
                  key: ValueKey<bool>(_selectedIndex == 1),
                  color: _selectedIndex == 1
                      ? const Color(0xFF6366F1)
                      : const Color(0xFF6B7280),
                ),
              ),
              label: 'Bookings',
            ),
            BottomNavigationBarItem(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(
                    scale: animation,
                    child: child,
                  );
                },
                child: Icon(
                  _selectedIndex == 2 ? Icons.calendar_today : Icons.calendar_today_outlined,
                  key: ValueKey<bool>(_selectedIndex == 2),
                  color: _selectedIndex == 2
                      ? const Color(0xFF6366F1)
                      : const Color(0xFF6B7280),
                ),
              ),
              label: 'Manage',
            ),
            BottomNavigationBarItem(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(
                    scale: animation,
                    child: child,
                  );
                },
                child: Icon(
                  _selectedIndex == 3 ? Icons.person : Icons.person_outline,
                  key: ValueKey<bool>(_selectedIndex == 3),
                  color: _selectedIndex == 3
                      ? const Color(0xFF6366F1)
                      : const Color(0xFF6B7280),
                ),
              ),
              label: 'Profile',
            ),
          ],
          ),
        ),
      ),
    );
  }
}
