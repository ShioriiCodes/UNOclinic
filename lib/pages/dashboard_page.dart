import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../mock/mock_data.dart';
import '../../widgets/kpi_card.dart';
import '../../widgets/section_card.dart';
import '../../utils/formatters.dart';
import '../../utils/breakpoints.dart';

/// Dashboard: KPI cards, recent activity, alerts, quick actions (UI only).
/// Responsive: small / medium / large desktop.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

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
                onPressed: () {},
                icon: const Icon(Icons.person_add_rounded, size: 18),
                label: const Text('New Patient'),
              ),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.medical_services_rounded, size: 18),
                label: const Text('New Visit'),
              ),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.badge_rounded, size: 18),
                label: const Text('Issue Certificate'),
              ),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.forward_rounded, size: 18),
                label: const Text('Create Referral'),
              ),
              OutlinedButton.icon(
                onPressed: () {},
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
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      itemCount: mockDashboardActivity.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final a = mockDashboardActivity[i];
                        return ListTile(
                          leading: Icon(
                            _activityIcon(a.type),
                            size: 20,
                            color: theme.colorScheme.primary,
                          ),
                          title: Text(
                            a.description,
                            style: theme.textTheme.bodyMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            Formatters.dateTime(a.time),
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
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      itemCount: mockDashboardAlerts.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final a = mockDashboardAlerts[i];
                        return ListTile(
                          leading: Icon(
                            Icons.warning_amber_rounded,
                            size: 20,
                            color: a.severity == 'high'
                                ? Colors.orange
                                : theme.colorScheme.primary,
                          ),
                          title: Text(
                            a.title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            a.message,
                            style: theme.textTheme.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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
  static Widget _kpiRow({required double sectionGap}) {
    const pad = 8.0;
    return Row(
      children: [
        Expanded(child: Padding(padding: const EdgeInsets.only(right: pad), child: _buildKpiCard("Today's Visits", todayVisitsCount, Icons.medical_services_rounded))),
        Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: pad), child: _buildKpiCard('Pending Certificates', pendingCertificatesCount, Icons.badge_rounded))),
        Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: pad), child: _buildKpiCard('Pending Referrals', pendingReferralsCount, Icons.forward_rounded))),
        Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: pad), child: _buildKpiCard('Low Stock Items', lowStockCount, Icons.inventory_2_rounded))),
        Expanded(child: Padding(padding: const EdgeInsets.only(left: pad), child: _buildKpiCard('Near Expiry (30 days)', nearExpiryCount, Icons.warning_amber_rounded))),
      ],
    );
  }

  /// Grid of KPI cards for small screens.
  static Widget _kpiGrid({required int crossAxisCount, required double gap}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - gap * (crossAxisCount - 1)) / crossAxisCount;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            SizedBox(width: itemWidth, child: _buildKpiCard("Today's Visits", todayVisitsCount, Icons.medical_services_rounded)),
            SizedBox(width: itemWidth, child: _buildKpiCard('Pending Certificates', pendingCertificatesCount, Icons.badge_rounded)),
            SizedBox(width: itemWidth, child: _buildKpiCard('Pending Referrals', pendingReferralsCount, Icons.forward_rounded)),
            SizedBox(width: itemWidth, child: _buildKpiCard('Low Stock Items', lowStockCount, Icons.inventory_2_rounded)),
            SizedBox(width: itemWidth, child: _buildKpiCard('Near Expiry (30 days)', nearExpiryCount, Icons.warning_amber_rounded)),
          ],
        );
      },
    );
  }

  static Widget _buildKpiCard(String title, int value, IconData icon) {
    return KpiCard(
      title: title,
      value: '$value',
      icon: icon,
    );
  }

  IconData _activityIcon(String type) {
    switch (type) {
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
