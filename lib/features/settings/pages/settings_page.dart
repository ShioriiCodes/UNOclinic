// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';

import '../../../utils/breakpoints.dart';
import '../../../widgets/app_table.dart';
import '../../../widgets/section_card.dart';
import '../repositories/settings_repository.dart';
import '../repositories/user_repository.dart';

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
  List<Map<String, dynamic>> users = [];
  bool isLoading = true;
  List<Map<String, dynamic>> logs = [];
  bool isLoadingLogs = true;

  final UserRepository _userRepo = UserRepository();
  final SettingsRepository _repo = SettingsRepository();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController contactController = TextEditingController();

  Future<void> loadUsers() async {
    setState(() => isLoading = true);

    try {
      final loaded = await _userRepo.getUsers();
      if (!mounted) return;
      setState(() => users = loaded);
    } catch (e) {
      print('ERROR: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load users.')),
      );
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    loadUsers();
    loadSettings();
  }

  @override
  void dispose() {
    nameController.dispose();
    addressController.dispose();
    contactController.dispose();
    super.dispose();
  }

  Future<void> loadSettings() async {
    setState(() => isLoadingLogs = true);

    try {
      final loadedLogs = await _repo.getAuditLogs();
      final clinic = await _repo.getClinicInfo();
      if (!mounted) return;
      setState(() {
        logs = loadedLogs;
        nameController.text = (clinic?['name'] ?? '').toString();
        addressController.text = (clinic?['address'] ?? '').toString();
        contactController.text = (clinic?['contact_number'] ?? '').toString();
      });
    } catch (e) {
      print('SETTINGS ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load settings: $e')),
        );
      }
    }

    if (mounted) {
      setState(() => isLoadingLogs = false);
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
            child: isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : users.isEmpty
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
                        rows: users,
                        cellBuilder: (user, key) {
                          switch (key) {
                            case 'name':
                              return Text((user['full_name'] ?? '-').toString());
                            case 'email':
                              return Text((user['email'] ?? '-').toString());
                            case 'role':
                              return Text((user['role'] ?? '-').toString());
                            default:
                              return const SizedBox.shrink();
                          }
                        },
                        onRowTap: (user) => _showManageUserModal(context, user),
                      ),
          ),
          const SizedBox(height: 24),
          SectionCard(
            title: 'Clinic information',
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Clinic name'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contactController,
                  decoration: const InputDecoration(labelText: 'Contact number'),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () async {
                    try {
                      await _repo.updateClinicInfo({
                        'name': nameController.text,
                        'address': addressController.text,
                        'contact_number': contactController.text,
                        'updated_at': DateTime.now().toIso8601String(),
                      });
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Clinic info saved.')),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to save clinic info: $e')),
                      );
                    }
                  },
                  child: const Text('Save clinic info'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SectionCard(
            title: 'Audit log',
            padding: const EdgeInsets.all(24),
            child: isLoadingLogs
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : logs.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(8),
                        child: Text('No audit logs found.'),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: logs.length,
                        itemBuilder: (context, index) {
                          final log = logs[index];
                          final profiles = log['profiles'];
                          String fullName = 'User';
                          if (profiles is Map) {
                            fullName = (profiles['full_name'] ?? 'User').toString();
                          }
                          final createdAt = log['created_at']?.toString() ?? '';
                          return ListTile(
                            title: Text((log['action'] ?? '').toString()),
                            subtitle: Text('$fullName - $createdAt'),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showCreateUserModal(BuildContext context) {
    final name = TextEditingController();
    final email = TextEditingController();
    final password = TextEditingController();
    String role = 'STAFF';
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Create User'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 520,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: name,
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
                  TextField(
                    controller: password,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      hintText: 'Minimum 6 characters',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: role,
                    items: const [
                      DropdownMenuItem(value: 'ADMIN', child: Text('ADMIN')),
                      DropdownMenuItem(value: 'STAFF', child: Text('STAFF')),
                    ],
                    onChanged: (v) => setLocal(() => role = v ?? 'STAFF'),
                    decoration: const InputDecoration(labelText: 'Role'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      final fullName = name.text.trim();
                      final em = email.text.trim();
                      final pw = password.text;
                      if (fullName.isEmpty || em.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Name and email are required.')),
                        );
                        return;
                      }
                      if (pw.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Password must be at least 6 characters.'),
                          ),
                        );
                        return;
                      }

                      setLocal(() => saving = true);
                      try {
                        await _userRepo.createUserWithPassword(
                          email: em,
                          password: pw,
                          fullName: fullName,
                          role: role,
                        );
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        await loadUsers();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('User account created.')),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to create user: $e')),
                        );
                      } finally {
                        if (ctx.mounted) {
                          setLocal(() => saving = false);
                        }
                      }
                    },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    ).then((_) {
      name.dispose();
      email.dispose();
      password.dispose();
    });
  }

  void _showManageUserModal(BuildContext context, Map<String, dynamic> user) {
    final id = (user['id'] ?? '').toString();
    if (id.isEmpty) return;
    String role = (user['role'] ?? 'STAFF').toString().toUpperCase();
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Manage User'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text((user['full_name'] ?? '-').toString()),
                const SizedBox(height: 4),
                Text(
                  (user['email'] ?? '-').toString(),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: role,
                  items: const [
                    DropdownMenuItem(value: 'ADMIN', child: Text('ADMIN')),
                    DropdownMenuItem(value: 'STAFF', child: Text('STAFF')),
                  ],
                  onChanged: saving ? null : (v) => setLocal(() => role = v ?? 'STAFF'),
                  decoration: const InputDecoration(labelText: 'Role'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: saving
                  ? null
                  : () async {
                      setLocal(() => saving = true);
                      try {
                        await _userRepo.deleteUser(id);
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        await loadUsers();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('User deleted.')),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to delete user: $e')),
                        );
                      } finally {
                        if (ctx.mounted) {
                          setLocal(() => saving = false);
                        }
                      }
                    },
              child: const Text('Delete'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      setLocal(() => saving = true);
                      try {
                        await _userRepo.updateRole(id, role);
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        await loadUsers();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Role updated.')),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to update role: $e')),
                        );
                      } finally {
                        if (ctx.mounted) {
                          setLocal(() => saving = false);
                        }
                      }
                    },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
