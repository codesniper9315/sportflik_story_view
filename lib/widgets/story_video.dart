import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sportflik_story_view/widgets/stream_video_player.dart';
import 'package:video_player/video_player.dart';

import '../utils.dart';
import '../controller/story_controller.dart';

class StoryVideo extends StatefulWidget {
  final File? file;
  final String? url;
  final StoryController? storyController;
  final String? thumbnail;
  final double width;
  final double height;

  StoryVideo(
    this.width,
    this.height, {
    this.storyController,
    this.file,
    this.url,
    this.thumbnail,
    Key? key,
  }) : super(key: key ?? UniqueKey());

  @override
  State<StatefulWidget> createState() {
    return StoryVideoState();
  }
}

class StoryVideoState extends State<StoryVideo> {
  Future<void>? playerLoader;

  StreamSubscription? _streamSubscription;

  VideoPlayerController? playerController;

  @override
  void initState() {
    super.initState();

    if (widget.storyController != null) {
      widget.storyController!.pause();
    }
  }

  _initializeVideoPlayer() {
    playerController!.initialize().then((v) {
      setState(() {});
      widget.storyController!.play();
    });

    if (widget.storyController != null) {
      _streamSubscription =
          widget.storyController!.playbackNotifier.listen((playbackState) {
        if (playbackState == PlaybackState.pause) {
          playerController!.pause();
        } else {
          playerController!.play();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamVideoPlayer(
      height: double.infinity,
      width: double.infinity,
      storyController: widget.storyController!,
      url: widget.url,
      file: widget.file,
      thumbnailUrl: widget.thumbnail,
    );
  }

  @override
  void dispose() {
    playerController?.dispose();
    _streamSubscription?.cancel();
    super.dispose();
  }
}
