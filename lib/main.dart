import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:saf/saf.dart';

void main() {
  runApp(MaterialApp(home: SAFDownloader()));
}

class SAFDownloader extends StatefulWidget {
  @override
  State<SAFDownloader> createState() => _SAFDownloaderState();
}

class _SAFDownloaderState extends State<SAFDownloader> {
  SAF? saf;
  Map<String, String> cache = {};
  double progress = 0.0;

  final files = {
    'Chapter 1': 'https://mesanjeetk.github.io/neetx-2024/physics/ch1.pdf',
    'Chapter 2': 'https://mesanjeetk.github.io/neetx-2024/physics/ch1.pdf',
  };

  @override
  void initState() {
    super.initState();
    loadCache();
  }

  Future<void> loadCache() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/cache.json');
    if (await file.exists()) {
      final json = jsonDecode(await file.readAsString());
      cache = Map<String, String>.from(json['files']);
      if (json['folderUri'] != null) {
        saf = SAF.fromUri(Uri.parse(json['folderUri']));
      }
      await verifyFiles();
    }
    setState(() {});
  }

  Future<void> verifyFiles() async {
    final verified = <String, String>{};
    for (final entry in cache.entries) {
      final file = File(entry.value);
      if (await file.exists()) {
        verified[entry.key] = entry.value;
      }
    }
    cache = verified;
    await saveCache();
  }

  Future<void> saveCache() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/cache.json');
    final json = {
      'folderUri': saf?.uri.toString(),
      'files': cache,
    };
    await file.writeAsString(jsonEncode(json));
  }

  Future<void> pickFolder() async {
    saf = await SAF.getDirectoryPermission(isDynamic: true);
    await saveCache();
    setState(() {});
  }

  Future<void> downloadFile(String name, String url) async {
    if (saf == null) {
      await pickFolder();
      if (saf == null) return;
    }

    final fileName = '$name.pdf';
    final dio = Dio();

    final response = await dio.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
      onReceiveProgress: (received, total) {
        setState(() {
          progress = received / total;
        });
      },
    );

    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/$fileName');
    await tempFile.writeAsBytes(response.data!);

    final writtenFile = await saf!.writeToFile(
      name: fileName,
      bytes: response.data!,
      mimeType: 'application/pdf',
    );

    cache[name] = writtenFile!.path;
    await saveCache();

    setState(() {
      progress = 0;
    });

    openPdf(writtenFile.path);
  }

  void openPdf(String path) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PDFViewPage(path: path),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('SAF PDF Downloader')),
      body: Column(
        children: [
          if (progress > 0)
            LinearProgressIndicator(value: progress),
          Expanded(
            child: ListView(
              children: files.entries.map((entry) {
                final downloaded = cache.containsKey(entry.key);
                return ListTile(
                  title: Text(entry.key),
                  subtitle: downloaded
                      ? Text('Downloaded')
                      : Text('Not downloaded'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      if (downloaded) {
                        openPdf(cache[entry.key]!);
                      } else {
                        downloadFile(entry.key, entry.value);
                      }
                    },
                    child: Text(downloaded ? 'Open' : 'Download'),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class PDFViewPage extends StatelessWidget {
  final String path;

  PDFViewPage({required this.path});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('PDF Viewer')),
      body: PDFView(
        filePath: path,
      ),
    );
  }
}
