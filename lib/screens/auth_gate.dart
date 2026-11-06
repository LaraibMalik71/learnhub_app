import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/onboarding_service.dart';

import 'home_screen.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';
import 'splash_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final OnboardingService _onboardingService = OnboardingService();

  late final Future<bool> _onboardingFuture;

  bool _showOnboarding = false;
  bool _onboardingCompleted = false;

  @override
  void initState() {
    super.initState();

    _onboardingFuture = _onboardingService.isOnboardingCompleted();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Wait until Firebase checks the current authentication state.
        if (!authProvider.isInitialized) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Show HomeScreen when the user is logged in.
        if (authProvider.isAuthenticated) {
          return const HomeScreen();
        }

        // Check whether onboarding has already been completed.
        return FutureBuilder<bool>(
          future: _onboardingFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return const Scaffold(
                body: Center(
                  child: Text('Unable to load LearnHub. Please restart.'),
                ),
              );
            }

            // Show LoginScreen after onboarding is completed.
            if (snapshot.data == true || _onboardingCompleted) {
              return const LoginScreen();
            }

            // Show OnboardingScreen after the splash screen.
            if (_showOnboarding) {
              return OnboardingScreen(
                onCompleted: () {
                  setState(() {
                    _onboardingCompleted = true;
                  });
                },
              );
            }

            // First launch: show SplashScreen for two seconds.
            return SplashScreen(
              onFinished: () {
                setState(() {
                  _showOnboarding = true;
                });
              },
            );
          },
        );
      },
    );
  }
}
