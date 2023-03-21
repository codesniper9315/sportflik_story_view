import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sportflik_story_view/widgets/story_video_player.dart';

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
  @override
  Widget build(BuildContext context) {
    return StoryVideoPlayer(
      height: double.infinity,
      width: double.infinity,
      storyController: widget.storyController!,
      url: widget.url,
      file: widget.file,
      thumbnailUrl: widget.thumbnail,
    );
  }
}
