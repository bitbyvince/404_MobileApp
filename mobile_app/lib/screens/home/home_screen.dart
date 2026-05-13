// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_logo.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';

// ── Providers for backend data ────────────────────────────────

// GET /compliance/summary → { total, compliant, at_risk, defaulters }
// Replace with this
final complianceSummaryProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final res = await ApiService.get('/compliance/summary');
  return res['summary'] as Map<String, dynamic>;
});

final riskZoneCountProvider = FutureProvider<Map<String, int>>((ref) async {
  final res = await ApiService.get('/heatmap');
  final zones = res['data'] as List;
  final counts = <String, int>{
    'Critical': 0,
    'High': 0,
    'Moderate': 0,
    'Low': 0,
  };
  for (final z in zones) {
    final level = z['risk_level'] as String;
    counts[level] = (counts[level] ?? 0) + 1;
  }
  return counts;
});

// ─────────────────────────────────────────────────────────────

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(complianceSummaryProvider);
    final riskAsync = ref.watch(riskZoneCountProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primaryBlue,
        onRefresh: () async {
          ref.invalidate(complianceSummaryProvider);
          ref.invalidate(riskZoneCountProvider);
        },
        child: CustomScrollView(
          slivers: [
            // ── App Bar ─────────────────────────────────────
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.primaryBlue,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primaryBlue, AppColors.lightBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Row(
                        children: [
                          const AppLogo(size: 40),
                          const SizedBox(width: 10),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'RespiraTrack',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'TB-DOTS Surveillance',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          // Notification bell
                          IconButton(
                            icon: const Icon(
                              Icons.notifications_outlined,
                              color: AppColors.white,
                            ),
                            onPressed: () => context.go('/notifications'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Risk zone alert banner ─────────────────
                  riskAsync.when(
                    data: (counts) {
                      final hasHighRisk =
                          (counts['Critical'] ?? 0) + (counts['High'] ?? 0) > 0;
                      if (!hasHighRisk) return const SizedBox.shrink();
                      return _AlertBanner(
                        count:
                            (counts['Critical'] ?? 0) + (counts['High'] ?? 0),
                        onTap: () => context.go('/map'),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 20),

                  // ── Quick Actions ──────────────────────────
                  Text('Quick Actions', style: AppTextStyles.h3),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.map_rounded,
                          label: 'View\nHeat Map',
                          color: AppColors.primaryBlue,
                          onTap: () => context.go('/map'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.shield_outlined,
                          label: 'Protection\nGuide',
                          color: AppColors.success,
                          onTap: () => context.go('/education'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.notifications_active_outlined,
                          label: 'My\nAlerts',
                          color: AppColors.warning,
                          onTap: () => context.go('/notifications'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── TB Risk in your area (from backend) ───
                  Text('TB Risk In Your Area', style: AppTextStyles.h3),
                  const SizedBox(height: 4),
                  Text(
                    'Based on latest barangay data',
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: 12),
                  riskAsync.when(
                    data: (counts) => _RiskSummaryCard(counts: counts),
                    loading: () => const _ShimmerCard(height: 140),
                    error: (e, _) => _ErrorCard(message: e.toString()),
                  ),
                  const SizedBox(height: 24),

                  // ── Overall compliance stats ───────────────
                  Text('Compliance Overview', style: AppTextStyles.h3),
                  const SizedBox(height: 12),
                  summaryAsync.when(
                    data: (s) => _ComplianceStatsRow(summary: s),
                    loading: () => const _ShimmerCard(height: 80),
                    error: (e, _) => _ErrorCard(message: e.toString()),
                  ),
                  const SizedBox(height: 24),

                  // ── Education CTA ──────────────────────────
                  _EducationCta(onTap: () => context.go('/education')),
                  const SizedBox(height: 20),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Alert Banner ──────────────────────────────────────────────
class _AlertBanner extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _AlertBanner({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.critical.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.critical.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.critical,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count high-risk zone${count > 1 ? 's' : ''} detected',
                    style: const TextStyle(
                      color: AppColors.critical,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const Text(
                    'TB hotspot activity nearby. Tap to view map.',
                    style: TextStyle(color: AppColors.critical, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.critical),
          ],
        ),
      ),
    );
  }
}

// ── Quick Action Card ─────────────────────────────────────────
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Risk Summary Card — populated from GET /heatmap/zones ─────
class _RiskSummaryCard extends StatelessWidget {
  final Map<String, int> counts;
  const _RiskSummaryCard({required this.counts});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Very High (31+)', AppColors.riskHigh, counts['Critical'] ?? 0),
      ('Moderate (11–30)', AppColors.riskModerate, counts['High'] ?? 0),
      ('Low (1–10)', AppColors.riskLow, counts['Moderate'] ?? 0),
      ('None', AppColors.riskNone, counts['Low'] ?? 0),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: item.$2,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.$1,
                        style: AppTextStyles.bodyBold.copyWith(fontSize: 13),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: item.$2.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${item.$3} zone${item.$3 != 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 11,
                          color: item.$2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ── Compliance Stats Row — from GET /compliance/summary ───────
class _ComplianceStatsRow extends StatelessWidget {
  final Map<String, dynamic> summary;
  const _ComplianceStatsRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatPill(
          '${summary['compliant'] ?? 0}',
          'Compliant',
          AppColors.success,
        ),
        const SizedBox(width: 10),
        _StatPill('${summary['at_risk'] ?? 0}', 'At Risk', AppColors.warning),
        const SizedBox(width: 10),
        _StatPill(
          '${summary['defaulters'] ?? 0}',
          'Defaulter',
          AppColors.critical,
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  final String value, label;
  final Color color;
  const _StatPill(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}

// ── Education CTA ─────────────────────────────────────────────
class _EducationCta extends StatelessWidget {
  final VoidCallback onTap;
  const _EducationCta({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primaryBlue, AppColors.lightBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Stay Protected',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Learn personal protection protocols and how to prevent TB.',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Read Now →',
                      style: TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.health_and_safety_outlined,
              size: 56,
              color: Colors.white38,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shimmer placeholder ───────────────────────────────────────
class _ShimmerCard extends StatelessWidget {
  final double height;
  const _ShimmerCard({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.border.withOpacity(0.4),
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}

// ── Error card ────────────────────────────────────────────────
class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.critical.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Failed to load data. Pull down to retry.',
        style: AppTextStyles.caption.copyWith(color: AppColors.critical),
      ),
    );
  }
}
