import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

import 'pdf_viewer_page.dart';

class YearPDFPage extends StatefulWidget {
  final String year;
  const YearPDFPage({super.key, required this.year});

  @override
  State<YearPDFPage> createState() => _YearPDFPageState();
}

class _YearPDFPageState extends State<YearPDFPage> {
  final dio = Dio();
  late Directory appDir;
  bool isDownloaded = false;
  bool isDownloading = false;
  double progress = 0.0;
  String? filePath;

  @override
  void initState() {
    super.initState();
    initDownloadStatus();
  }

  Future<void> initDownloadStatus() async {
    appDir = await getApplicationDocumentsDirectory();
    filePath = "${appDir.path}/${widget.year}.pdf";
    final file = File(filePath!);
    if (await file.exists()) {
      isDownloaded = true;
    }
    setState(() {});
  }

  Future<void> downloadPDF() async {
    final url = "https://mesanjeetk.github.io/neetx-core/pdfs/${widget.year}.pdf";
    setState(() {
      isDownloading = true;
      progress = 0.0;
    });

    try {
      await dio.download(
        url,
        filePath!,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              progress = received / total;
            });
          }
        },
      );
      isDownloaded = true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Downloaded ${widget.year} PDF")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() {
        isDownloading = false;
      });
    }
  }

  void openInApp() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PDFViewerScreen(filePath: filePath!),
      ),
    );
  }

  void openExternal() {
    OpenFilex.open(filePath!);
  }

  void deletePDF() async {
    final file = File(filePath!);
    if (await file.exists()) {
      await file.delete();
    }
    isDownloaded = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${widget.year} PYQ")),
      body: Center(
        child: isDownloading
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 10),
                  Text("${(progress * 100).toStringAsFixed(0)}%"),
                ],
              )
            : isDownloaded
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: openInApp,
                        child: const Text("View in App"),
                      ),
                      ElevatedButton(
                        onPressed: openExternal,
                        child: const Text("Open with other app"),
                      ),
                      ElevatedButton(
                        onPressed: deletePDF,
                        child: const Text("Delete PDF"),
                      ),
                    ],
                  )
                : ElevatedButton(
                    onPressed: downloadPDF,
                    child: const Text("Download PDF"),
                  ),
      ),
    );
  }
}
