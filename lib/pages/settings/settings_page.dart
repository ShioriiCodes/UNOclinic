import 'package:flutter/material.dart';

import '../../mock/mock_data.dart';
import '../../utils/formatters.dart';
import '../../utils/breakpoints.dart';
import '../../widgets/section_card.dart';
import '../../widgets/app_table.dart';
import '../../repositories/profile_repository.dart';

/// Settings page: Users table + Create User modal, Clinic info, Audit log (UI only).
class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.isAdmin,
  });

  final bool isAdmin;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final ProfileRepository _profileRepo = ProfileRepository();
  bool _loadingUsers = false;
  List<Map<String, dynamic>> _users = const [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _loadingUsers = true);
    try {
      final users = await _profileRepo.getUsers();
      if (!mounted) return;
      setState(() => _users = users);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load users.')),
      );
    } finally {
      if (mounted) setState(() => _loadingUsers = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!widget.isAdmin) {
      return SingleChildScrollView(
        padding: Breakpoints.pagePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Settings',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            const SectionCard(
              title: 'Access denied',
              padding: EdgeInsets.all(24),
              child: Text('Access denied. Admin only.'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: Breakpoints.pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Settings',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          // Users
          SectionCard(
            title: 'Users',
            actions: [
              FilledButton.icon(
                onPressed: () => _showCreateUserModal(context),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Create User'),
              ),
            ],
            padding: const EdgeInsets.all(24),
            child: _loadingUsers
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _users.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(8),
                        child: Text('No users found.'),
                      )
                    : AppTable<Map<String, dynamic>>(
                        columns: const [
                          AppTableColumn('name', 'Name', width: 180),
                          AppTableColumn('email', 'Email', width: 220),
                          AppTableColumn('role', 'Role', width: 100),
                        ],
                        rows: _users,
                        cellBuilder: (row, key) {
                          switch (key) {
                            case 'name':
                              return Text((row['full_name'] ?? '—').toString());
                            case 'email':
                              return Text((row['email'] ?? '—').toString());
                            case 'role':
                              return Text((row['role'] ?? '—').toString());
                            default:
                              return const SizedBox.shrink();
                          }
                        },
                      ),
          ),
          const SizedBox(height: 24),
          // Clinic info
          SectionCard(
            title: 'Clinic information',
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  decoration: const InputDecoration(labelText: 'Clinic name'),
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(labelText: 'Address'),
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(labelText: 'Contact number'),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () {}, // UI only — Save
                  child: const Text('Save clinic info'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Audit log
          SectionCard(
            title: 'Audit log',
            padding: const EdgeInsets.all(24),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: mockAuditLog.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final e = mockAuditLog[i];
                return ListTile(
                  title: Text(e.action),
                  subtitle: Text('${e.user} — ${Formatters.dateTime(e.time)}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateUserModal(BuildContext context) {
    final fullName = TextEditingController();
    final email = TextEditingController();
    final password = TextEditingController();
    String role = 'STAFF';
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create User'),
        content: StatefulBuilder(
          builder: (context, setLocal) {
            return SingleChildScrollView(
              child: SizedBox(
                width: 520,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: fullName,
                      decoration: const InputDecoration(labelText: 'Full name'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: email,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'user@example.com',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: role,
                      items: const [
                        DropdownMenuItem(value: 'ADMIN', child: Text('ADMIN')),
                        DropdownMenuItem(value: 'STAFF', child: Text('STAFF')),
                      ],
                      onChanged: saving ? null : (v) => setLocal(() => role = v ?? 'STAFF'),
                      decoration: const InputDecoration(labelText: 'Role'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: password,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        hintText: 'Minimum 6 characters',
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          StatefulBuilder(
            builder: (context, setLocal) {
              return FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        final em = email.text.trim();
                        final fn = fullName.text.trim();
                        final pw = password.text;

                        if (fn.isEmpty) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(content: Text('Full name is required.')),
                          );
                          return;
                        }
                        if (em.isEmpty) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(content: Text('Email is required.')),
                          );
                          return;
                        }
                        if (pw.length < 6) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(content: Text('Password must be at least 6 characters.')),
                          );
                          return;
                        }

                        setLocal(() => saving = true);
                        try {
                          await _profileRepo.registerUserAsAdmin(
                            email: em,
                            password: pw,
                            role: role,
                            fullName: fn,
                          );

                          if (!mounted || !ctx.mounted) return;
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(content: Text('User account created.')),
                          );
                          await _loadUsers();
                        } catch (_) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(content: Text('Failed to create user account.')),
                          );
                        } finally {
                          setLocal(() => saving = false);
                        }
                      },
                child: const Text('Create'),
              );
            },
          ),
        ],
      ),
    ).then((_) {
      fullName.dispose();
      email.dispose();
      password.dispose();
    });
  }
}
