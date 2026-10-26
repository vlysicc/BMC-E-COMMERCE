import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Color authBlack = Color(0xFF101010);
const Color authCard = Color(0xFF191919);
const Color authGold = Color(0xFFD6B875);
const Color authGoldLight = Color(0xFFF0DDA5);
const Color authWhite = Color(0xFFF7F5EF);
const Color authMuted = Color(0xFFAAA69B);

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool isLogin = true;
  bool isLoading = false;
  bool hidePassword = true;
  String? message;
  bool messageIsError = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      message = null;
    });

    try {
      final supabase = Supabase.instance.client;
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (isLogin) {
        await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
      } else {
        final response = await supabase.auth.signUp(
          email: email,
          password: password,
        );

        if (response.session == null && mounted) {
          setState(() {
            message =
                'Account created! Check your email to confirm your account, '
                'then log in.';
            messageIsError = false;
          });
        } else if (mounted) {
          setState(() {
            message = 'Account created successfully.';
            messageIsError = false;
          });
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          message = e.message;
          messageIsError = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          message = 'Something went wrong. Please try again.';
          messageIsError = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  String? validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) return 'Email is required.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Enter a valid email address.';
    }

    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required.';
    }

    if (value.length < 6) {
      return 'Use at least 6 characters.';
    }

    return null;
  }

  InputDecoration inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: authMuted),
      prefixIcon: Icon(icon, color: authGold, size: 21),
      filled: true,
      fillColor: authCard,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 18,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF38352E)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: authGold, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: authBlack,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 28,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // BRAND
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 30,
                      ),
                      decoration: BoxDecoration(
                        color: authCard,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFF665735),
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: authGold,
                                width: 1.3,
                              ),
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF302A1D),
                                  Color(0xFF171717),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Icon(
                              Icons.favorite_rounded,
                              color: authGoldLight,
                              size: 34,
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'LuvJam',
                            style: TextStyle(
                              fontSize: 38,
                              letterSpacing: 2.5,
                              fontWeight: FontWeight.w900,
                              color: authWhite,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 52,
                            height: 2,
                            color: authGold,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'MATCHING FITS. TIMELESS CONNECTION.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              letterSpacing: 1.6,
                              fontWeight: FontWeight.w600,
                              color: authGold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    Text(
                      isLogin ? 'WELCOME BACK' : 'JOIN THE CLUB',
                      style: const TextStyle(
                        fontSize: 25,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w800,
                        color: authWhite,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      isLogin
                          ? 'Your next favorite fit is waiting.'
                          : 'Create your account and find your style.',
                      style: const TextStyle(
                        fontSize: 14,
                        color: authMuted,
                      ),
                    ),

                    const SizedBox(height: 26),

                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      style: const TextStyle(color: authWhite),
                      cursorColor: authGold,
                      decoration: inputDecoration(
                        'Email Address',
                        Icons.alternate_email_rounded,
                      ),
                      validator: validateEmail,
                    ),

                    const SizedBox(height: 17),

                    TextFormField(
                      controller: _passwordController,
                      obscureText: hidePassword,
                      autofillHints: [
                        isLogin
                            ? AutofillHints.password
                            : AutofillHints.newPassword,
                      ],
                      style: const TextStyle(color: authWhite),
                      cursorColor: authGold,
                      decoration: inputDecoration(
                        'Password',
                        Icons.lock_outline_rounded,
                      ).copyWith(
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              hidePassword = !hidePassword;
                            });
                          },
                          color: authMuted,
                          icon: Icon(
                            hidePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: validatePassword,
                    ),

                    if (!isLogin) ...[
                      const SizedBox(height: 17),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: hidePassword,
                        style: const TextStyle(color: authWhite),
                        cursorColor: authGold,
                        decoration: inputDecoration(
                          'Confirm Password',
                          Icons.verified_user_outlined,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password.';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match.';
                          }
                          return null;
                        },
                      ),
                    ],

                    if (message != null) ...[
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: messageIsError
                              ? const Color(0xFF351C1C)
                              : const Color(0xFF1B3025),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: messageIsError
                                ? Colors.redAccent.withAlpha(120)
                                : Colors.green.withAlpha(120),
                          ),
                        ),
                        child: Text(
                          message!,
                          style: TextStyle(
                            color: messageIsError
                                ? const Color(0xFFFF9C9C)
                                : const Color(0xFFB7E5C6),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 25),

                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: authGold,
                          foregroundColor: authBlack,
                          disabledBackgroundColor:
                              authGold.withAlpha(110),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 23,
                                height: 23,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: authBlack,
                                ),
                              )
                            : Text(
                                isLogin ? 'LOGIN' : 'CREATE ACCOUNT',
                                style: const TextStyle(
                                  fontSize: 14,
                                  letterSpacing: 1.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            isLogin
                                ? "Don't have an account?"
                                : 'Already a member?',
                            style: const TextStyle(
                              color: authMuted,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: isLoading
                              ? null
                              : () {
                                  setState(() {
                                    isLogin = !isLogin;
                                    message = null;
                                  });
                                },
                          child: Text(
                            isLogin ? 'Sign up' : 'Log in',
                            style: const TextStyle(
                              color: authGoldLight,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    const Center(
                      child: Text(
                        'LUVJAM  •  MADE FOR TWO',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 2,
                          color: Color(0xFF77736A),
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
    );
  }
}