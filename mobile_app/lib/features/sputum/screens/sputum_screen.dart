import 'package:flutter/material.dart';
import '../../../data/repositories/sputum_repository.dart';

class SputumScreen extends StatefulWidget {
  const SputumScreen({super.key});

  @override
  State<SputumScreen> createState() => _SputumScreenState();
}

class _SputumScreenState extends State<SputumScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _tests = [];

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
      final list = await SputumRepository.instance.getMyTests();
      setState(() {
        _tests = list;
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
      appBar: AppBar(title: const Text('Sputum Tests')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text('Error: $_error'))
          : ListView.builder(
              itemCount: _tests.length,
              itemBuilder: (context, i) =>
                  ListTile(title: Text(_tests[i].toString())),
            ),
    );
  }
}
