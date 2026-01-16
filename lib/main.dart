import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'ui/theme.dart';
import 'screens/home.dart';
import 'screens/planner.dart';
import 'screens/market.dart';
import 'screens/profile.dart';
import 'screens/splash.dart';
import 'screens/login.dart';
import 'screens/verify_email.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FarmWiseApp());
}

class FarmWiseApp extends StatefulWidget {
  const FarmWiseApp({super.key});

  static final ValueNotifier<ThemeMode> themeNotifier =
      ValueNotifier(ThemeMode.light);

  @override
  _FarmWiseAppState createState() => _FarmWiseAppState();
}

class _FarmWiseAppState extends State<FarmWiseApp> {
  int _selectedIndex = 0;
  bool _firebaseReady = false;
  String? _initError;
  User? _user;
  StreamSubscription<User?>? _authSub;

  // Track if we manually passed verification (for the session)
  bool _manuallyVerified = false;

  final List<Widget> _screens = [
    HomeScreen(),
    MarketScreen(),
    PlannerScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initFirebase();
  }

  Future<void> _initFirebase() async {
    try {
      await Firebase.initializeApp();
      if (!mounted) return;
      _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
        if (!mounted) return;
        setState(() {
          _firebaseReady = true;
          _user = user;
          // If no user, reset index and verification tracking
          if (user == null) {
            _selectedIndex = 0;
            _manuallyVerified = false;
          }
        });
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _initError = e.toString());
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine if we should show the Verify Email Screen
    // Condition: User is logged in AND (Email is not verified AND Verification not manually skipped/confirmed this session)
    bool showVerification =
        _user != null && !_user!.emailVerified && !_manuallyVerified;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: FarmWiseApp.themeNotifier,
      builder: (_, mode, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'FarmWise',
          theme: AppTheme.theme(),
          darkTheme: AppTheme.darkTheme(),
          themeMode: mode,
          home: !_firebaseReady
              ? const SplashScreen()
              : _initError != null
                  ? Scaffold(
                      body: Center(
                          child: Text('Firebase init error:\n$_initError')))
                  : (_user == null)
                      ? LoginScreen(onLoggedIn: () {})
                      : showVerification
                          ? VerifyEmailScreen(onVerified: () {
                              setState(() {
                                _manuallyVerified = true;
                              });
                            })
                          : Scaffold(
                              body: IndexedStack(
                                index: _selectedIndex,
                                children: _screens,
                              ),
                              bottomNavigationBar: BottomNavigationBar(
                                currentIndex: _selectedIndex,
                                onTap: _onItemTapped,
                                items: const [
                                  BottomNavigationBarItem(
                                      icon: Icon(Icons.home), label: 'Home'),
                                  BottomNavigationBarItem(
                                      icon: Icon(Icons.store), label: 'Market'),
                                  BottomNavigationBarItem(
                                      icon: Icon(Icons.calendar_today),
                                      label: 'Planner'),
                                  BottomNavigationBarItem(
                                      icon: Icon(Icons.person),
                                      label: 'Profile'),
                                ],
                              ),
                            ),
        );
      },
    );
  }
}
