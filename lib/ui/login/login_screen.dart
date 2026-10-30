import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';
import '../../cubits/permission/permission_cubit.dart';
import '../../services/sync_service.dart';
import '../navigation/main_navigation_screen.dart';
import '../permission_setup/permission_setup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberUsername = false;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthCubit>().state;
    if (authState is Unauthenticated && authState.savedUsername != null) {
      _usernameController.text = authState.savedUsername!;
      _rememberUsername = true;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    context.read<AuthCubit>().login(
          usernameOrEmail: _usernameController.text,
          password: _passwordController.text,
          rememberUsername: _rememberUsername,
        );
  }

  void _onAuthStateChanged(BuildContext context, AuthState state) async {
    final navigator = Navigator.of(context);

    if (state is Authenticated) {
      // Trigger first sync in background
      SyncService.instance.runSync(trigger: 'app_open');

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
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: _onAuthStateChanged,
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        final lockoutSeconds =
            state is Unauthenticated ? state.lockoutSeconds : 0;
        final isLockedOut = lockoutSeconds > 0;
        final errorMessage =
            state is Unauthenticated ? state.errorMessage : null;

        return Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            'assets/images/logo.jpeg',
                            width: 76,
                            height: 76,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Admin Login',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Authenticate to enable auto-approvals & sync',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Username/Email Field
                      TextFormField(
                        controller: _usernameController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email / Username / Phone',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter username or email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),

                      // Remember Username
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberUsername,
                            onChanged: (val) {
                              setState(() {
                                _rememberUsername = val ?? false;
                              });
                            },
                          ),
                          const Text('Remember username'),
                        ],
                      ),

                      // Error or Lockout Message
                      if (isLockedOut) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text(
                            'Too many failed attempts. Try again in $lockoutSeconds seconds.',
                            style: const TextStyle(
                                color: Colors.red, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ] else if (errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          errorMessage,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 24),

                      // Login Button
                      ElevatedButton(
                        onPressed:
                            (isLoading || isLockedOut) ? null : _onLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Log In',
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
            ),
          ),
        );
      },
    );
  }
}
