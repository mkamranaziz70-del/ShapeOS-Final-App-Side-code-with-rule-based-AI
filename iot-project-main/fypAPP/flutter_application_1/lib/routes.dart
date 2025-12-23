import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/device_detail_screen.dart';
import 'models/device_model.dart';

final GoRouter router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),

    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
      routes: [
        GoRoute(
          path: 'device-detail',
          builder: (context, state) {
            final device = state.extra as DeviceModel?;

            if (device == null) {
              return const Scaffold(
                body: Center(child: Text('No device selected')),
              );
            }

            return DeviceDetailScreen(device: device);
          },
        ),
      ],
    ),
  ],
);
