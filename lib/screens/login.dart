import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/user_service.dart';
import '../ui/components/reusable_card.dart';
import '../ui/components/buttons.dart';
import '../ui/theme.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback? onLoggedIn;

  const LoginScreen({super.key, this.onLoggedIn});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _areaController = TextEditingController();

  bool _isSubmitting = false;
  bool _isLogin = true;
  String? _error;

  final UserService _userService = UserService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _locationController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final googleUser = await GoogleSignIn(scopes: ['email']).signIn();
      if (googleUser == null) {
        // User cancelled
        if (mounted) setState(() => _isSubmitting = false);
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result =
          await FirebaseAuth.instance.signInWithCredential(credential);

      if (result.user != null) {
        // Try to check/create profile, but don't block login on failure
        try {
          final existing = await _userService.getUser(result.user!.uid);
          if (existing == null) {
            await _userService.saveUser(UserProfile(
              uid: result.user!.uid,
              email: result.user!.email ?? '',
              fullName: result.user!.displayName ?? 'Farmer',
              farmLocation: 'Unknown',
              farmArea: 'Unknown',
              photoUrl: result.user!.photoURL,
            ));
          }
        } catch (e) {
          debugPrint("Profile creation failed (Google): $e");
          // Continue anyway, it's not fatal for login
        }
      }

      widget.onLoggedIn?.call();
    } catch (e) {
      debugPrint("Google Sign In Error: $e");
      setState(() => _error = 'Google sign-in failed. Check connection.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submit() async {
    setState(() => _error = null);

    // Only validate fields relevant to the current mode
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    setState(() => _isSubmitting = true);

    try {
      final auth = FirebaseAuth.instance;

      if (_isLogin) {
        // --- LOGGING IN ---
        await auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        widget.onLoggedIn?.call();
      } else {
        // --- SIGNING UP ---
        final userCredential = await auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (userCredential.user != null) {
          await userCredential.user!
              .updateDisplayName(_nameController.text.trim());

          try {
            final profile = UserProfile(
              uid: userCredential.user!.uid,
              email: _emailController.text.trim(),
              fullName: _nameController.text.trim(),
              farmLocation: _locationController.text.trim(),
              farmArea: _areaController.text.trim(),
              photoUrl: userCredential.user!.photoURL,
            );
            await _userService.saveUser(profile);
          } catch (e) {
            debugPrint("Failed to save extended profile: $e");
            // User created in Auth, so we can proceed, but maybe warn user?
            // optimizing for UX: let them in.
          }
        }
        widget.onLoggedIn?.call();
      }
    } on FirebaseAuthException catch (e) {
      String msg = 'Authentication failed';
      if (e.code == 'user-not-found')
        msg = 'No user found with this email.';
      else if (e.code == 'wrong-password')
        msg = 'Incorrect password.';
      else if (e.code == 'email-already-in-use')
        msg = 'Email already registered.';
      else if (e.code == 'weak-password')
        msg = 'Password is too weak.';
      else
        msg = e.message ?? msg;

      setState(() => _error = msg);
    } catch (e) {
      debugPrint("Login Error: $e");
      setState(() => _error =
          'An unexpected error occurred. Restart app if this persists.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              height: 220,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryGreen, AppTheme.lightGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 44,
                        width: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child:
                            const Icon(Icons.agriculture, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('FarmWise',
                              style: textTheme.titleMedium
                                  ?.copyWith(color: Colors.white)),
                          Text('Plan. Grow. Thrive.',
                              style: textTheme.bodySmall
                                  ?.copyWith(color: Colors.white70)),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    _isLogin ? 'Welcome back' : 'Join FarmWise',
                    style:
                        textTheme.headlineSmall?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isLogin
                        ? 'Sign in to plan smarter with FarmWise.'
                        : 'Create your account to get started.',
                    style: textTheme.bodyMedium
                        ?.copyWith(color: Colors.white.withOpacity(0.9)),
                  ),
                ],
              ),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 200, 16, 24),
              child: Column(
                children: [
                  ReusableCard(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Show error at top for visibility
                          if (_error != null) ...[
                            Container(
                              padding: const EdgeInsets.all(10),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline,
                                      color: Colors.red, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(_error!,
                                        style: textTheme.bodySmall?.copyWith(
                                            color: Colors.red.shade900)),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          if (!_isLogin) ...[
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text('Full Name',
                                  style: textTheme.bodyMedium),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _nameController,
                              textCapitalization: TextCapitalization.words,
                              decoration:
                                  const InputDecoration(hintText: 'John Doe'),
                              validator: (val) =>
                                  !_isLogin && (val == null || val.isEmpty)
                                      ? 'Enter your name'
                                      : null,
                            ),
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text('Farm Location',
                                  style: textTheme.bodyMedium),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _locationController,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                  hintText: 'e.g. Adama, Ethiopia'),
                              validator: (val) =>
                                  !_isLogin && (val == null || val.isEmpty)
                                      ? 'Enter farm location'
                                      : null,
                            ),
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text('Farm Area',
                                  style: textTheme.bodyMedium),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _areaController,
                              decoration: const InputDecoration(
                                  hintText: 'e.g. 5 hectares'),
                              validator: (val) =>
                                  !_isLogin && (val == null || val.isEmpty)
                                      ? 'Enter farm area'
                                      : null,
                            ),
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 16),
                          ],

                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Email', style: textTheme.bodyMedium),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                                hintText: 'farmer@example.com'),
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return 'Enter your email';
                              if (!value.contains('@'))
                                return 'Enter a valid email';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerLeft,
                            child:
                                Text('Password', style: textTheme.bodyMedium),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(hintText: ''),
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return 'Enter your password';
                              if (value.length < 6)
                                return 'At least 6 characters';
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          PrimaryButton(
                            label: _isSubmitting
                                ? (_isLogin
                                    ? 'Signing in...'
                                    : 'Creating account...')
                                : (_isLogin ? 'Sign in' : 'Create account'),
                            icon: _isSubmitting
                                ? Icons.hourglass_bottom
                                : Icons.lock_open,
                            onPressed: _isSubmitting ? null : _submit,
                          ),
                          const SizedBox(height: 12),
                          if (_isLogin)
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.login),
                                label: Text(_isSubmitting
                                    ? 'Please wait...'
                                    : 'Continue with Google'),
                                onPressed:
                                    _isSubmitting ? null : _signInWithGoogle,
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(48),
                                  foregroundColor: AppTheme.primaryGreen,
                                  side: const BorderSide(
                                      color: AppTheme.primaryGreen),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                          SecondaryButton(
                            label: _isLogin
                                ? 'Need an account? Sign up'
                                : 'Have an account? Sign in',
                            icon: Icons.swap_horiz,
                            onPressed: _isSubmitting
                                ? null
                                : () => setState(() {
                                      _isLogin = !_isLogin;
                                      _error = null;
                                    }),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'New to FarmWise? Create an account and start planning smarter.',
                    style: textTheme.bodySmall
                        ?.copyWith(color: AppTheme.darkGray.withOpacity(0.7)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
