import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

void main() {
  runApp(const MaterialApp(home: PDFMultiDownloader()));
}

class PDFMultiDownloader extends StatefulWidget {
  const PDFMultiDownloader({super.key});

  @override
  State<PDFMultiDownloader> createState() => _PDFMultiDownloaderState();
}

class _PDFMultiDownloaderState extends State<PDFMultiDownloader> {
  final dio = Dio();
  late Directory appDir;
  File? cacheFile;
  Map<String, dynamic> downloadStatus = {}; // JSON structure
  Map<String, double> progressMap = {};
  Map<String, bool> downloadingMap = {};

  final List<Map<String, String>> pdfList = [
    {
      'name': 'Chapter 1',
      'url': 'https://mesanjeetk.github.io/neetx-2024/physics/ch1.pdf',
      'file': 'ch1.pdf',
    },
    {
      'name': 'Chapter 2',
      'url': 'https://mesanjeetk.github.io/neetx-2024/physics/ch2.pdf',
      'file': 'ch2.pdf',
    },
    {
      'name': 'Chapter 3',
      'url': 'https://mesanjeetk.github.io/neetx-2024/physics/ch3.pdf',
      'file': 'ch3.pdf',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initDirAndCache();
  }

  Future<void> _initDirAndCache() async {
    appDir = await getApplicationDocumentsDirectory();
    cacheFile = File("${appDir.path}/downloads.json");
    if (await cacheFile!.exists()) {
      final content = await cacheFile!.readAsString();
      downloadStatus = jsonDecode(content);
    }
    await _verifyFiles();
    setState(() {});
  }

  Future<void> _verifyFiles() async {
    bool updated = false;
    for (var pdf in pdfList) {
      final path = "${appDir.path}/${pdf['file']}";
      if (downloadStatus[pdf['file']] == true && !(await File(path).exists())) {
        downloadStatus[pdf['file']] = false;
        updated = true;
      }
    }
    if (updated) {
      await cacheFile!.writeAsString(jsonEncode(downloadStatus));
    }
  }

  Future<void> _saveCache() async {
    await cacheFile!.writeAsString(jsonEncode(downloadStatus));
  }

  Future<void> downloadPDF(Map<String, String> pdf) async {
    final url = pdf['url']!;
    final filename = pdf['file']!;
    final savePath = "${appDir.path}/$filename";

    if (downloadStatus[filename] == true) {
      _showViewer(savePath);
      return;
    }

    setState(() {
      downloadingMap[filename] = true;
      progressMap[filename] = 0.0;
    });

    try {
      await dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              progressMap[filename] = received / total;
            });
          }
        },
      );

      downloadStatus[filename] = true;
      await _saveCache();

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Downloaded ${pdf['name']}!')));
      _showViewer(savePath);

    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() {
        downloadingMap[filename] = false;
      });
    }
  }

  Future<void> _showViewer(String filePath) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PDFViewerScreen(filePath: filePath),
      ),
    );
  }

  Future<void> _openExternal(String filePath) async {
    await OpenFilex.open(filePath);
  }

  Future<void> _deleteFile(String filename) async {
    final file = File("${appDir.path}/$filename");
    if (await file.exists()) {
      await file.delete();
    }
    downloadStatus[filename] = false;
    await _saveCache();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (appDir.path.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Advanced PDF Downloader")),
      body: ListView.builder(
        itemCount: pdfList.length,
        itemBuilder: (context, index) {
          final pdf = pdfList[index];
          final filename = pdf['file']!;
          final isDownloading = downloadingMap[filename] ?? false;
          final isDownloaded = downloadStatus[filename] == true;
          final progress = progressMap[filename] ?? 0.0;

          return Card(
            child: ListTile(
              title: Text(pdf['name']!),
              subtitle: isDownloading
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LinearProgressIndicator(value: progress),
                        Text("${(progress * 100).toStringAsFixed(0)}%"),
                      ],
                    )
                  : null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isDownloaded) ...[
                    IconButton(
                      icon: const Icon(Icons.visibility),
                      tooltip: 'View in App',
                      onPressed: () => _showViewer("${appDir.path}/$filename"),
                    ),
                    IconButton(
                      icon: const Icon(Icons.open_in_new),
                      tooltip: 'Open with...',
                      onPressed: () => _openExternal("${appDir.path}/$filename"),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      tooltip: 'Delete',
                      onPressed: () => _deleteFile(filename),
                    ),
                  ] else
                    IconButton(
                      icon: const Icon(Icons.download),
                      tooltip: 'Download',
                      onPressed: isDownloading ? null : () => downloadPDF(pdf),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class PDFViewerScreen extends StatelessWidget {
  final String filePath;
  const PDFViewerScreen({super.key, required this.filePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("In-App PDF Viewer")),
      body: PDFView(
        filePath: filePath,
      ),
    );
  }
}
