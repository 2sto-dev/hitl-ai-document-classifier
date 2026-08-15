import 'package:flutter/material.dart';

import 'screens/auth/login_screen.dart';
import 'screens/auth/profile_screen.dart';
import 'screens/auth/settings_screen.dart';
import 'theme/app_theme.dart';
import 'screens/dashboards/dashboard_screen.dart';
import 'screens/review/review_screen.dart';
import 'screens/history/history_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  bool _showProfilePage = false;
  bool _isAuthenticated = AuthService.isSignedIn;

  @override
  void initState() {
    super.initState();
    AuthService.authenticationState.addListener(_handleAuthenticationChange);
  }

  @override
  void dispose() {
    AuthService.authenticationState.removeListener(_handleAuthenticationChange);
    super.dispose();
  }

  void _handleAuthenticationChange() {
    if (!mounted) return;
    setState(() {
      _isAuthenticated = AuthService.authenticationState.value;
      if (!_isAuthenticated) {
        _selectedIndex = 0;
        _showProfilePage = false;
      }
    });
  }

  static const List<Widget> _pages = [
    ReviewScreen(),
    DashboardScreen(),
    HistoryScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _showProfilePage = false;
    });
  }

  void _showProfile() {
    setState(() {
      _showProfilePage = true;
    });
  }

  void _onLoginSuccess() {
    setState(() {
      _isAuthenticated = true;
    });
  }

  Future<void> _handleSignOut() async {
    await AuthService.logout();
    setState(() {
      _isAuthenticated = false;
      _selectedIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) {
      return LoginScreen(onLoginSuccess: _onLoginSuccess);
    }

    final isWide = MediaQuery.of(context).size.width >= 900;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        toolbarHeight: 64,
        titleSpacing: 8,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                gradient: AppColors.buttonGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shield_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                isWide ? 'HITL AI Classifier' : 'HITL AI',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            color: AppColors.surface,
            tooltip: 'Account menu',
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.secondary.withAlpha(150)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_outline, color: AppColors.accent, size: 19),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: isWide ? 150 : 78),
                    child: Text(
                      AuthService.username ?? 'Reviewer',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 18),
                ],
              ),
            ),
            onSelected: (value) async {
              switch (value) {
                case 'profile':
                  _showProfile();
                  break;
                case 'settings':
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                  break;
                case 'logout':
                  await _handleSignOut();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'profile', child: Text('Profile')),
              const PopupMenuItem(value: 'settings', child: Text('Settings')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'logout', child: Text('Log out')),
            ],
          ),
        ],
      ),
      body: AppGradientBackground(
        child: Row(
          children: [
          if (isWide)
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onItemTapped,
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.rate_review),
                  selectedIcon: Icon(Icons.rate_review, color: AppColors.accent),
                  label: Text('AI Review Workspace'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard),
                  selectedIcon: Icon(Icons.dashboard, color: AppColors.accent),
                  label: Text('Dashboard'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.history),
                  selectedIcon: Icon(Icons.history, color: AppColors.accent),
                  label: Text('Decision History'),
                ),
              ],
            )
          else
            const SizedBox.shrink(),
          Expanded(
            child: _showProfilePage
                ? const ProfileScreen()
                : _pages[_selectedIndex],
          ),
          ],
        ),
      ),
      drawer: isWide
          ? null
          : Drawer(
              child: ListView(
                padding: EdgeInsets.only(
                  top: MediaQuery.paddingOf(context).top + 20,
                ),
                children: [
                  ListTile(
                    leading: const Icon(Icons.rate_review),
                    title: const Text('AI Review Workspace'),
                    onTap: () {
                      Navigator.of(context).pop();
                      _onItemTapped(0);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.dashboard),
                    title: const Text('Dashboard'),
                    onTap: () {
                      Navigator.of(context).pop();
                      _onItemTapped(1);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.history),
                    title: const Text('Decision History'),
                    onTap: () {
                      Navigator.of(context).pop();
                      _onItemTapped(2);
                    },
                  ),
                  const Divider(color: Colors.white12),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Sign out'),
                    onTap: () async {
                      Navigator.of(context).pop();
                      await _handleSignOut();
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
