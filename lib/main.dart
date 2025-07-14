import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MaterialApp(
    home: PDFMultiDownloader(),
  ));
}

class PDFMultiDownloader extends StatefulWidget {
  const PDFMultiDownloader({super.key});

  @override
  State<PDFMultiDownloader> createState() => _PDFMultiDownloaderState();
}

class _PDFMultiDownloaderState extends State<PDFMultiDownloader> {
  final dio = Dio();

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

  Map<String, double> progressMap = {};
  Map<String, bool> downloadingMap = {};
  late Directory appDir;

  @override
  void initState() {
    super.initState();
    _initDirectory();
  }

  Future<void> _initDirectory() async {
    appDir = await getApplicationDocumentsDirectory();
    setState(() {});
  }

  Future<void> downloadPDF(Map<String, String> pdf) async {
    final url = pdf['url']!;
    final filename = pdf['file']!;
    final savePath = "${appDir.path}/$filename";

    // If already exists, open directly
    final file = File(savePath);
    if (await file.exists()) {
      await OpenFilex.open(savePath);
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Downloaded ${pdf['name']}!')),
      );

      await OpenFilex.open(savePath);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error downloading ${pdf['name']}: $e')),
      );
    } finally {
      setState(() {
        downloadingMap[filename] = false;
      });
    }
  }

  Future<void> clearDownloads() async {
    for (var pdf in pdfList) {
      final file = File("${appDir.path}/${pdf['file']}");
      if (await file.exists()) {
        await file.delete();
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All downloads cleared!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (appDir.path.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Multi PDF Downloader"),
        actions: [
          IconButton(
            onPressed: clearDownloads,
            icon: const Icon(Icons.delete),
            tooltip: 'Clear All Downloads',
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: pdfList.length,
        itemBuilder: (context, index) {
          final pdf = pdfList[index];
          final filename = pdf['file']!;
          final isDownloading = downloadingMap[filename] ?? false;
          final progress = progressMap[filename] ?? 0.0;

          return Card(
            child: ListTile(
              title: Text(pdf['name']!),
              subtitle: isDownloading
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LinearProgressIndicator(value: progress),
                        const SizedBox(height: 4),
                        Text("${(progress * 100).toStringAsFixed(0)}%"),
                      ],
                    )
                  : null,
              trailing: IconButton(
                icon: Icon(isDownloading ? Icons.downloading : Icons.download),
                onPressed: isDownloading ? null : () => downloadPDF(pdf),
              ),
            ),
          );
        },
      ),
    );
  }
}
