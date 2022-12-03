import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:danisankitab/selector_page.dart';
import 'package:danisankitab/selector_page_tts.dart';
import 'package:danisankitab/sliding_segmented_control.dart';
import 'package:flutter/cupertino.dart' as cupertino;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_archive/flutter_archive.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'booknode.dart';

const descText =
    "Azərbaycan Respublikası Əmək və Əhalinin Sosial Müdafiəsi Nazirliyinin sosial sifarişi ilə bu kitabların səsləndirilməsi təşkil edilmişdir.";

class HomePage extends StatefulWidget {
  final List<BookNode> bookNodes;
  final bool ttsMode;
  final int ttsDownloadSize;

  HomePage(
      {Key key,
      @required this.bookNodes,
      @required this.ttsMode,
      @required this.ttsDownloadSize})
      : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  bool ttsMode = true;
  bool requireDownload = false;
  AudioPlayer plyr;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print(state);
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      if (plyr != null) {
        plyr.stop();
        // plyr.dispose();
        // plyr = null;
      }
    }
  }

  @override
  initState() {
    super.initState();
    // SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(systemNavigationBarColor: Colors.white, systemNavigationBarIconBrightness: Brightness.dark));
    requireDownload = widget.ttsDownloadSize > 0;
    ttsMode = widget.ttsMode && (!requireDownload);
    plyr = AudioPlayer();
    WidgetsBinding.instance.addObserver(this);

    if (ttsMode) {
      playTts(true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> playTts(bool withWelcome) async {
    await plyr.load(ConcatenatingAudioSource(
        children: withWelcome
            ? [
                AudioSource.uri(Uri.parse('asset:///assets/welcome.mp3')),
                AudioSource.uri(Uri.parse('asset:///assets/nazirlikinfo.mp3')),
                AudioSource.uri(
                    Uri.parse('asset:///assets/entertocategories.mp3'))
              ]
            : [
                AudioSource.uri(
                    Uri.parse('asset:///assets/entertocategories.mp3'))
              ]));
    await plyr.play();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
              child: GestureDetector(
            child: topPart(),
            onTap: () async {
              if (ttsMode) {
                playTts(false);
              } else {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) =>
                        SelectorPage(bookNodes: widget.bookNodes)));
              }
            },
            onDoubleTap: () async {
              if (ttsMode) {
                plyr.stop();
                await Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) =>
                        SelectorPageTts(bookNodes: widget.bookNodes)));
                await plyr.load(ConcatenatingAudioSource(children: [
                  AudioSource.uri(Uri.parse('asset:///assets/homepage.mp3')),
                  AudioSource.uri(
                      Uri.parse('asset:///assets/entertocategories.mp3'))
                ]));
                await plyr.play();
              } else {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) =>
                        SelectorPage(bookNodes: widget.bookNodes)));
              }
            },
          )),
          SafeArea(
              top: false,
              bottom: true,
              child: Padding(
                padding: EdgeInsets.all(10),
                child: CupertinoSlidingSegmentedControl(
                    children: {
                      "a": Padding(
                        child: Text("Normal rejim"),
                        padding: EdgeInsets.symmetric(vertical: 15),
                      ),
                      "b": Text("Səsli rejim")
                    },
                    groupValue: ttsMode ? "b" : "a",
                    onValueChanged: (s) async {
                      if (s == "b" && requireDownload) {
                        s = (await showDownloadModal()) ? "b" : "a";
                        if (s == "b") {
                          requireDownload = false;
                        }
                      }

                      setState(() {
                        ttsMode = (s == "b");
                      });
                      if (ttsMode) {
                        AudioService.connect().then((value) {
                          AudioService.stop();
                        }).then((value) {
                          AudioService.disconnect();
                        });
                        playTts(false);
                      } else {
                        plyr.stop();
                      }
                      SharedPreferences.getInstance()
                          .then((value) => value.setBool("ttsMode", ttsMode));
                    }),
              ))
        ],
      ),
    );
  }

  Widget topPart() {
    return ClipRRect(
        borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(50), bottomRight: Radius.circular(50)),
        child: Stack(children: <Widget>[
          Container(
            decoration: BoxDecoration(
              color: Colors.transparent,
              image: DecorationImage(
                fit: BoxFit.cover,
                image: AssetImage(
                  'assets/kids.png',
                ),
              ),
            ),
            // height: 400,
          ),
          AnimatedContainer(
            duration: Duration(milliseconds: 200),
            // height: 400,
            decoration: BoxDecoration(
                color: Colors.white,
                gradient: LinearGradient(
                    begin: FractionalOffset.topCenter,
                    end: FractionalOffset.bottomCenter,
                    colors: !ttsMode
                        ? [
                            Color(0xfff1c40f).withOpacity(0.7),
                            Color(0xffe67e22).withOpacity(0.7),
                            Color(0xffd35400).withOpacity(0.8),
                          ]
                        : [
                            Color(0xff3edefe).withOpacity(0.7),
                            Color(0xff43b7fe).withOpacity(0.7),
                            Color(0xff4f59ff).withOpacity(0.8),
                          ],
                    stops: [0.0, 0.5, 1.0])),
          ),
          Center(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                "assets/logo.png",
                width: 200,
              ),
              Container(
                height: 30,
              ),
              Text(
                descText,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              )
            ],
          ))
        ]));
  }

  Future<bool> showDownloadModal() async {
    var r = await showModalBottomSheet(
        context: context,
        builder: (c) {
          return TtsDownloader(widget.ttsDownloadSize);
        });
    return r == "ok";
    print(r);
    setState(() {
      ttsMode = r == "ok";
    });
  }
}

class TtsDownloader extends StatefulWidget {
  final int ttsDownloadSize;
  TtsDownloader(this.ttsDownloadSize);

  @override
  _TtsDownloaderState createState() => _TtsDownloaderState();
}

class _TtsDownloaderState extends State<TtsDownloader> {
  bool isDownloading = false;
  bool hasError = false;
  int progress = 0;
  int progressMax = 1;

  Future<void> doIt() async {
    setState(() {
      isDownloading = true;
      hasError = false;
    });
    try {
      var dir = await getApplicationDocumentsDirectory();
      final prefs = await SharedPreferences.getInstance();

      var ttsRes = await http.get("https://danisankitab.az/tts.json");
      if (ttsRes.statusCode != 200) throw Exception();
      int latestTtsVersion = jsonDecode(ttsRes.body)["updated_at"];

      var dFile = File(dir.path + "/tts.zip");
      var r = await (await HttpClient()
              .getUrl(Uri.parse("https://danisankitab.az/tts.zip")))
          .close();
      await r.map((event) {
        setState(() {
          progress += event.length;
        });
        return event;
      }).pipe(dFile.openWrite());

      // var ttsZipRes = await http.get("https://danisankitab.az/tts.zip");
      // if (ttsZipRes.statusCode != 200) throw Exception();
      // var fl = await File(dir.path + "/tts.zip").writeAsBytes(ttsZipRes.bodyBytes);

      var destDir = Directory(dir.path + "/tts/");
      if (await destDir.exists()) {
        await destDir.delete(recursive: true);
      }
      await ZipFile.extractToDirectory(
          zipFile: dFile, destinationDir: Directory(dir.path + "/tts/"));
      await dFile.delete();
      await prefs.setInt("tts", latestTtsVersion);
      Navigator.of(context).pop("ok");
    } catch (e) {
      setState(() {
        isDownloading = false;
        hasError = true;
        progress = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (hasError) {
      return Container(
          height: 300,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 50,
                color: Colors.black54,
              ),
              TextButton(
                child: Text("Yenidən cəhd et"),
                onPressed: doIt,
              )
            ],
          ));
    }

    if (isDownloading) {
      double p = progress.toDouble() / widget.ttsDownloadSize.toDouble();
      return Container(
          height: 300,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(value: p > 0 && p < 1.0 ? p : null),
              Container(
                height: 20,
              ),
              Text(p < 1.0
                  ? "Yüklənir " + (p * 100).round().toString() + "%"
                  : "Gözləyin...")
            ],
          ));
    }

    return Container(
        height: 300,
        // padding: EdgeInsets.only(top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Icon(Icons.cloud_download_outlined,
                    size: 100, color: Colors.black54),
                Text("Səsli rejim üçün əlavə yükləmə tələb olunur.")
              ],
            )),
            SafeArea(
                top: false,
                child: ButtonBar(
                  alignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                        onPressed: () {
                          Navigator.of(context).pop("cancel");
                        },
                        child: Text("İmtina")),
                    TextButton(
                      onPressed: doIt,
                      child:
                          Text("Yüklə (${filesize(widget.ttsDownloadSize)})"),
                    )
                  ],
                ))
          ],
        ));
  }
}

// from https://github.com/synw/filesize
String filesize(dynamic size, [int round = 0]) {
  /**
   * [size] can be passed as number or as string
   *
   * the optional parameter [round] specifies the number
   * of digits after comma/point (default is 2)
   */
  int divider = 1024;
  int _size;
  try {
    _size = int.parse(size.toString());
  } catch (e) {
    throw ArgumentError("Can not parse the size parameter: $e");
  }

  if (_size < divider) {
    return "$_size B";
  }

  if (_size < divider * divider && _size % divider == 0) {
    return "${(_size / divider).toStringAsFixed(0)} KB";
  }

  if (_size < divider * divider) {
    return "${(_size / divider).toStringAsFixed(round)} KB";
  }

  if (_size < divider * divider * divider && _size % divider == 0) {
    return "${(_size / (divider * divider)).toStringAsFixed(0)} MB";
  }

  if (_size < divider * divider * divider) {
    return "${(_size / divider / divider).toStringAsFixed(round)} MB";
  }

  if (_size < divider * divider * divider * divider && _size % divider == 0) {
    return "${(_size / (divider * divider * divider)).toStringAsFixed(0)} GB";
  }

  if (_size < divider * divider * divider * divider) {
    return "${(_size / divider / divider / divider).toStringAsFixed(round)} GB";
  }

  if (_size < divider * divider * divider * divider * divider &&
      _size % divider == 0) {
    num r = _size / divider / divider / divider / divider;
    return "${r.toStringAsFixed(0)} TB";
  }

  if (_size < divider * divider * divider * divider * divider) {
    num r = _size / divider / divider / divider / divider;
    return "${r.toStringAsFixed(round)} TB";
  }

  if (_size < divider * divider * divider * divider * divider * divider &&
      _size % divider == 0) {
    num r = _size / divider / divider / divider / divider / divider;
    return "${r.toStringAsFixed(0)} PB";
  } else {
    num r = _size / divider / divider / divider / divider / divider;
    return "${r.toStringAsFixed(round)} PB";
  }
}
