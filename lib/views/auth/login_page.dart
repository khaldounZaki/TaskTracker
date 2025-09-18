import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/user_service.dart';
import '../../data/services/auth_service.dart';
import '../../utils/helpers.dart';
import '../../utils/theme.dart'; // 👈 Import centralized theme

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _checkingLogin = true;
  bool _passwordVisible = false;

  @override
  void initState() {
    super.initState();
    _checkAlreadyLoggedIn();
  }

  void _checkAlreadyLoggedIn() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final userService = Provider.of<UserService>(context, listen: false);
    final currentUser = auth.currentUser;

    if (currentUser != null) {
      final user = await userService.getUserById(currentUser.uid);
      if (user != null && user.active) {
        Navigator.pushReplacementNamed(context, '/dashboard');
        return;
      } else {
        await auth.signOut();
      }
    }
    setState(() => _checkingLogin = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingLogin) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final auth = Provider.of<AuthService>(context, listen: false);
    final userService = Provider.of<UserService>(context, listen: false);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Image.asset('assets/logo.png', height: 120),
              const SizedBox(height: 24),

              // Welcome Text
              Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.whiteSubtitle,
                ),
              ),
              const SizedBox(height: 8),
              // Text(
              //   'Sign in to continue to Team Task Manager',
              //   textAlign: TextAlign.center,
              //   style: TextStyle(fontSize: 16, color: AppTheme.subtitle),
              // ),
              const SizedBox(height: 32),

              // Form Card
              Card(
                elevation: AppTheme.cardTheme.elevation,
                shape: AppTheme.cardTheme.shape,
                shadowColor: AppTheme.cardTheme.shadowColor,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: _emailCtrl,
                        decoration: AppTheme.inputDecoration(
                          label: "Email",
                          icon: Icons.email,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Password with visibility toggle 👇
                      TextField(
                        controller: _passCtrl,
                        obscureText: !_passwordVisible,
                        decoration: AppTheme.inputDecoration(
                          label: "Password",
                          icon: Icons.lock,
                          isPassword: true,
                          togglePassword: () {
                            setState(() {
                              _passwordVisible = !_passwordVisible;
                            });
                          },
                          passwordVisible: _passwordVisible,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Sign In Button
                      _loading
                          ? const CircularProgressIndicator()
                          : SizedBox(
                              width: double.infinity,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: AppTheme.buttonGradient,
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                  ),
                                  onPressed: () async {
                                    setState(() => _loading = true);
                                    try {
                                      final cred = await auth.signInWithEmail(
                                        email: _emailCtrl.text.trim(),
                                        password: _passCtrl.text.trim(),
                                      );
                                      final uid = cred.user!.uid;
                                      final user = await userService
                                          .getUserById(uid);
                                      if (user == null || !user.active) {
                                        await auth.signOut();
                                        showError(
                                          context,
                                          'Account not active yet. Wait for admin activation.',
                                        );
                                      } else {
                                        Navigator.pushReplacementNamed(
                                          context,
                                          '/dashboard',
                                        );
                                      }
                                    } catch (e) {
                                      showError(
                                        context,
                                        'Sign in failed: ${e.toString()}',
                                      );
                                    }
                                    setState(() => _loading = false);
                                  },
                                  child: const Text(
                                    'Sign In',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.buttonText,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                      const SizedBox(height: 16),

                      // Register link
                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/register'),
                        child: Text(
                          'Create an account',
                          style: TextStyle(color: AppTheme.link),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
