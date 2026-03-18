import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// WARNING: This registration allows creating ADMIN accounts.
/// Disable or restrict in production.
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _fullName = TextEditingController();
  String _role = 'STAFF';
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _fullName.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_loading) return;
    setState(() => _loading = true);

    try {
      final email = _email.text.trim();
      final password = _password.text;
      final fullName = _fullName.text.trim();
      final role = _role.trim().toUpperCase();

      if (email.isEmpty || password.isEmpty || fullName.isEmpty) {
        throw const AuthException('Please fill in all fields.');
      }
      if (role != 'ADMIN' && role != 'STAFF') {
        throw const AuthException('Role must be ADMIN or STAFF.');
      }

      final res = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );

      final user = res.user;
      if (user == null) {
        throw const AuthException('Registration failed. Please try again.');
      }

      await Supabase.instance.client.from('profiles').insert({
        'id': user.id,
        'email': email,
        'role': role,
        'full_name': fullName,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created')),
      );
      Navigator.of(context).pop(); // back to LoginPage
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration failed. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Create Account',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _email,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'Enter email',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _password,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter password',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _fullName,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        hintText: 'Enter full name',
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _role,
                      items: const [
                        DropdownMenuItem(value: 'ADMIN', child: Text('ADMIN')),
                        DropdownMenuItem(value: 'STAFF', child: Text('STAFF')),
                      ],
                      onChanged: _loading ? null : (v) => setState(() => _role = v ?? 'STAFF'),
                      decoration: const InputDecoration(labelText: 'Role'),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _loading ? null : _register,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text('Register'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _loading ? null : () => Navigator.of(context).pop(),
                      child: const Text('Back to Login'),
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

