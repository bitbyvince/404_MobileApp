// lib/screens/education/education_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

// Provider: GET /education → { contents: [...] }
final educationContentsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final res = await ApiService.get('/education');
  final list = res['data'] as List<dynamic>;
  return list.map((e) => e as Map<String, dynamic>).toList();
});

// Map backend category strings to icons and colors
IconData _iconForCategory(String cat) {
  switch (cat) {
    case 'Protection Protocol':
      return Icons.shield_outlined;
    case 'TB Awareness':
      return Icons.visibility_outlined;
    case 'Treatment Guide':
      return Icons.medical_services_outlined;
    case 'Emergency Response':
      return Icons.emergency_outlined;
    default:
      return Icons.article_outlined;
  }
}

Color _colorForCategory(String cat) {
  switch (cat) {
    case 'Protection Protocol':
      return AppColors.primaryBlue;
    case 'TB Awareness':
      return AppColors.riskModerate;
    case 'Treatment Guide':
      return AppColors.success;
    case 'Emergency Response':
      return AppColors.critical;
    default:
      return AppColors.primaryBlue;
  }
}

class EducationScreen extends ConsumerWidget {
  const EducationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentsAsync = ref.watch(educationContentsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Health Education'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(24),
          child: Padding(
            padding: EdgeInsets.only(left: 16, bottom: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Protection & TB Guidance',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primaryBlue,
        onRefresh: () async => ref.invalidate(educationContentsProvider),
        child: contentsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primaryBlue),
          ),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.wifi_off_rounded,
                  size: 48,
                  color: AppColors.textLight,
                ),
                const SizedBox(height: 12),
                Text('Could not load content', style: AppTextStyles.h3),
                const SizedBox(height: 6),
                Text('Pull down to retry', style: AppTextStyles.caption),
              ],
            ),
          ),
          data: (contents) {
            // Group by category
            final Map<String, List<Map<String, dynamic>>> grouped = {};
            for (final c in contents) {
              final cat = c['category'] as String? ?? 'Other';
              grouped.putIfAbsent(cat, () => []).add(c);
            }

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ── Active alert reminder ────────────────────
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.riskHigh.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.riskHigh.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.riskHigh,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'You may be near a high-risk TB zone. Review protocols below.',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.riskHigh,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Text('Browse by Category', style: AppTextStyles.h3),
                const SizedBox(height: 12),

                // ── Category cards ──────────────────────────
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.35,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: grouped.keys.length,
                  itemBuilder: (context, i) {
                    final cat = grouped.keys.elementAt(i);
                    final items = grouped[cat]!;
                    final color = _colorForCategory(cat);
                    final icon = _iconForCategory(cat);

                    return GestureDetector(
                      onTap: () =>
                          context.go('/education/detail/${items.first['_id']}'),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(icon, color: color, size: 22),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${items.length}',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: color,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              cat,
                              style: AppTextStyles.bodyBold.copyWith(
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${items.length} article${items.length != 1 ? 's' : ''}',
                              style: AppTextStyles.caption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // ── All articles list ───────────────────────
                Text('All Articles', style: AppTextStyles.h3),
                const SizedBox(height: 12),
                ...contents.map((c) {
                  final cat = c['category'] as String? ?? '';
                  final color = _colorForCategory(cat);
                  return GestureDetector(
                    onTap: () => context.go('/education/detail/${c['_id']}'),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _iconForCategory(cat),
                              color: color,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c['title'] as String? ?? '',
                                  style: AppTextStyles.bodyBold.copyWith(
                                    fontSize: 13,
                                  ),
                                ),
                                Text(cat, style: AppTextStyles.caption),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.textLight,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}
