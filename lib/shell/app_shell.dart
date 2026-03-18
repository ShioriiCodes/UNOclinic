import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';

import 'sidebar.dart';
import 'topbar.dart';
import '../utils/breakpoints.dart';
import '../features/dashboard/pages/dashboard_page.dart';
import '../features/health_certificates/pages/health_certificates_page.dart';
import '../features/patients/pages/patients_page.dart';
import '../features/referrals/pages/referrals_page.dart';
import '../features/visits/pages/visits_page.dart';
import '../pages/inventory/inventory_page.dart';
import '../pages/reports/reports_page.dart';
import '../pages/settings/settings_page.dart';
import '../models/user_profile.dart';

/// App shell: left sidebar + top bar + main content + optional right details drawer.
/// Navigation via indexed stack (no go_router).
class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.profile,
  });

  final UserProfile profile;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  bool _sidebarCollapsed = false;
  SyncStatus _syncStatus = SyncStatus.syncing;
  Timer? _connectivityTimer;
  String _userRole = 'STAFF';

  Widget? _detailsDrawer;

  @override
  void initState() {
    super.initState();
    _userRole = (widget.profile.role.isNotEmpty ? widget.profile.role : 'STAFF').toUpperCase();
    _startConnectivityMonitor();
  }

  @override
  void dispose() {
    _connectivityTimer?.cancel();
    super.dispose();
  }

  void _setDetailsDrawer(Widget? drawer) {
    setState(() => _detailsDrawer = drawer);
  }

  void _startConnectivityMonitor() {
    // Run once immediately, then every 5 seconds.
    _checkConnectivity();
    _connectivityTimer = Timer.periodic(const Duration(seconds: 5), (_) => _checkConnectivity());
  }

  Future<void> _checkConnectivity() async {
    if (!mounted) return;
    setState(() => _syncStatus = SyncStatus.syncing);

    final isOnline = await _hasInternetAccess();
    if (!mounted) return;

    setState(() => _syncStatus = isOnline ? SyncStatus.online : SyncStatus.offline);
  }

  Future<bool> _hasInternetAccess() async {
    try {
      final result = await InternetAddress.lookup('example.com')
          .timeout(const Duration(seconds: 2));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Builds only the active page so layout and semantics run for one page at a time.
  /// Avoids "child needs layout" / "never been laid out" from off-screen IndexedStack children.
  Widget _buildActivePage() {
    switch (_selectedIndex) {
      case 0:
        return DashboardPage(onNavigate: _onSelectNav);
      case 1:
        return PatientsPage(onOpenDrawer: _setDetailsDrawer);
      case 2:
        return VisitsPage(onOpenDrawer: _setDetailsDrawer);
      case 3:
        return HealthCertificatesPage(onOpenDrawer: _setDetailsDrawer);
      case 4:
        return ReferralsPage(onOpenDrawer: _setDetailsDrawer);
      case 5:
        return InventoryPage(onOpenDrawer: _setDetailsDrawer);
      case 6:
        return const ReportsPage();
      case 7:
        return SettingsPage(isAdmin: _userRole == 'ADMIN');
      default:
        return DashboardPage(onNavigate: _onSelectNav);
    }
  }

  void _onSelectNav(int i) {
    // Settings is ADMIN-only.
    if (i == 7 && _userRole != 'ADMIN') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings is ADMIN only.')),
      );
      return;
    }
    setState(() => _selectedIndex = i);
  }

  @override
  Widget build(BuildContext context) {
    final isTabletOrSmaller = Breakpoints.isTabletOrSmaller(context);
    final effectiveCollapsed = isTabletOrSmaller ? true : _sidebarCollapsed;
    final userLabel = (widget.profile.fullName ?? '').trim().isNotEmpty
        ? widget.profile.fullName!.trim()
        : widget.profile.email;

    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Sidebar(
            selectedIndex: _selectedIndex,
            onSelect: _onSelectNav,
            collapsed: effectiveCollapsed,
            onToggleCollapse: () {
              if (isTabletOrSmaller) return;
              setState(() => _sidebarCollapsed = !_sidebarCollapsed);
            },
          ),
          Expanded(
            child: ClipRect(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Topbar(
                    syncStatus: _syncStatus,
                    onSyncStatusTap: _checkConnectivity,
                    userLabel: userLabel,
                  ),
                  Expanded(
                    child: SizedBox.expand(child: _buildActivePage()),
                  ),
                ],
              ),
            ),
          ),
          _detailsDrawer ?? const SizedBox.shrink(),
        ],
      ),
    );
  }
}
