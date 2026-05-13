// lib/providers/education_provider.dart

import 'package:flutter/material.dart';
import '../models/education_content.model.dart';
import '../services/education_service.dart';

class EducationProvider extends ChangeNotifier {
  final EducationService _service = EducationService();

  List<EducationContent> _contents = [];
  List<EducationContent> _filtered = [];
  String? _selectedCategory;
  String? _selectedRiskLevel;
  bool _isLoading = false;
  String? _error;

  // ─── GETTERS ──────────────────────────────────────────────────────────────

  List<EducationContent> get contents => _filtered;
  String? get selectedCategory => _selectedCategory;
  String? get selectedRiskLevel => _selectedRiskLevel;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ─── FETCH ALL ────────────────────────────────────────────────────────────

  Future<void> fetchAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _contents = await _service.getAll();
      _applyFilters();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── FETCH BY RISK LEVEL ──────────────────────────────────────────────────

  Future<void> fetchByRiskLevel(String riskLevel) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _contents = await _service.getByRiskLevel(riskLevel);
      _selectedRiskLevel = riskLevel;
      _applyFilters();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── FILTERS ──────────────────────────────────────────────────────────────

  void setCategory(String? category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  void setRiskLevel(String? riskLevel) {
    _selectedRiskLevel = riskLevel;
    _applyFilters();
    notifyListeners();
  }

  void clearFilters() {
    _selectedCategory = null;
    _selectedRiskLevel = null;
    _filtered = List.from(_contents);
    notifyListeners();
  }

  void _applyFilters() {
    _filtered = _contents.where((c) {
      final matchCategory =
          _selectedCategory == null || c.category == _selectedCategory;
      final matchRiskLevel =
          _selectedRiskLevel == null || c.riskLevelTarget == _selectedRiskLevel;
      return matchCategory && matchRiskLevel;
    }).toList();
  }
}
