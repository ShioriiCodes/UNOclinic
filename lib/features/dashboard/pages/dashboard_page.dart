import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../utils/breakpoints.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/kpi_card.dart';
import '../../../widgets/section_card.dart';
import '../models/activity_model.dart';
import '../repositories/dashboard_repository.dart';

/// Dashboard: KPI cards, recent activity, alerts, quick actions.
/// Responsive: small / medium / large desktop.
class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
    this.onNavigate,
  });

  final ValueChanged<int>? onNavigate;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int todayVisits = 0;
  int pendingCertificates = 0;
  int pendingReferrals = 0;
  int lowStockItems = 0;
  int nearExpiryItems = 0;
  List<ActivityModel> activities = const [];
  List<Map<String, dynamic>> alerts = const [];
  bool isLoading = true;

  final DashboardRepository _repo = DashboardRepository();

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    setState(() => isLoading = true);
    try {
      final results = await Future.wait<dynamic>([
        _repo.getTodayVisits(),
        _repo.getPendingCertificates(),
        _repo.getPendingReferrals(),
        _repo.getLowStockItems(),
        _repo.getNearExpiryItems(),
        _repo.getRecentActivities(),
        _repo.getAlerts(),
      ]);

      if (!mounted) return;
      setState(() {
        todayVisits = results[0] as int;
        pendingCertificates = results[1] as int;
        pendingReferrals = results[2] as int;
        lowStockItems = results[3] as int;
        nearExpiryItems = results[4] as int;
        activities = List<ActivityModel>.from(results[5] as List<dynamic>);
        alerts = List<Map<String, dynamic>>.from(results[6] as List<dynamic>);
      });
    } catch (e) {
      debugPrint('Dashboard load error: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = Breakpoints.pagePadding(context);
    final sectionGap = Breakpoints.sectionGap(context);
    final isSmall = Breakpoints.isSmall(context);

    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 8,
            children: [
              Text(
                'Dashboard',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextButton.icon(
                onPressed: () async {
                  await Supabase.instance.client.auth.signOut();
                },
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Logout'),
              ),
            ],
          ),
          SizedBox(height: sectionGap),
          // KPI row — bounded height so Expanded children get laid out (avoids hit-test exception)
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              if (width < Breakpoints.medium) {
                return _kpiGrid(
                  crossAxisCount: 2,
                  gap: sectionGap,
                );
              }
              return ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 100, maxHeight: 140),
                child: _kpiRow(sectionGap: sectionGap),
              );
            },
          ),
          SizedBox(height: sectionGap * 1.25),
          // Quick actions — responsive spacing
          Wrap(
            spacing: isSmall ? 12 : 16,
            runSpacing: isSmall ? 12 : 16,
            children: [
              FilledButton.icon(
                onPressed: () => widget.onNavigate?.call(1),
                icon: const Icon(Icons.person_add_rounded, size: 18),
                label: const Text('New Patient'),
              ),
              OutlinedButton.icon(
                onPressed: () => widget.onNavigate?.call(2),
                icon: const Icon(Icons.medical_services_rounded, size: 18),
                label: const Text('New Visit'),
              ),
              OutlinedButton.icon(
                onPressed: () => widget.onNavigate?.call(3),
                icon: const Icon(Icons.badge_rounded, size: 18),
                label: const Text('Issue Certificate'),
              ),
              OutlinedButton.icon(
                onPressed: () => widget.onNavigate?.call(4),
                icon: const Icon(Icons.forward_rounded, size: 18),
                label: const Text('Create Referral'),
              ),
              OutlinedButton.icon(
                onPressed: () => widget.onNavigate?.call(5),
                icon: const Icon(Icons.inventory_rounded, size: 18),
                label: const Text('Receive Stock'),
              ),
            ],
          ),
          SizedBox(height: sectionGap * 1.25),
          // Two-column: Recent Activity | Alerts — bounded height to avoid hit-test issues
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 520),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SectionCard(
                    title: 'Recent Activity',
                    child: isLoading
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const ClampingScrollPhysics(),
                            itemCount: activities.length,
                            itemBuilder: (context, i) {
                              final activity = activities[i];
                              return ListTile(
                                leading: Icon(
                                  _activityIcon(activity.title),
                                  size: 20,
                                  color: theme.colorScheme.primary,
                                ),
                                title: Text(
                                  activity.title,
                                  style: theme.textTheme.bodyMedium,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  activity.subtitle,
                                  style: theme.textTheme.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Text(
                                  Formatters.time(activity.date),
                                  style: theme.textTheme.bodySmall,
                                ),
                              );
                            },
                          ),
                  ),
                ),
                SizedBox(width: sectionGap),
                Expanded(
                  child: SectionCard(
                    title: 'Alerts',
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      itemCount: alerts.length,
                      itemBuilder: (context, i) {
                        final alert = alerts[i];
                        return ListTile(
                          title: Text(
                            (alert['message'] ?? '').toString(),
                            style: theme.textTheme.bodyMedium,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Single row of 5 KPI cards (medium/large).
  Widget _kpiRow({required double sectionGap}) {
    const pad = 8.0;
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: pad),
            child: _buildKpiCard("Today's Visits", isLoading ? '...' : todayVisits.toString(), Icons.medical_services_rounded),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: pad),
            child: _buildKpiCard('Pending Certificates', isLoading ? '...' : pendingCertificates.toString(), Icons.badge_rounded),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: pad),
            child: _buildKpiCard('Pending Referrals', isLoading ? '...' : pendingReferrals.toString(), Icons.forward_rounded),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: pad),
            child: _buildKpiCard('Low Stock Items', isLoading ? '...' : lowStockItems.toString(), Icons.inventory_2_rounded),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: pad),
            child: _buildKpiCard('Near Expiry (30 days)', isLoading ? '...' : nearExpiryItems.toString(), Icons.warning_amber_rounded),
          ),
        ),
      ],
    );
  }

  /// Grid of KPI cards for small screens.
  Widget _kpiGrid({required int crossAxisCount, required double gap}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - gap * (crossAxisCount - 1)) / crossAxisCount;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            SizedBox(width: itemWidth, child: _buildKpiCard("Today's Visits", isLoading ? '...' : todayVisits.toString(), Icons.medical_services_rounded)),
            SizedBox(width: itemWidth, child: _buildKpiCard('Pending Certificates', isLoading ? '...' : pendingCertificates.toString(), Icons.badge_rounded)),
            SizedBox(width: itemWidth, child: _buildKpiCard('Pending Referrals', isLoading ? '...' : pendingReferrals.toString(), Icons.forward_rounded)),
            SizedBox(width: itemWidth, child: _buildKpiCard('Low Stock Items', isLoading ? '...' : lowStockItems.toString(), Icons.inventory_2_rounded)),
            SizedBox(width: itemWidth, child: _buildKpiCard('Near Expiry (30 days)', isLoading ? '...' : nearExpiryItems.toString(), Icons.warning_amber_rounded)),
          ],
        );
      },
    );
  }

  static Widget _buildKpiCard(String title, String value, IconData icon) {
    return KpiCard(
      title: title,
      value: value,
      icon: icon,
    );
  }

  IconData _activityIcon(String type) {
    final normalized = type.toLowerCase();
    if (normalized.contains('visit')) {
      return Icons.medical_services_rounded;
    }
    if (normalized.contains('certificate')) {
      return Icons.badge_rounded;
    }
    if (normalized.contains('referral')) {
      return Icons.forward_rounded;
    }
    switch (normalized) {
      case 'visit':
        return Icons.medical_services_rounded;
      case 'certificate':
        return Icons.badge_rounded;
      case 'referral':
        return Icons.forward_rounded;
      case 'inventory':
        return Icons.inventory_2_rounded;
      default:
        return Icons.circle_rounded;
    }
  }
}

