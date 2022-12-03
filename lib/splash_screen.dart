import 'dart:convert';
import 'dart:io';

import 'package:danisankitab/home_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'booknode.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool isTrying = true;
  bool isDownloading = false;

  Future<void> doIt() async {
    try {
      var apiResF = http.get("https://danisankitab.az/api2.json");
      var ttsResF = http.get("https://danisankitab.az/tts.json");

      var dir = await getApplicationDocumentsDirectory();
      final prefs = await SharedPreferences.getInstance();

      // tts.json
      // throw 1;
      var ttsRes = await ttsResF;
      if (ttsRes.statusCode != 200) throw Exception();
      int latestTtsVersion = jsonDecode(ttsRes.body)["updated_at"];
      int ttsDownloadSize = jsonDecode(ttsRes.body)["size"];
      int myTtsVersion = prefs.getInt("tts") ?? 0;
      bool requireTtsDownload =
          myTtsVersion != latestTtsVersion; //requireTtsDownload = true;
      print("latestTtsVersion: " + latestTtsVersion.toString());
      print("myTtsVersion: " + myTtsVersion.toString());
      print("requireTtsDownload: " + requireTtsDownload.toString());
      print("ttsDownloadSize: " + ttsDownloadSize.toString());

      // api.json
      var apiRes = await apiResF;
      if (apiRes.statusCode != 200) throw Exception();

      var json = jsonDecode(utf8.decode(apiRes.bodyBytes));
      List<BookNode> nodes = List<BookNode>();
      for (var i = 0; i < json.length; i++) {
        nodes.add(BookNode.fromJsonCategory(json[i], dir.path + "/tts/"));
      }

      // partial tts updater
      // var mp3s = (await Directory(dir.path + "/tts/").list().toList())
      //     .map((e) => e.path.split("/").last).toSet();
      // var filesToDelete = mp3s.difference(BookNode.ttsSet);
      // var filesToDownload = BookNode.ttsSet.difference(mp3s);
      // print("filesToDelete: " + filesToDelete.length.toString());
      // print("filesToDownload: " + filesToDownload.length.toString());
      //
      // if (filesToDownload.length < 10) {
      //   for(var i in filesToDownload) {
      //     var r = await http.get("https://danisankitab.az/persistent/" + i);
      //     await File(dir.path + "/tts/" + i).writeAsBytes(r.bodyBytes);
      //   }
      //   requireTtsDownload = false;
      //   await prefs.setInt("tts", latestTtsVersion);
      // }

      // get ttsMode from saved preferences
      bool ttsMode = prefs.getBool("ttsMode") ?? true;

      Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => HomePage(
                bookNodes: nodes,
                ttsMode: ttsMode,
                ttsDownloadSize: requireTtsDownload ? ttsDownloadSize : 0,
              )));
    } catch (e, s) {
      print(e);
      print(s);
      setState(() {
        isTrying = false;
      });
    }
  }

  @override
  void initState() {
    doIt();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(
      children: [
        Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: FractionalOffset.topCenter,
                  end: FractionalOffset.bottomCenter,
                  colors: [
                Color(0xff3edefe).withOpacity(0.7),
                Color(0xff43b7fe).withOpacity(0.7),
                Color(0xff4f59ff).withOpacity(0.8),
              ],
                  stops: [
                0.0,
                0.5,
                1.0
              ])),
        ),
        Align(
          alignment: Alignment.center,
          child: Image.asset(
            "assets/logo.png",
            width: 200,
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
              padding: EdgeInsets.only(bottom: 100),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isDownloading)
                    Padding(
                        padding: EdgeInsets.only(bottom: 20),
                        child: Text(
                          "Yeni səslər yüklənir...",
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        )),
                  !isTrying
                      ? ElevatedButton(
                          onPressed: () {
                            setState(() {
                              isTrying = true;
                            });
                            doIt();
                          },
                          child: Text("Yenidən cəhd et"),
                          // colorBrightness: Brightness.light,
                          // color: Colors.white,
                        )
                      : CircularProgressIndicator(
                          valueColor:
                              new AlwaysStoppedAnimation<Color>(Colors.white))
                ],
              )),
        ),
      ],
    ));
  }
}
