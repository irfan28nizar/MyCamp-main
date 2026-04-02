import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mycamp_app/features/auth/data/repositories/supabase_auth_repository.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final SupabaseAuthRepository _authRepository = SupabaseAuthRepository();
  bool _isLoading = false;
  bool _emailSent = false;

  bool get _isResetEnabled => _emailController.text.trim().isNotEmpty;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    setState(() => _isLoading = true);

    final success = await _authRepository.resetPassword(
      _emailController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      setState(() => _emailSent = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent! Check your inbox.'),
          backgroundColor: Color(0xFF1DA0AA),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send reset email. Try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/auth/login_bg.png',
              fit: BoxFit.cover,
              alignment: const Alignment(0.4, 0.4),
            ),
          ),

          // Dark overlay for readability
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.30),
            ),
          ),

          // Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(cardRadius),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.88,
                      padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.24),
                        borderRadius: BorderRadius.circular(cardRadius),
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
                          // Back button
                          Align(
                            alignment: Alignment.topLeft,
                            child: IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back),
                              color: textPrimary,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Logo
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
                                Icons.lock_reset,
                                size: 32,
                                color: primaryTeal,
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Title
                          const Text(
                            'Reset Password',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Subtitle
                          const Text(
                            'Enter your email to receive a password reset link',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: textMuted,
                            ),
                          ),

                          const SizedBox(height: 28),

                          if (_emailSent) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF4CAF50),
                                ),
                              ),
                              child: const Column(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Color(0xFF4CAF50),
                                    size: 32,
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'Email sent successfully!',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF2E7D32),
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Check your inbox for the password reset link.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF558B2F),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ] else ...[
                            // Email field
                            SizedBox(
                              height: 52,
                              child: TextFormField(
                                controller: _emailController,
                                onChanged: (_) => setState(() {}),
                                textInputAction: TextInputAction.done,
                                keyboardType: TextInputType.emailAddress,
                                enabled: !_isLoading,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: textPrimary,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'your.email@example.com',
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

                            const SizedBox(height: 24),

                            // Reset button
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
                                  onPressed: (_isResetEnabled && !_isLoading)
                                      ? _handleResetPassword
                                      : null,
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
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child:
                                              CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                          ),
                                        )
                                      : const Text(
                                          'SEND RESET LINK',
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
                          ],

                          const SizedBox(height: 16),

                          // Back to login
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'Back to Login',
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
