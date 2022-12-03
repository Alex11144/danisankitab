import 'dart:async';
import 'dart:ui';

import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:danisankitab/selector_page.dart';
import 'package:flutter/cupertino.dart' as cupertino;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

import 'booknode.dart';

class PlayerPage extends StatefulWidget {
  final BookNode bookNode;

  PlayerPage(this.bookNode);

  @override
  _PlayerPageState createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  double slidingI = -1.0;
  bool isPlaying = false;

  @override
  Widget build(BuildContext context) {
    return AudioServiceWidget(
        child: Scaffold(
            body: Stack(
      children: [
        Container(
          decoration: BoxDecoration(
              image: DecorationImage(
                  fit: BoxFit.cover,
                  image: CachedNetworkImageProvider(
                      "https://danisankitab.az/persistent/" +
                          widget.bookNode.artUri))),
          child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 100.0, sigmaY: 100.0),
              child: Container(color: Colors.white.withOpacity(0.01))),
        ),
        StreamBuilder<bool>(
          stream: AudioService.runningStream,
          builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
            if (snapshot.connectionState != ConnectionState.active) {
              return miniPlayer(0);
            }
            final running = snapshot.data ?? false;
            if (!running) {
              return miniPlayer(0);
            }

            return StreamBuilder<MediaItem>(
                stream: AudioService.currentMediaItemStream,
                builder:
                    (BuildContext context, AsyncSnapshot<MediaItem> snapshot) {
                  if (snapshot.connectionState != ConnectionState.active) {
                    return miniPlayer(0);
                  }
                  final bool isPlayingMe = (snapshot.data?.id ?? "") ==
                      "https://danisankitab.az/persistent/" +
                          widget.bookNode.mp3Uri;
                  if (!isPlayingMe) {
                    print("::::" + (snapshot.data?.id ?? ""));
                    return miniPlayer(1);
                  }

                  return miniPlayer(2);
                });
          },
        )
      ],
    )));
  }

  Widget miniPlayer(int serverState) {
    Widget plyBtn, sldr, plyBtn2;
    VoidCallback forwardCallback, rewindCallback;

    if (serverState == 0) {
      plyBtn = IconButton(
          icon: Icon(cupertino.CupertinoIcons.play_fill),
          iconSize: 50,
          color: Colors.white,
          onPressed: () {
            AudioService.start(
                backgroundTaskEntrypoint: _entrypoint,
                params: {
                  "id": "https://danisankitab.az/persistent/" +
                      widget.bookNode.mp3Uri,
                  "title": widget.bookNode.title,
                  "album": widget.bookNode.subtitle,
                  "art": "https://danisankitab.az/persistent/" +
                      widget.bookNode.artUri,
                  "duration": widget.bookNode.duration.inSeconds
                },
                androidNotificationIcon: "drawable/ic_notification");
          });
    } else if (serverState == 1) {
      plyBtn = IconButton(
        icon: Icon(cupertino.CupertinoIcons.play_fill),
        iconSize: 50,
        color: Colors.white,
        onPressed: () {
          AudioService.playMediaItem(MediaItem(
              id: "https://danisankitab.az/persistent/" +
                  widget.bookNode.mp3Uri,
              title: widget.bookNode.title,
              album: widget.bookNode.subtitle,
              artUri: "https://danisankitab.az/persistent/" +
                  widget.bookNode.artUri,
              duration: widget.bookNode.duration));
        },
      );
    } else if (serverState == 2) {
      plyBtn = StreamBuilder<PlaybackState>(
          stream: AudioService.playbackStateStream,
          builder:
              (BuildContext context, AsyncSnapshot<PlaybackState> snapshot) {
            bool playing = snapshot.data?.playing ?? false;
            return IconButton(
              icon: Icon(playing
                  ? cupertino.CupertinoIcons.pause_fill
                  : cupertino.CupertinoIcons.play_fill),
              iconSize: 50,
              color: Colors.white,
              onPressed: () {
                if (playing)
                  AudioService.pause();
                else
                  AudioService.play();
              },
            );
          });

      rewindCallback = () {
        AudioService.rewind();
      };

      forwardCallback = () {
        AudioService.fastForward();
      };
    }

    if (serverState == 0 || serverState == 1) {
      sldr = Column(
        children: [
          Slider(
            value: 0.0,
            onChanged: null,
            activeColor: Colors.white,
            inactiveColor: Colors.white54,
          ),
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 25),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Text(myFormatDuration(Duration.zero),
                      style: TextStyle(color: Colors.white)),
                  Text(myFormatDuration(widget.bookNode.duration),
                      style: TextStyle(color: Colors.white))
                ],
              )),
        ],
      );
    } else if (serverState == 2) {
      sldr = StreamBuilder<Duration>(
        stream: AudioService.positionStream,
        builder: (BuildContext context, AsyncSnapshot<Duration> snapshot) {
          Duration d = snapshot.data ?? Duration.zero;

          return Column(
            children: [
              Slider(
                value: slidingI < 0 ? d.inSeconds.toDouble() : slidingI,
                max: widget.bookNode.duration.inSeconds.toDouble(),
                activeColor: Colors.white,
                inactiveColor: Colors.white54,
                onChanged: (v) {
                  setState(() {
                    slidingI = v;
                  });
                },
                onChangeEnd: (v) {
                  AudioService.seekTo(Duration(seconds: v.toInt()));
                  setState(() {
                    slidingI = -1.0;
                  });
                },
              ),
              Padding(
                  padding: EdgeInsets.symmetric(horizontal: 25),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Text(
                          myFormatDuration(slidingI < 0.0
                              ? d
                              : Duration(seconds: slidingI.ceil())),
                          style: TextStyle(color: Colors.white)),
                      Text(myFormatDuration(widget.bookNode.duration),
                          style: TextStyle(color: Colors.white))
                    ],
                  )),
            ],
          );

          return Slider(
            value: slidingI < 0 ? d.inSeconds.toDouble() : slidingI,
            max: widget.bookNode.duration.inSeconds.toDouble(),
            onChanged: (v) {
              setState(() {
                slidingI = v;
              });
            },
            onChangeEnd: (v) {
              AudioService.seekTo(Duration(seconds: v.toInt()));
              setState(() {
                slidingI = -1.0;
              });
            },
          );
        },
      );
    }

    return Material(
        color: Colors.transparent,
        child: Center(
            child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StreamBuilder<PlaybackState>(
                stream: AudioService.playbackStateStream,
                builder: (BuildContext context,
                    AsyncSnapshot<PlaybackState> snapshot) {
                  bool playing =
                      (snapshot.data?.playing ?? false) && (serverState == 2);
                  return AnimatedPadding(
                    padding: EdgeInsets.all(playing ? 30 : 50),
                    duration: Duration(milliseconds: 200),
                    child: Material(
                        elevation: 5,
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                        clipBehavior: Clip.antiAlias,
                        child: AspectRatio(
                          aspectRatio: 1.0,
                          child: Container(
                            decoration: BoxDecoration(
                                image: DecorationImage(
                                    fit: BoxFit.cover,
                                    image: CachedNetworkImageProvider(
                                        "https://danisankitab.az/persistent/" +
                                            widget.bookNode.artUri))),
                          ),
                        )),
                  );
                }),

            // Container(height: 50,),
            Text(
              widget.bookNode.title,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            Text(
              widget.bookNode.subtitle,
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),

            sldr,

            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(cupertino.CupertinoIcons.backward_fill),
                  color: Colors.white,
                  iconSize: 50,
                  onPressed: rewindCallback,
                ),
                plyBtn,
                IconButton(
                  icon: Icon(cupertino.CupertinoIcons.forward_fill),
                  color: Colors.white,
                  iconSize: 50,
                  onPressed: forwardCallback,
                )
              ],
            )
          ],
        )));
  }
}

String myFormatDuration(Duration duration) {
  var ss = duration.inSeconds.remainder(60);
  var mm = duration.inMinutes.remainder(60);
  var hh = duration.inHours;
  var r = ss.toString().padLeft(2, "0");
  if (hh > 0) {
    return hh.toString() +
        ":" +
        mm.toString().padLeft(2, "0") +
        ":" +
        ss.toString().padLeft(2, "0");
  }

  return mm.toString() + ":" + ss.toString().padLeft(2, "0");
}

void _entrypoint() => AudioServiceBackground.run(() => AudioPlayerTask());

class AudioPlayerTask extends BackgroundAudioTask {
  var _player = AudioPlayer(); // e.g. just_audio

// Implement callbacks here. e.g. onStart, onStop, onPlay, onPause

  @override
  Future<void> onStart(Map<String, dynamic> params) async {
    final mediaItem = MediaItem(
        id: params["id"],
        album: params["album"],
        title: params["title"],
        artUri: params["art"],
        duration: Duration(seconds: params["duration"]));
    // Tell the UI and media notification what we're playing.
    AudioServiceBackground.setMediaItem(mediaItem);
    // Listen to state changes on the player...
    _player.playbackEventStream.listen((playerState) {
      // ... and forward them to all audio_service clients.
      AudioServiceBackground.setState(
        playing: _player.playing,
        // Every state from the audio player gets mapped onto an audio_service state.
        processingState: {
          ProcessingState.none: AudioProcessingState.none,
          ProcessingState.loading: AudioProcessingState.connecting,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[playerState.processingState],
        // Tell clients what buttons/controls should be enabled in the
        // current state.
        controls: [
          _player.playing ? MediaControl.pause : MediaControl.play,
          MediaControl.stop,
        ],
        systemActions: [MediaAction.seekTo],
        position: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
      );
    });
    // Play when ready.
    _player.play();
    // Start loading something (will play when ready).
    await _player.setUrl(mediaItem.id);
  }

  @override
  Future<void> onPlayMediaItem(MediaItem mediaItem) async {
    _player.setUrl(mediaItem.id);
    _player.play();
    AudioServiceBackground.setMediaItem(mediaItem);
    AudioServiceBackground.setState(
        position: Duration.zero,
        controls: [],
        playing: null,
        processingState: null);
  }

  @override
  Future<void> onPlay() {
    _player.play();
  }

  @override
  Future<void> onPause() {
    _player.pause();
  }

  @override
  Future<void> onSeekTo(Duration position) {
    _player.seek(position);
  }

  @override
  Future<void> onFastForward() => _seekRelative(Duration(seconds: 10));

  @override
  Future<void> onRewind() => _seekRelative(Duration(seconds: -10));

  /// Jumps away from the current position by [offset].
  Future<void> _seekRelative(Duration offset) async {
    var newPosition = _player.position + offset;
    // Make sure we don't jump out of bounds.
    if (newPosition < Duration.zero) newPosition = Duration.zero;
    //if (newPosition > mediaItem.duration) newPosition = mediaItem.duration;
    // Perform the jump via a seek.
    await _player.seek(newPosition);
  }
}
