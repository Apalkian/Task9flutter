import 'package:flutter/material.dart';

import 'auth_service.dart';
import 'config.dart';
import 'home_page_appbar_snippet.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService auth = AuthService();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    emailCtrl.dispose();
    passwordCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _loginWithEmail() async {
    if (emailCtrl.text.trim().isEmpty || passwordCtrl.text.isEmpty) {
      _snack('Please enter your email and password.');
      return;
    }
    setState(() => loading = true);
    final user =
        await auth.signInWithEmail(emailCtrl.text.trim(), passwordCtrl.text);
    if (!mounted) return;
    setState(() => loading = false);

    if (user != null) {
      if (!user.emailVerified) {
        // Sign out again so the app does not open the Home page.
        await auth.signOut();
        _snack('Please verify your email before logging in.');
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomePage()),
        );
      }
    } else {
      _snack('Invalid email or password');
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => loading = true);
    final user = await auth.signInWithGoogle();
    if (!mounted) return;
    setState(() => loading = false);
    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomePage()),
      );
    }
  }

  // FORGOT PASSWORD dialog
  Future<void> _forgotPassword() async {
    final resetCtrl = TextEditingController(text: emailCtrl.text.trim());

    final email = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your email and we will send you a reset link.'),
            const SizedBox(height: 12),
            TextField(
              controller: resetCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, resetCtrl.text.trim()),
            child: const Text('Send link'),
          ),
        ],
      ),
    );  // end of showDialog

    if (email == null) return; // cancelled
    if (email.isEmpty) {
      _snack('Please enter your email.');
      return;
    }

    final error = await auth.sendPasswordReset(email);
    if (!mounted) return;
    _snack(error ??
        'Password reset email sent. Please check your inbox (and spam).');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login  |  $kLastName')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: loading ? null : _forgotPassword,
                  child: const Text('Forgot password?'),
                ),
              ),
              ElevatedButton(
                onPressed: loading ? null : _loginWithEmail,
                child: loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Login with Email'),
              ),
              const SizedBox(height: 24),
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('OR'),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.login),
                label: const Text('Sign in with Google'),
                onPressed: loading ? null : _loginWithGoogle,
              ),
              const SizedBox(height: 12),
              TextButton(
                child: const Text("Don't have an account? Register"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
