// lib/screens/education/education_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

// Provider: GET /education/:id
final educationDetailProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
      final res = await ApiService.get('/education/$id');
      return res['data'] as Map<String, dynamic>;
    });

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

class EducationDetailScreen extends ConsumerWidget {
  final String contentId;
  const EducationDetailScreen({super.key, required this.contentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(educationDetailProvider(contentId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: detailAsync.when(
        loading: () => const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: AppColors.primaryBlue),
          ),
        ),
        error: (e, _) => Scaffold(
          appBar: AppBar(title: const Text('Error')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppColors.critical,
                ),
                const SizedBox(height: 12),
                Text('Could not load article', style: AppTextStyles.h3),
                const SizedBox(height: 6),
                Text(
                  e.toString(),
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        data: (content) {
          // content comes from MongoDB education_contents document
          final title = content['title'] as String? ?? '';
          final body = content['content_body'] as String? ?? '';
          final category = content['category'] as String? ?? '';
          final color = _colorForCategory(category);
          final icon = _iconForCategory(category);

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 160,
                pinned: true,
                backgroundColor: color,
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.white,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    color: color,
                    child: Center(
                      child: Icon(icon, size: 64, color: Colors.white30),
                    ),
                  ),
                  title: Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Category badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Content body — rendered as plain text from MongoDB
                    // The content_body field in education_contents stores
                    // the full article text.
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        body,
                        style: AppTextStyles.body.copyWith(
                          height: 1.7,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Risk level target badge (if set)
                    if (content['risk_level_target'] != null)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.skyBlue,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primaryBlue.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              size: 16,
                              color: AppColors.primaryBlue,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Recommended for: ${content['risk_level_target']} risk areas',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 30),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
