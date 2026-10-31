import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../widgets/glass_card.dart';

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
  bool _showWpCredentials = false;

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
            backgroundColor: const Color(0xFFDC2626),
            content: Text(auth.errorMessage!),
            duration: const Duration(seconds: 4),
          ),
        );
      }
      // Auto-expand WordPress credentials fields for immediate alternative login
      setState(() {
        _showWpCredentials = true;
      });
    }
  }

  void _handleWpLogin() async {
    final user = _usernameController.text.trim();
    final pass = _passwordController.text;

    if (user.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter username and password.')),
      );
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.loginWithCredentials(username: user, password: pass);
    if (success && mounted) {
      widget.onLoginSuccess();
    } else if (mounted && auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.redAccent, content: Text(auth.errorMessage!)),
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
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Emblem & Header
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: AppColors.goldGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentGold.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'X',
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'TripCosmos X-Agents',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.getTextPrimary(context),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'AI Telephony • Multi-Source Leads • Financial CRM',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.getTextSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Google 1-Click Sign In Button
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isLight ? Colors.white : const Color(0xFF1E293B),
                            foregroundColor: isLight ? Colors.black87 : Colors.white,
                            elevation: 2,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isLight ? Colors.grey.shade300 : AppColors.borderSubtle,
                              ),
                            ),
                          ),
                          icon: auth.isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Image.network(
                                  'https://www.gstatic.com/images/branding/product/1x/gsa_512dp.png',
                                  width: 22,
                                  height: 22,
                                  errorBuilder: (ctx, err, stack) => const Icon(Icons.login, size: 22, color: Colors.blue),
                                ),
                          label: Text(
                            auth.isLoading ? 'Verifying with Google...' : 'Continue with Google',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          onPressed: auth.isLoading ? null : _handleGoogleLogin,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.shield_outlined, size: 14, color: Colors.green),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Role automatically assigned from your WordPress profile (Sales Agent, Manager, Finance, Dispatcher).',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.getTextMuted(context),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: AppColors.getBorder(context))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.getTextMuted(context),
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: AppColors.getBorder(context))),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // WordPress Credentials Toggle or Form
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
                      padding: const EdgeInsets.all(20),
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
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.getTextPrimary(context),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () => setState(() => _showWpCredentials = false),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                              labelText: 'Username or Email',
                              prefixIcon: const Icon(Icons.person_outline),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: auth.isLoading ? null : _handleWpLogin,
                            child: Text(auth.isLoading ? 'Authenticating...' : 'Sign In'),
                          ),
                        ],
                      ),
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
