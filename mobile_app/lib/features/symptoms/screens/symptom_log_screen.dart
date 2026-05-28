import 'package:flutter/material.dart';
import '../../../data/repositories/symptom_repository.dart';
import '../../../data/models/symptom_log_model.dart';
import '../widgets/symptom_chip_selector.dart';
import '../widgets/severity_slider.dart';
import '../widgets/symptom_history_tile.dart';

class SymptomLogScreen extends StatefulWidget {
  const SymptomLogScreen({super.key});

  @override
  State<SymptomLogScreen> createState() => _SymptomLogScreenState();
}

class _SymptomLogScreenState extends State<SymptomLogScreen>
    with SingleTickerProviderStateMixin {
  static const _blue = Color(0xFF1A73E8);
  static const _navy = Color(0xFF1A3A5C);
  static const _green = Color(0xFF34A853);

  late TabController _tabController;
  final Map<String, int> _selectedSymptoms = {};
  final _notesController = TextEditingController();
  bool _submitting = false;
  bool _loadingHistory = true;
  List<SymptomLogModel> _history = [];

  static const _available = [
    'Nausea',
    'Vomiting',
    'Rash',
    'Joint Pain',
    'Dizziness',
    'Blurred Vision',
    'Abdominal Pain',
    'Fever',
    'Fatigue',
    'Tingling in Hands/Feet',
    'Dark Urine',
    'Yellowing of Skin',
    'Hearing Loss',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _loadingHistory = true);
    try {
      final result = await SymptomRepository.instance.getHistory(
        page: 1,
        limit: 20,
      );
      setState(() => _history = result.logs);
    } catch (_) {
    } finally {
      setState(() => _loadingHistory = false);
    }
  }

  Future<void> _submit() async {
    if (_selectedSymptoms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one symptom.')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final entries = _selectedSymptoms.entries
          .map((e) => SymptomEntry(symptom: e.key, severity: e.value))
          .toList();
      await SymptomRepository.instance.submitLog(
        symptoms: entries,
        freeTextNotes: _notesController.text.trim(),
      );
      setState(() {
        _selectedSymptoms.clear();
        _notesController.clear();
      });
      await _loadHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Symptoms submitted successfully.'),
            backgroundColor: _green,
          ),
        );
        _tabController.animateTo(1);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
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
          'Log Symptoms',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Log Today'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildLogTab(), _buildHistoryTab()],
      ),
    );
  }

  Widget _buildLogTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── INSTRUCTION BANNER ────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _blue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Select any symptoms you experienced after taking your medication today.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── CHIP SELECTOR ─────────────────────────────
          const Text(
            'Select Symptoms',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 10),
          SymptomChipSelector(
            availableSymptoms: _available,
            selectedSymptoms: _selectedSymptoms,
            onToggle: (s) => setState(() {
              if (_selectedSymptoms.containsKey(s)) {
                _selectedSymptoms.remove(s);
              } else {
                _selectedSymptoms[s] = 1;
              }
            }),
          ),
          const SizedBox(height: 20),

          // ── SEVERITY SLIDERS ──────────────────────────
          if (_selectedSymptoms.isNotEmpty) ...[
            const Text(
              'Set Severity',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 10),
            ..._selectedSymptoms.keys.map(
              (symptom) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SeveritySlider(
                  symptom: symptom,
                  severity: _selectedSymptoms[symptom]!,
                  onChanged: (s, v) => setState(() => _selectedSymptoms[s] = v),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],

          // ── NOTES ─────────────────────────────────────
          const Text(
            'Additional Notes (optional)',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Describe how you feel...',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _blue, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── SUBMIT ────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Submit Symptom Log',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_loadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_history.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_rounded, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'No symptom logs yet.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _history.length,
        itemBuilder: (context, i) {
          final log = _history[i];
          return SymptomHistoryTile(
            date: log.formattedDate,
            time: log.formattedTime,
            symptoms: log.symptomNames,
            overallSeverity: log.overallSeverityLabel,
            summarySentence: log.summarySentence,
            isReviewed: log.isReviewed,
          );
        },
      ),
    );
  }
}
