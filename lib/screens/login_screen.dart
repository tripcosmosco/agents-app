import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/google_logo.dart';

/// Modern AI Web-app style Authentication Screen (Claude / ChatGPT pattern)
class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginScreen({
    super.key,
    required this.onLoginSuccess,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _showWpCredentials = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleGoogleLogin() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.signInWithGoogle();
    if (success && mounted) {
      widget.onLoginSuccess();
    } else if (mounted) {
      if (auth.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            backgroundColor: const Color(0xFFDC2626),
            content: Text(
              auth.errorMessage!,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _handleWpLogin() async {
    final user = _usernameController.text.trim();
    final pass = _passwordController.text;

    if (user.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Please enter username and password.'),
        ),
      );
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.loginWithCredentials(username: user, password: pass);
    if (success && mounted) {
      widget.onLoginSuccess();
    } else if (mounted && auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          backgroundColor: const Color(0xFFDC2626),
          content: Text(auth.errorMessage!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Emblem & Header (Claude / ChatGPT style)
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: AppColors.goldGradient,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentGold.withValues(alpha: 0.28),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'X',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Welcome to X-Agents',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.getTextPrimary(context),
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Log in with your Google or WordPress account to access your AI Telephony & Operations CRM.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: AppColors.getTextSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Standard AI Website "Continue with Google" Button (Claude / ChatGPT style)
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: auth.isLoading ? null : _handleGoogleLogin,
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: isLight ? Colors.white : const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isLight ? 0.04 : 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (auth.isLoading)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            const GoogleLogo(size: 20),
                          const SizedBox(width: 12),
                          Text(
                            auth.isLoading ? 'Connecting to Google...' : 'Continue with Google',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isLight ? const Color(0xFF0F172A) : Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Minimalist Divider (ChatGPT / Claude pattern)
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: AppColors.getTextMuted(context),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Alternative Login: WordPress CRM Credentials
                  if (!_showWpCredentials)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.password_rounded, size: 18),
                      label: const Text('Sign in with WordPress Username / Password'),
                      onPressed: () => setState(() => _showWpCredentials = true),
                    )
                  else
                    GlassCard(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'WordPress CRM Login',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.getTextPrimary(context),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => setState(() => _showWpCredentials = false),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _usernameController,
                            style: TextStyle(color: AppColors.getTextPrimary(context), fontSize: 14),
                            decoration: InputDecoration(
                              labelText: 'Username or Email',
                              labelStyle: TextStyle(fontSize: 13, color: AppColors.getTextSecondary(context)),
                              prefixIcon: const Icon(Icons.mail_outline_rounded, size: 18),
                              filled: true,
                              fillColor: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: TextStyle(color: AppColors.getTextPrimary(context), fontSize: 14),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: TextStyle(fontSize: 13, color: AppColors.getTextSecondary(context)),
                              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
                              filled: true,
                              fillColor: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 1,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: auth.isLoading ? null : _handleWpLogin,
                            child: Text(
                              auth.isLoading ? 'Authenticating...' : 'Continue',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 28),

                  // Bottom Security Notice (Claude / ChatGPT style)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.verified_user_outlined, size: 14, color: AppColors.successGreen),
                      const SizedBox(width: 6),
                      Text(
                        'Secured by Google Cloud & WordPress Enterprise RBAC',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.getTextMuted(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
