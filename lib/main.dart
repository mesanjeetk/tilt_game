import 'package:flutter/material.dart';
import 'package:saf/saf.dart';

void main() {
  runApp(const SafExample());
}

class SafExample extends StatelessWidget {
  const SafExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SafHome(),
    );
  }
}

class SafHome extends StatefulWidget {
  @override
  State<SafHome> createState() => _SafHomeState();
}

class _SafHomeState extends State<SafHome> {
  Saf? saf;
  String folderUri = '';
  String folderName = '';

  Future<void> pickFolder() async {
    final granted = await Saf.getDirectoryPermission(isDynamic: true);

    if (granted) {
      final dirs = await Saf.getPersistedPermissionDirectories();
      if (dirs != null && dirs.isNotEmpty) {
        final uri = dirs.first;
        saf = Saf.fromUri(Uri.parse(uri));
        setState(() {
          folderUri = uri;
          folderName = saf?.name ?? 'Unknown';
        });
      } else {
        setState(() {
          folderUri = 'No persisted directories found.';
        });
      }
    } else {
      setState(() {
        folderUri = 'User denied permission.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saf Picker')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: pickFolder,
              child: const Text('Pick Folder'),
            ),
            const SizedBox(height: 20),
            Text('Folder Name: $folderName'),
            const SizedBox(height: 10),
            Text('Folder URI: $folderUri'),
          ],
        ),
      ),
    );
  }
}
