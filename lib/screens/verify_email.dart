import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../ui/components/buttons.dart';
import '../ui/components/reusable_card.dart';
import '../ui/theme.dart';

class VerifyEmailScreen extends StatefulWidget {
  final VoidCallback onVerified;

  const VerifyEmailScreen({super.key, required this.onVerified});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _isSending = false;
  bool _isChecking = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _sendVerificationEmail();
  }

  Future<void> _sendVerificationEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.emailVerified) {
      try {
        await user.sendEmailVerification();
        setState(() => _message = "Verification email sent to ${user.email}");
      } catch (e) {
        setState(() => _message = "Error sending email: $e");
      }
    }
  }

  Future<void> _checkVerification() async {
    setState(() => _isChecking = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Reload user to get updated emailVerified status
      await user.reload();
      final updatedUser = FirebaseAuth.instance.currentUser;

      if (updatedUser != null && updatedUser.emailVerified) {
        widget.onVerified();
      } else {
        setState(() {
          _message = "Email not verified yet. Please check your inbox.";
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.mark_email_unread,
                  size: 80, color: AppTheme.primaryGreen),
              const SizedBox(height: 24),
              Text(
                'Verify your email',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'We have sent a verification link to your email address. Please click it to continue.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (_message != null)
                Text(
                  _message!,
                  style: const TextStyle(color: Colors.green),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 32),
              PrimaryButton(
                label: _isChecking ? 'Checking...' : 'I have verified',
                icon: Icons.check_circle_outline,
                onPressed: _isChecking ? null : _checkVerification,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () async {
                  setState(() => _isSending = true);
                  await _sendVerificationEmail();
                  setState(() => _isSending = false);
                },
                child: Text(_isSending ? 'Sending...' : 'Resend Email'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => FirebaseAuth.instance.signOut(),
                child: const Text('Sign Out / Use different email',
                    style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
