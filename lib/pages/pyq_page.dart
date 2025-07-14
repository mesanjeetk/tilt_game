import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

class PYQPage extends StatefulWidget {
  const PYQPage({super.key});

  @override
  State<PYQPage> createState() => _PYQPageState();
}

class _PYQPageState extends State<PYQPage> {
  List<int> years = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchYears();
  }

  Future<void> fetchYears() async {
    const apiUrl = 'https://mesanjeetk.github.io/neetx-core/neetData.json';
    final response = await http.get(Uri.parse(apiUrl));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      years = List<int>.from(data['years']);
    }
    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PYQs')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: years.length,
              itemBuilder: (context, index) {
                final year = years[index];
                return Card(
                  child: ListTile(
                    title: Text("$year PYQ"),
                    onTap: () => context.go('/pyqs/$year'),
                  ),
                );
              },
            ),
    );
  }
}
