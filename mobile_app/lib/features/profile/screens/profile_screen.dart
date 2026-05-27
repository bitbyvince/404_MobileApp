import 'package:flutter/material.dart';
import '../../../data/repositories/patient_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loading = true;
  String? _error;
  dynamic _profile;

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
      setState(() {
        _profile = data;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text('Error: $_error'))
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Name: ${_profile?.firstName ?? ''} ${_profile?.lastName ?? ''}',
                  ),
                  const SizedBox(height: 8),
                  Text('Regimen: ${_profile?.regimen ?? 'N/A'}'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/profile/health-records'),
                    child: const Text('Health Records'),
                  ),
                ],
              ),
            ),
    );
  }
}
