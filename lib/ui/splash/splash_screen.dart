import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';
import '../../cubits/permission/permission_cubit.dart';
import '../login/login_screen.dart';
import '../navigation/main_navigation_screen.dart';
import '../permission_setup/permission_setup_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AuthCubit>().checkInitialSession();
      }
    });
  }

  void _onAuthStateChanged(BuildContext context, AuthState state) async {
    final navigator = Navigator.of(context);

    if (state is Authenticated) {
      final permCubit = context.read<PermissionCubit>();
      await permCubit.checkPermissions();
      if (!mounted) return;

      if (permCubit.state.canProceedToHome) {
        navigator.pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        );
      } else {
        navigator.pushReplacement(
          MaterialPageRoute(
            builder: (_) => const PermissionSetupScreen(isFirstRun: true),
          ),
        );
      }
    } else if (state is Unauthenticated || state is AuthExpired) {
      navigator.pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: _onAuthStateChanged,
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/logo.jpeg',
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Projonmo Admin',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
