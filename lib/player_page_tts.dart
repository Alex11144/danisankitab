import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:danisankitab/booknode.dart';
import 'package:danisankitab/player_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' as cupertino;
import 'package:just_audio/just_audio.dart';

class PlayerPageTts extends StatefulWidget {
  final BookNode bookNode;
  PlayerPageTts(this.bookNode);

  @override
  _PlayerPageTtsState createState() => _PlayerPageTtsState();
}

class _PlayerPageTtsState extends State<PlayerPageTts> with WidgetsBindingObserver {

  AudioPlayer _player;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      if (_player != null) {
        _player.pause();
      }
    } else if (state == AppLifecycleState.resumed) {
      if (!_player.playing)_player.play();
    }
  }

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _player.load(ConcatenatingAudioSource(
      children: [
        AudioSource.uri(Uri.parse('asset:///assets/playerinfo.mp3')),
        AudioSource.uri(Uri.parse('https://danisankitab.az/persistent/' + widget.bookNode.mp3Uri))
      ]
    ));
    _player.play();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _player.stop();
    _player.dispose();
    super.dispose();
  }

  Future<void> _seekRelative(Duration offset) async {
    var newPosition = _player.position + offset;
    // Make sure we don't jump out of bounds.
    if (newPosition < Duration.zero) newPosition = Duration.zero;
    //if (newPosition > mediaItem.duration) newPosition = mediaItem.duration;
    // Perform the jump via a seek.
    await _player.seek(newPosition);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (_player.playing) {
            _player.pause();
          } else {
            _player.play();
          }
          setState(() {

          });
        },
        onHorizontalDragEnd: (d) {
          if (d.primaryVelocity > 0) {
            _seekRelative(Duration(seconds: 5));
          } else {
            _seekRelative(Duration(seconds: -5));
          }
        },
        onVerticalDragEnd: (d) {
          if (d.primaryVelocity > 10) {
            Navigator.of(context).pop();
          }
        },
        child: IgnorePointer(
          ignoring: true,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(image: DecorationImage(fit: BoxFit.cover, image: CachedNetworkImageProvider("https://danisankitab.az/persistent/"+widget.bookNode.artUri))),
                child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 100.0, sigmaY: 100.0),
                    child: Container(color: Colors.white.withOpacity(0.01))
                ),
              ),

              Material(color: Colors.transparent, child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      AnimatedPadding(padding: EdgeInsets.all(_player.playing ? 30: 50), duration: Duration(milliseconds: 200), child: Material(
                          elevation: 5,
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          clipBehavior: Clip.antiAlias,
                          child: AspectRatio(
                            aspectRatio: 1.0,
                            child: Container(
                              decoration: BoxDecoration(
                                  image: DecorationImage(
                                      fit: BoxFit.cover,
                                      image: CachedNetworkImageProvider("https://danisankitab.az/persistent/"+widget.bookNode.artUri)
                                  )
                              ),
                            ),
                          )
                      ),),



                      // Container(height: 50,),
                      Text(widget.bookNode.title, style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold), textAlign: TextAlign.center,),
                      Text(widget.bookNode.subtitle, style: TextStyle(color: Colors.white), textAlign: TextAlign.center,),


                      // sldr,

                      StreamBuilder<Duration>(
                        stream: _player.positionStream,
                        builder: (BuildContext context, AsyncSnapshot<Duration> snapshot) {
                          Duration d = snapshot.data ?? Duration.zero;
                          return Column(
                            children: [
                              Slider(value: d.inSeconds.toDouble(), max: widget.bookNode.duration.inSeconds.toDouble(), activeColor: Colors.white, inactiveColor: Colors.white54,onChanged: (double value) {},),

                              Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 25),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Text(myFormatDuration(d), style: TextStyle(color: Colors.white)),
                                      Text(myFormatDuration(widget.bookNode.duration), style: TextStyle(color: Colors.white))
                                    ],
                                  )
                              ),
                            ],
                          ); //
                        },
                      ),

                      Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(icon: Icon(cupertino.CupertinoIcons.backward_fill), color: Colors.white, iconSize: 50, onPressed: (){},),
                          IconButton(icon: Icon(_player.playing ? cupertino.CupertinoIcons.pause_fill : cupertino.CupertinoIcons.play_fill), color: Colors.white, iconSize: 50, onPressed: (){},),
                          IconButton(icon: Icon(cupertino.CupertinoIcons.forward_fill), color: Colors.white, iconSize: 50, onPressed: (){},)
                        ],
                      )
                    ],
                  )
              ))
            ],
          ),
        )
      ),
    );
  }
}
