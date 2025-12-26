import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'models/device_model.dart';
import 'screens/dashboard_screen.dart';
import 'screens/device_detail_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(
      path: '/welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (context, state) => const SignUpScreen()),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
      routes: [
        GoRoute(
          path: 'device-detail',
          builder: (context, state) {
            // ✅ Safe check before casting
            final extra = state.extra;
            if (extra is DeviceModel) {
              return DeviceDetailScreen(device: extra);
            } else {
              // Optional: show an error page if extra is missing or wrong type
              return Scaffold(
                appBar: AppBar(title: const Text("Error")),
                body: const Center(
                  child: Text(
                    "Device data not found",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              );
            }
          },
        ),
      ],
    ),
  ],
);
