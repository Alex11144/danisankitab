import 'package:cached_network_image/cached_network_image.dart';
import 'package:danisankitab/booknode.dart';
import 'package:danisankitab/player_page_tts.dart';
import 'package:danisankitab/selector_page.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class SelectorPageTts extends StatefulWidget {

  final List<BookNode> bookNodes;
  SelectorPageTts({Key key, @required this.bookNodes}) : super(key: key);

  @override
  _SelectorPageTtsState createState() => _SelectorPageTtsState();
}

class _SelectorPageTtsState extends State<SelectorPageTts> with WidgetsBindingObserver {

  int selectedItem = 0;

  AudioPlayer _player = AudioPlayer();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      if (_player != null) {
        _player.stop();
      }
    }
  }

  static bool isPlayedNavinfo = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _player.load(ConcatenatingAudioSource(
        children: [
          AudioSource.uri(Uri.parse('asset:///assets/categories.mp3')),
          if (!isPlayedNavinfo) AudioSource.uri(Uri.parse('asset:///assets/navinfo.mp3')),
          AudioSource.uri(Uri.file(widget.bookNodes[selectedItem].tts))
        ]
    ));
    _player.play();
    WidgetsBinding.instance.addObserver(this);
    isPlayedNavinfo = true;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () async {
          print(widget.bookNodes[selectedItem].tts);
          await _player.setFilePath(widget.bookNodes[selectedItem].tts);
          await _player.play();
          print("done.");
        },
        onDoubleTap: () async {
          _player.stop();
          if (widget.bookNodes[selectedItem].isCategory)
            await Navigator.push(context, MaterialPageRoute(builder: (context) => SelectorPageTts(bookNodes: widget.bookNodes[selectedItem].children)));
          else
            await Navigator.push(context, MaterialPageRoute(builder: (context) => PlayerPageTts(widget.bookNodes[selectedItem])));
          await _player.load(ConcatenatingAudioSource(
              children: [
                AudioSource.uri(Uri.parse('asset:///assets/categories.mp3')),
                AudioSource.uri(Uri.file(widget.bookNodes[selectedItem].tts))
              ]
          ));
          await _player.play();
        },
        onHorizontalDragEnd: (DragEndDetails details) async {
          var l = widget.bookNodes.length;
          int i = 0;
          if (details.primaryVelocity > 0) {
            i = (selectedItem + 1) % l;
          } else if (details.primaryVelocity < 0) {
            i = (selectedItem + (l - 1)) % l;
          } else return;
          setState(() {
            selectedItem = i;
          });
          await _player.setFilePath(widget.bookNodes[i].tts);
          await _player.play();
        },
        onVerticalDragEnd: (DragEndDetails details){
          if (details.primaryVelocity > 10) {
            Navigator.of(context).pop();
          }
        },
        child: Container(
          constraints: BoxConstraints.expand(),
          color: Colors.white,
          child: SafeArea(child: myGrid((selectedItem/6).floor() * 6))
        )
      ),
    );
  }

  Widget myGrid(int offset) {

    return Padding(padding: EdgeInsets.all(5), child: Column(
      children: [
        Expanded(child: Row(children: [Expanded(child: myGridI(offset + 0)), Expanded(child: myGridI(offset + 1))])),
        Expanded(child: Row(children: [Expanded(child: myGridI(offset + 2)), Expanded(child: myGridI(offset + 3))])),
        Expanded(child: Row(children: [Expanded(child: myGridI(offset + 4)), Expanded(child: myGridI(offset + 5))])),
      ],
    ));
  }

  Widget myGridI(int index) {
    if (index >= widget.bookNodes.length) return Container();
    // return SelectorItemWidget(widget.bookNodes[index]);
    return Container(
      // margin: const EdgeInsets.all(15.0),
      // padding: const EdgeInsets.all(3.0),
      decoration: index == selectedItem ? BoxDecoration(
        borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red, width: 3)
      ) : null,
      child: SelectorItemWidget(widget.bookNodes[index]),
    );
  }
}
