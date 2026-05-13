// lib/services/education_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/education_content.model.dart';
import '../utils/jwt_helper.dart';

class EducationService {
  // ─── GET ALL CONTENT ─────────────────────────────────────────────────────

  Future<List<EducationContent>> getAll() async {
    final token = await JwtHelper.getToken();

    final response = await http.get(
      Uri.parse(ApiConfig.education),
      headers: ApiConfig.headers(token: token),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List list = data['contents'] ?? [];
      return list.map((e) => EducationContent.fromJson(e)).toList();
    }
    throw Exception('Failed to load education content.');
  }

  // ─── GET BY RISK LEVEL ───────────────────────────────────────────────────

  Future<List<EducationContent>> getByRiskLevel(String riskLevel) async {
    final token = await JwtHelper.getToken();

    final response = await http.get(
      Uri.parse('${ApiConfig.education}/by-risk/$riskLevel'),
      headers: ApiConfig.headers(token: token),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List list = data['contents'] ?? [];
      return list.map((e) => EducationContent.fromJson(e)).toList();
    }
    throw Exception(
      'Failed to load education content for risk level: $riskLevel.',
    );
  }

  // ─── GET SINGLE ARTICLE ──────────────────────────────────────────────────

  Future<EducationContent> getById(String id) async {
    final token = await JwtHelper.getToken();

    final response = await http.get(
      Uri.parse('${ApiConfig.education}/$id'),
      headers: ApiConfig.headers(token: token),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return EducationContent.fromJson(data['content']);
    }
    throw Exception('Failed to load article.');
  }

  // ─── GET BY CATEGORY ─────────────────────────────────────────────────────

  Future<List<EducationContent>> getByCategory(String category) async {
    final token = await JwtHelper.getToken();

    final uri = Uri.parse(
      ApiConfig.education,
    ).replace(queryParameters: {'category': category});

    final response = await http.get(
      uri,
      headers: ApiConfig.headers(token: token),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List list = data['contents'] ?? [];
      return list.map((e) => EducationContent.fromJson(e)).toList();
    }
    throw Exception(
      'Failed to load education content for category: $category.',
    );
  }
}
