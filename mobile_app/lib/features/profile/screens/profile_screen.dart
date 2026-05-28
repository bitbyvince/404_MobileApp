import 'package:flutter/material.dart';
import '../../../data/repositories/patient_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../services/secure_storage_service.dart';
import '../../../data/models/patient_model.dart';
import '../../../core/router/route_names.dart';
import '../widgets/profile_info_tile.dart';
import '../widgets/treatment_info_card.dart';
import '../widgets/drug_regimen_list.dart' as regimen;
import '../widgets/adherence_summary_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _blue = Color(0xFF1A73E8);
  static const _navy = Color(0xFF1A3A5C);

  bool _loading = true;
  String? _error;
  PatientModel? _patient;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await PatientRepository.instance.getMyProfile();
      setState(() => _patient = data);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await AuthRepository.instance.logout();
    } catch (_) {}
    await SecureStorageService.wipeAll();
    if (mounted) {
      Navigator.pushReplacementNamed(context, RouteNames.login);
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
          'Profile',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _logout,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Error: $_error'),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // ── AVATAR BANNER ──────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _navy,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                _patient != null
                                    ? '${_patient!.firstName[0]}${_patient!.lastName[0]}'
                                    : 'P',
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _patient?.fullName ?? 'Patient',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _patient?.tbCaseNumber ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.75),
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _blue,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _patient?.treatmentPhase ?? 'Intensive',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── PERSONAL INFO ──────────────────────────
                    ProfileInfoTile(
                      label: 'Phone Number',
                      value: _patient?.phoneNumber ?? 'N/A',
                      icon: Icons.phone_outlined,
                      isEditable: true,
                    ),
                    ProfileInfoTile(
                      label: 'Email',
                      value: _patient?.email ?? 'Not provided',
                      icon: Icons.email_outlined,
                      isEditable: true,
                    ),
                    ProfileInfoTile(
                      label: 'Health Center',
                      value: _patient?.healthCenterName ?? 'N/A',
                      icon: Icons.local_hospital_outlined,
                    ),
                    ProfileInfoTile(
                      label: 'Barangay',
                      value: _patient?.barangayName ?? 'N/A',
                      icon: Icons.location_on_outlined,
                    ),
                    ProfileInfoTile(
                      label: 'Sex',
                      value: _patient?.sex ?? 'N/A',
                      icon: Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: 4),

                    // ── TREATMENT INFO ─────────────────────────
                    if (_patient != null)
                      TreatmentInfoCard(
                        treatmentPhase: _patient!.treatmentPhase,
                        regimenType: _patient!.regimenType,
                        datSupport: _patient!.datSupport,
                        locationOfTreatment: _patient!.locationOfTreatment,
                        dateStarted: _patient!.dateStarted,
                        endDate: _patient!.endDate,
                        progress: _patient!.treatmentProgress,
                      ),
                    const SizedBox(height: 12),

                    // ── DRUG REGIMEN ───────────────────────────
                    if (_patient != null)
                      regimen.DrugRegimenList(
                        drugs: _patient!.drugRegimen
                            .map(
                              (d) => regimen.DrugRegimenItem(
                                drugName: d.drugName,
                                strength: d.strength,
                                unit: d.unit,
                                numberToBeTaken: d.numberToBeTaken,
                              ),
                            )
                            .toList(),
                      ),
                    const SizedBox(height: 12),

                    // ── ADHERENCE SUMMARY ──────────────────────
                    if (_patient != null)
                      AdherenceSummaryCard(
                        dosesTaken: _patient!.compliance.dosesTaken,
                        dosesMissed: _patient!.compliance.dosesMissed,
                        dosesRemaining: _patient!.compliance.dosesRemaining,
                        compliancePercentage:
                            _patient!.compliance.compliancePercentage,
                        consecutiveMissedDoses:
                            _patient!.compliance.consecutiveMissedDoses,
                        riskLevel: _patient!.compliance.riskLevel,
                        riskScore: _patient!.riskScore.score,
                        adherence: _patient!.compliance.adherence,
                      ),
                    const SizedBox(height: 12),

                    // ── HEALTH RECORDS BUTTON ──────────────────
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          RouteNames.healthRecords,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _navy,
                          side: const BorderSide(color: Color(0xFF1A3A5C)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.folder_outlined, size: 18),
                        label: const Text(
                          'View Full Health Records',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}
