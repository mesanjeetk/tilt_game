import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:saf/saf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  runApp(const MyApp());
}

const filesToDownload = [
  {
    'name': 'ch1.pdf',
    'url': 'https://mesanjeetk.github.io/neetx-2024/physics/ch1.pdf',
  },
  {
    'name': 'ch2.pdf',
    'url': 'https://mesanjeetk.github.io/neetx-2024/physics/ch1.pdf',
  },
  // Add more chapters!
];

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: SAFCacheApp(),
    );
  }
}

class SAFCacheApp extends StatefulWidget {
  const SAFCacheApp({super.key});
  @override
  State<SAFCacheApp> createState() => _SAFCacheAppState();
}

class _SAFCacheAppState extends State<SAFCacheApp> {
  SAF? saf;
  late File cacheFile;
  Map<String, dynamic> cacheData = {};
  bool loading = true;

  RewardedAd? rewardedAd;
  Map<String, double> downloadProgress = {}; // Store progress per file

  @override
  void initState() {
    super.initState();
    initCache();
    loadRewardedAd();
  }

  Future<void> initCache() async {
    final dir = await getApplicationDocumentsDirectory();
    cacheFile = File('${dir.path}/cache.json');

    if (await cacheFile.exists()) {
      cacheData = jsonDecode(await cacheFile.readAsString());
    } else {
      cacheData = {'folderUri': null, 'files': []};
    }

    if (cacheData['folderUri'] != null) {
      saf = SAF.fromUri(Uri.parse(cacheData['folderUri']));
      final validFiles = <dynamic>[];
      for (final file in cacheData['files']) {
        final exists = await saf!.exists(file['path']);
        if (exists) validFiles.add(file);
      }
      cacheData['files'] = validFiles;
      await saveCache();
    }

    setState(() => loading = false);
  }

  Future<void> pickFolder() async {
    saf = await SAF.getDirectoryPermission(isDynamic: true);
    if (saf != null) {
      cacheData['folderUri'] = saf!.persistableUri.toString();
      await saveCache();
      setState(() {});
    }
  }

  Future<void> loadRewardedAd() async {
    await RewardedAd.load(
      adUnitId: RewardedAd.testAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          rewardedAd = ad;
        },
        onAdFailedToLoad: (error) {
          debugPrint('Failed to load rewarded ad: $error');
          rewardedAd = null;
        },
      ),
    );
  }

  Future<void> showRewardedAd() async {
    if (rewardedAd == null) return;
    rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        debugPrint('User earned reward.');
      },
    );
    rewardedAd = null;
    loadRewardedAd();
  }

  Future<void> downloadFile(Map<String, String> fileInfo) async {
    if (saf == null) {
      await pickFolder();
      if (saf == null) return;
    }

    final dio = Dio();

    final response = await dio.get<List<int>>(
      fileInfo['url']!,
      options: Options(responseType: ResponseType.stream),
    );

    final bytes = <int>[];
    final total = response.headers.map['content-length'] != null
        ? int.parse(response.headers.map['content-length']!.first)
        : null;

    int received = 0;

    final stream = response.data!.stream;
    await for (final chunk in stream) {
      bytes.addAll(chunk);
      received += chunk.length;

      if (total != null) {
        setState(() {
          downloadProgress[fileInfo['url']!] = received / total;
        });
      }
    }

    final outputPath =
        await saf!.writeFile(Uint8List.fromList(bytes), fileName: fileInfo['name']);

    cacheData['files'].add({
      'name': fileInfo['name'],
      'url': fileInfo['url'],
      'path': outputPath,
      'lastPage': 0,
    });

    downloadProgress.remove(fileInfo['url']);
    await saveCache();
    await showRewardedAd();
    setState(() {});
  }

  Future<void> saveCache() async {
    await cacheFile.writeAsString(jsonEncode(cacheData), flush: true);
  }

  void openFile(Map<String, dynamic> file) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PDFReaderPage(
          saf: saf!,
          filePath: file['path'],
          fileName: file['name'],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('📚 SAF PDF Manager')),
      body: ListView(
        children: filesToDownload.map((fileInfo) {
          final localFile = cacheData['files'].firstWhere(
            (f) => f['url'] == fileInfo['url'],
            orElse: () => null,
          );
          final progress = downloadProgress[fileInfo['url']!] ?? 0.0;

          return ListTile(
            title: Text(fileInfo['name']!),
            subtitle: progress > 0
                ? LinearProgressIndicator(value: progress)
                : localFile != null && localFile['lastPage'] > 0
                    ? Text('Last page read: ${localFile['lastPage'] + 1}')
                    : null,
            trailing: localFile == null
                ? ElevatedButton(
                    onPressed: () => downloadFile(fileInfo),
                    child: const Text('Download'),
                  )
                : ElevatedButton(
                    onPressed: () => openFile(localFile),
                    child: const Text('Open'),
                  ),
          );
        }).toList(),
      ),
    );
  }
}

class PDFReaderPage extends StatefulWidget {
  final SAF saf;
  final String filePath;
  final String fileName;

  const PDFReaderPage({
    super.key,
    required this.saf,
    required this.filePath,
    required this.fileName,
  });

  @override
  State<PDFReaderPage> createState() => _PDFReaderPageState();
}

class _PDFReaderPageState extends State<PDFReaderPage> {
  final PdfViewerController _controller = PdfViewerController();
  BannerAd? bannerAd;

  Future<Uint8List> loadBytes() async {
    return await widget.saf.readFile(widget.filePath);
  }

  @override
  void initState() {
    super.initState();
    bannerAd = BannerAd(
      adUnitId: BannerAd.testAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {});
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    bannerAd?.dispose();
    super.dispose();
  }

  Widget buildBanner() {
    return bannerAd == null
        ? const SizedBox.shrink()
        : SizedBox(
            width: bannerAd!.size.width.toDouble(),
            height: bannerAd!.size.height.toDouble(),
            child: AdWidget(ad: bannerAd!),
          );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.fileName)),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<Uint8List>(
              future: loadBytes(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return SfPdfViewer.memory(snapshot.data!);
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
          buildBanner(),
        ],
      ),
    );
  }
}
