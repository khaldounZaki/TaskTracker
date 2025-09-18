import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/auth_service.dart';
import '../../utils/helpers.dart';
import '../../utils/theme.dart'; // 👈 Import centralized theme

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _passwordVisible = false;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);

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

              // Title
              Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.whiteSubtitle,
                ),
              ),
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
                        controller: _nameCtrl,
                        decoration: AppTheme.inputDecoration(
                          label: "Full name",
                          icon: Icons.person,
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: _mobileCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: AppTheme.inputDecoration(
                          label: "Mobile",
                          icon: Icons.phone,
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: AppTheme.inputDecoration(
                          label: "Email",
                          icon: Icons.email,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Password with toggle 👇
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

                      // Register Button
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
                                      await auth.registerWithEmail(
                                        email: _emailCtrl.text.trim(),
                                        password: _passCtrl.text.trim(),
                                        name: _nameCtrl.text.trim(),
                                        mobile: _mobileCtrl.text.trim(),
                                      );
                                      showSuccess(
                                        context,
                                        'Registered successfully. Wait for admin activation.',
                                      );
                                      Navigator.pop(context);
                                    } catch (e) {
                                      showError(
                                        context,
                                        'Registration failed: $e',
                                      );
                                    }
                                    setState(() => _loading = false);
                                  },
                                  child: const Text(
                                    'Register',
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

                      // Back to Login
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Already have an account? Sign in',
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
