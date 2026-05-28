import 'package:flutter/material.dart';
import '../../../data/repositories/patient_repository.dart';
import '../../../data/repositories/sputum_repository.dart';
import '../../../data/models/patient_model.dart';
import '../../../data/models/sputum_test_model.dart';
import '../widgets/profile_info_tile.dart';
import '../../sputum/widgets/result_badge.dart';

class HealthRecordsScreen extends StatefulWidget {
  const HealthRecordsScreen({super.key});

  @override
  State<HealthRecordsScreen> createState() => _HealthRecordsScreenState();
}

class _HealthRecordsScreenState extends State<HealthRecordsScreen> {
  static const _navy = Color(0xFF1A3A5C);
  static const _blue = Color(0xFF1A73E8);

  bool _loading = true;
  PatientModel? _patient;
  List<SputumTestModel> _sputumTests = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        PatientRepository.instance.getMyProfile(),
        SputumRepository.instance.getMyTests(),
      ]);
      setState(() {
        _patient = results[0] as PatientModel;
        _sputumTests = (results[1] as List<SputumTestModel>)
          ..sort((a, b) => a.month.compareTo(b.month));
      });
    } catch (_) {
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Health Records',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── TB CASE INFO ───────────────────────────────
                    _SectionHeader(title: 'TB Case Information'),
                    const SizedBox(height: 8),
                    ProfileInfoTile(
                      label: 'TB Case Number',
                      value: _patient?.tbCaseNumber ?? 'N/A',
                      icon: Icons.badge_outlined,
                    ),
                    ProfileInfoTile(
                      label: 'Classification',
                      value: _patient?.classification ?? 'N/A',
                      icon: Icons.category_outlined,
                    ),
                    ProfileInfoTile(
                      label: 'Bacteriological Status',
                      value: _patient?.bacteriologicalStatus ?? 'N/A',
                      icon: Icons.biotech_outlined,
                    ),
                    ProfileInfoTile(
                      label: 'Date of Diagnosis',
                      value: _patient != null
                          ? _formatDate(_patient!.dateOfDiagnosis)
                          : 'N/A',
                      icon: Icons.event_outlined,
                    ),
                    ProfileInfoTile(
                      label: 'Treatment Start',
                      value: _patient != null
                          ? _formatDate(_patient!.dateStarted)
                          : 'N/A',
                      icon: Icons.play_circle_outline_rounded,
                    ),
                    ProfileInfoTile(
                      label: 'Expected End Date',
                      value: _patient != null
                          ? _formatDate(_patient!.endDate)
                          : 'N/A',
                      icon: Icons.stop_circle_outlined,
                    ),
                    ProfileInfoTile(
                      label: 'Treatment Outcome',
                      value:
                          _patient?.treatmentOutcome.status ?? 'On Treatment',
                      icon: Icons.flag_outlined,
                    ),
                    const SizedBox(height: 16),

                    // ── MEDICATION HISTORY ─────────────────────────
                    _SectionHeader(title: 'Medication History'),
                    const SizedBox(height: 8),
                    _RecordCard(
                      children: [
                        _RecordRow(
                          label: 'Total Doses Required',
                          value:
                              '${_patient?.compliance.totalDosesRequired ?? 168}',
                        ),
                        _RecordRow(
                          label: 'Doses Taken',
                          value: '${_patient?.compliance.dosesTaken ?? 0}',
                          valueColor: const Color(0xFF34A853),
                        ),
                        _RecordRow(
                          label: 'Doses Missed',
                          value: '${_patient?.compliance.dosesMissed ?? 0}',
                          valueColor: const Color(0xFFE53935),
                        ),
                        _RecordRow(
                          label: 'Compliance Rate',
                          value:
                              '${_patient?.compliance.compliancePercentage.toStringAsFixed(1) ?? 0}%',
                          valueColor: _blue,
                        ),
                        _RecordRow(
                          label: 'Adherence',
                          value: _patient?.compliance.adherence ?? 'Pending',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── SPUTUM TESTS ───────────────────────────────
                    _SectionHeader(title: 'Sputum Tests'),
                    const SizedBox(height: 8),
                    if (_sputumTests.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'No sputum tests recorded yet.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      )
                    else
                      ..._sputumTests.map(
                        (test) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Month ${test.month} Test',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF2D3748),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Due: ${test.formattedDueDate}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                  if (test.formattedCollectionDate != null)
                                    Text(
                                      'Collected: ${test.formattedCollectionDate}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                ],
                              ),
                              ResultBadge(
                                result: test.result,
                                isOverdue: test.isOverdue,
                              ),
                            ],
                          ),
                        ),
                      ),

                    // ── CONTACT TRACING ────────────────────────────
                    const SizedBox(height: 16),
                    _SectionHeader(title: 'Contact Tracing'),
                    const SizedBox(height: 8),
                    _RecordCard(
                      children: [
                        _RecordRow(
                          label: 'Number of Contacts',
                          value:
                              '${_patient?.contactTracing.numberOfContacts ?? 0}',
                        ),
                        if (_patient?.contactTracing.schedule != null)
                          _RecordRow(
                            label: 'Scheduled',
                            value: _formatDate(
                              _patient!.contactTracing.schedule!,
                            ),
                          ),
                      ],
                    ),

                    if (_patient?.additionalNotes.isNotEmpty == true) ...[
                      const SizedBox(height: 16),
                      _SectionHeader(title: 'Additional Notes'),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          _patient!.additionalNotes,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: const TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: Color(0xFF2D3748),
    ),
  );
}

class _RecordCard extends StatelessWidget {
  final List<Widget> children;
  const _RecordCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      children: children
          .expand((w) => [w, if (w != children.last) const Divider(height: 12)])
          .toList(),
    ),
  );
}

class _RecordRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _RecordRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
      Text(
        value,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: valueColor ?? const Color(0xFF2D3748),
        ),
      ),
    ],
  );
}
