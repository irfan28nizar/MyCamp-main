import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mycamp_app/features/auth/data/repositories/supabase_auth_repository.dart';
import 'package:mycamp_app/features/auth/presentation/screens/change_password_screen.dart';
import 'package:mycamp_app/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:mycamp_app/features/home/presentation/screens/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final SupabaseAuthRepository _authRepository = SupabaseAuthRepository();
  bool _isLoading = false;

  bool get _isLoginEnabled =>
      _emailController.text.trim().isNotEmpty &&
      _passwordController.text.isNotEmpty;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);

    final user = await _authRepository.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (user != null) {
      // Check if user must change their password (first login)
      if (_authRepository.mustChangePassword) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const ChangePasswordScreen(),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const HomeScreen(),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid email or password'),
        ),
      );
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);

    try {
      final user = await _authRepository.loginWithGoogle();

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (user != null) {
        // Check if user must change their password (first login with Google)
        if (_authRepository.mustChangePassword) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const ChangePasswordScreen(),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const HomeScreen(),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google login failed. Try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      debugPrint('Google login error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login error. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🎯 DESIGN CONSTANTS (MATCHES REFERENCE IMAGE)
    const cardRadius = 24.0;
    const fieldRadius = 14.0;

    const primaryTeal = Color(0xFF1DA0AA);
    const accentCyan = Color(0xFF39C3CF);

    const textPrimary = Color(0xFF1E1F22);
    const textMuted = Color(0xFF6A7075);
    const footerTeal = Color(0xFF256A6B);

    return Scaffold(
      body: Stack(
        children: [
          // 🔹 Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/auth/login_bg.png',
              fit: BoxFit.cover,
              alignment: const Alignment(0.4, 0.4)
            ),
          ),

          // 🔹 Dark overlay for readability
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.30),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(cardRadius),
                  child: BackdropFilter(
                    filter:
                        ImageFilter.blur(sigmaX: 5,  sigmaY: 5), // ✅ correct blur
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.88,
                      padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.24),
                        borderRadius:
                            BorderRadius.circular(cardRadius),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                          width: 1,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x26000000),
                            blurRadius: 24,
                            offset: Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 🔹 Logo
                          Align(
                            alignment: Alignment.center,
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFE9FCFD),
                                    Color(0xFFCDECF0)
                                  ],
                                ),
                              ),
                              child: const Icon(
                                Icons.explore,
                                size: 32,
                                color: primaryTeal,
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // 🔹 App title
                          const Text(
                            'MyCamp',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),

                          const SizedBox(height: 6),

                          const Text(
                            'Campus Navigation',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: textPrimary,
                            ),
                          ),

                          const SizedBox(height: 32),

                          // 🔹 Email field
                          SizedBox(
                            height: 52,
                            child: TextFormField(
                              controller: _emailController,
                              onChanged: (_) => setState(() {}),
                              textInputAction: TextInputAction.next,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(
                                fontSize: 16,
                                color: textPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Email',
                                hintStyle: const TextStyle(
                                  color: textMuted,
                                  fontSize: 16,
                                ),
                                prefixIcon:
                                    const Icon(Icons.email_outlined),
                                prefixIconColor: primaryTeal,
                                filled: true,
                                fillColor:
                                    Colors.white.withValues(alpha: 0.65),
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(fieldRadius),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(fieldRadius),
                                  borderSide: const BorderSide(
                                    color: primaryTeal,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // 🔹 Password field
                          SizedBox(
                            height: 52,
                            child: TextFormField(
                              controller: _passwordController,
                              onChanged: (_) => setState(() {}),
                              obscureText: true,
                              textInputAction: TextInputAction.done,
                              style: const TextStyle(
                                fontSize: 16,
                                color: textPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Password',
                                hintStyle: const TextStyle(
                                  color: textMuted,
                                  fontSize: 16,
                                ),
                                prefixIcon:
                                    const Icon(Icons.lock_outline),
                                prefixIconColor: primaryTeal,
                                filled: true,
                                fillColor:
                                    Colors.white.withValues(alpha: 0.65),
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(fieldRadius),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(fieldRadius),
                                  borderSide: const BorderSide(
                                    color: primaryTeal,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 22),

                          // 🔹 Login button
                          SizedBox(
                            height: 48,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [primaryTeal, accentCyan],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x33195457),
                                    blurRadius: 16,
                                    offset: Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed:
                                    (_isLoginEnabled && !_isLoading) ? _handleLogin : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  disabledBackgroundColor:
                                      Colors.white.withValues(alpha: 0.4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  'LOGIN',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.8,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          // 🔹 Divider with text
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  thickness: 1,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Text(
                                  'OR',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  thickness: 1,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 18),

                          // 🔹 Google Login button
                          SizedBox(
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: _isLoading ? null : _handleGoogleLogin,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  width: 1.5,
                                ),
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: _isLoading
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.g_mobiledata,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                              label: const Text(
                                'Sign in with Google',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          // 🔹 Forgot password
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ForgotPasswordScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: footerTeal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
