import 'package:flutter/material.dart';
import 'package:ootdmate_frontend/screens/auth/register_screen.dart';
import 'package:ootdmate_frontend/services/auth-services/auth_services.dart';
import 'package:ootdmate_frontend/widgets/background_wrapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ootdmate_frontend/core/theme/app_theme.dart';
import 'package:ootdmate_frontend/widgets/ui/glass_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authServices = AuthServices();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _authServices.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } catch (e) {
      if (!mounted) return;
      _showError('Terjadi Error saat login : ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BackgroundWrapper(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'WELCOME BACK!',
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(
                              shadows: [
                                Shadow(
                                  color: AppTheme.textPrimary.withAlpha(70),
                                  offset: Offset(-10, 4),
                                  blurRadius: 10,
                                ),
                              ],
                              fontSize: 34,
                            ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Don\'t have an account?', style: Theme.of(context).textTheme.bodyMedium,),
                          TextButton(
                            onPressed: _isLoading
                                ? null
                                : () async {
                                    final registered =
                                        await Navigator.push<bool>(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const RegisterScreen(),
                                          ),
                                        );

                                    if (!context.mounted ||
                                        registered != true) {
                                      return;
                                    }
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Registration success. Check email to verify account',
                                        ),
                                      ),
                                    );
                                  },
                            child: Text(
                              'Sign Up',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(letterSpacing: 0, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Login to your account',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                      const SizedBox(height: 24),
                      GlassTextField(
                        hintText: "Email",
                        prefixIcon: Icons.mail,
                        controller: _emailController,
                      ),
                      const SizedBox(height: 10),
                      GlassTextField(
                        hintText: "Password",
                        prefixIcon: Icons.lock,
                        suffixIcon: _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        obscureText: _obscurePassword,
                        controller: _passwordController,
                        onSuffixIconPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Login',
                                  style: TextStyle(color: AppTheme.primary),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
