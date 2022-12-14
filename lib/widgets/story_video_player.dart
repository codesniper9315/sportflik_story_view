import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:focus_detector/focus_detector.dart';
import 'package:sportflik_story_view/controller/story_controller.dart';
import 'package:video_player/video_player.dart';

class StoryVideoPlayer extends StatefulWidget {
  const StoryVideoPlayer({
    Key? key,
    required this.width,
    required this.height,
    this.url,
    this.thumbnailUrl,
    this.file,
    this.expandView = false,
    required this.storyController,
  })  : assert(url != null || file != null),
        super(key: key);

  final double width;
  final double height;
  final String? url;
  final String? thumbnailUrl;
  final File? file;
  final bool expandView;
  final StoryController storyController;

  @override
  // ignore: library_private_types_in_public_api
  _StoryVideoPlayerState createState() => _StoryVideoPlayerState();
}

class _StoryVideoPlayerState extends State<StoryVideoPlayer> {
  late StreamSubscription _streamSubscription;

  VideoPlayerController? _offlineController;
  VideoPlayerController? _onlineController;

  Duration? _progress;

  bool _isDisposing = false;
  bool _focusLost = false;

  bool get getIsInitializedOnlinePlayer =>
      _onlineController != null && _onlineController!.value.isInitialized;

  bool get getShouldPauseOnlineVideo =>
      !_isDisposing &&
      _onlineController != null &&
      _onlineController!.value.isInitialized;

  bool get getShouldPlayOnlineVideo =>
      _focusLost &&
      _onlineController != null &&
      _onlineController!.value.isInitialized;

  bool get getIsInitializedOfflinePlayer =>
      _offlineController != null && _offlineController!.value.isInitialized;

  bool get getShouldPauseOfflineVideo =>
      !_isDisposing &&
      _offlineController != null &&
      _offlineController!.value.isInitialized;

  bool get getShouldPlayOfflineVideo =>
      _focusLost &&
      _offlineController != null &&
      _offlineController!.value.isInitialized;

  bool get getShouldDisposeOfflineVideo =>
      _progress == null ||
      (_progress!.compareTo(_onlineController!.value.position) < 0 &&
          _offlineController != null);

  bool get getIsBufferingVideo =>
      _offlineController == null &&
      _onlineController != null &&
      _onlineController!.value.isInitialized &&
      _onlineController!.value.isBuffering;

  VideoPlayerController get getController =>
      _offlineController != null ? _offlineController! : _onlineController!;

  bool get getIsAspectRatioGreaterThanOne =>
      getController.value.aspectRatio > 1;

  @override
  void initState() {
    super.initState();

    if (widget.file != null) {
      initOfflinePlayer(widget.file!);
    }
    if (widget.url != null) {
      initOnlinePlayer(widget.url!);
    }

    _streamSubscription =
        widget.storyController.playbackNotifier.listen((value) {
      if (value == PlaybackState.pause) {
        if (getIsInitializedOfflinePlayer) {
          _offlineController!.pause();
        } else if (getIsInitializedOnlinePlayer) {
          _onlineController!.pause();
        }
      } else if (value == PlaybackState.play) {
        if (getIsInitializedOfflinePlayer) {
          _offlineController!.play();
        } else if (getIsInitializedOnlinePlayer) {
          _onlineController!.play();
        }
      }
    });
  }

  onProgressOfflineVideo() {
    _progress = _offlineController!.value.position;
  }

  onProgressOnlineVideo() {
    if (getShouldDisposeOfflineVideo) {
      disposeOfflineController();
    }
    setState(() {});
  }

  initOfflinePlayer(File file) {
    VideoPlayerOptions options = VideoPlayerOptions(mixWithOthers: true);
    _offlineController = VideoPlayerController.file(
      file,
      videoPlayerOptions: options,
    );

    _offlineController!.initialize().then((value) {
      if (!mounted) {
        _offlineController!.dispose();
        return;
      }

      _offlineController!.addListener(onProgressOfflineVideo);

      _offlineController!.play();

      widget.storyController.play();
    });
  }

  disposeOfflineController() {
    setState(() {
      // dispose the offline controller
      if (_offlineController != null) {
        _offlineController!.removeListener(onProgressOfflineVideo);
        _offlineController!.dispose();
        _offlineController = null;
      }
    });
  }

  initOnlinePlayer(String url) {
    var a = Uri.parse(url);
    VideoFormat? videoFormat;
    if (a.pathSegments.last.endsWith('m3u8')) {
      videoFormat = VideoFormat.hls;
    } else if (a.pathSegments.last.endsWith('mp4')) {
      videoFormat = VideoFormat.other;
    } else if (a.pathSegments.last.endsWith('mkv')) {
      videoFormat = VideoFormat.dash;
    }
    VideoPlayerOptions options = VideoPlayerOptions(mixWithOthers: true);
    _onlineController = VideoPlayerController.network(
      url,
      formatHint: videoFormat,
      videoPlayerOptions: options,
    );

    if (!mounted) {
      _onlineController!.dispose();
      return;
    }

    _onlineController!.addListener(onProgressOnlineVideo);

    _onlineController!.play();

    if (_progress != null) {
      widget.storyController.pause();

      _onlineController!
          .seekTo(_progress!)
          .then((value) => widget.storyController.play());
    }
  }

  onFocusLost() {
    _focusLost = true;

    // pause the online video when focus lost
    if (getShouldPauseOnlineVideo) {
      _onlineController!.pause();
      if (mounted) {
        setState(() {});
      }
    }

    // pause the offline video when focus lost
    if (getShouldPauseOfflineVideo) {
      _offlineController!.pause();
      if (mounted) {
        setState(() {});
      }
    }

    widget.storyController.pause();
  }

  onFocusGained() {
    Future.delayed(const Duration(milliseconds: 200), () {
      // resume the online video when focus gained
      if (getShouldPlayOnlineVideo) {
        _onlineController!.play();
      }
      // resume the offline video when focus gained
      if (getShouldPlayOfflineVideo) {
        _offlineController!.play();
      }
      if (mounted) {
        setState(() {
          _focusLost = false;
        });
      }

      widget.storyController.play();
    });
  }

  @override
  void dispose() {
    _isDisposing = true;

    if (_offlineController != null) {
      _offlineController!.dispose();
    }
    if (_onlineController != null) {
      _onlineController!.removeListener(onProgressOnlineVideo);
      _onlineController!.dispose();
    }

    _streamSubscription.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (getIsInitializedOfflinePlayer || getIsInitializedOnlinePlayer) {
      return FocusDetector(
        onFocusLost: onFocusLost,
        onFocusGained: onFocusGained,
        child: _videoPlayerBuilder(),
      );
    } else {
      return Container(
        width: widget.width,
        height: widget.height,
        color: Colors.black,
        child: Stack(
          children: [
            if (widget.thumbnailUrl != null) ...[
              CachedNetworkImage(
                imageUrl: widget.thumbnailUrl!,
                width: widget.width,
                height: widget.height,
                fit: BoxFit.fitWidth,
              )
            ],
          ],
        ),
      );
    }
  }

  Widget _videoPlayerBuilder() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.black,
      child: Stack(
        children: [
          if (_onlineController != null) ...[
            _videoPlayer(_onlineController!),
          ],
          if (_offlineController != null) ...[
            _videoPlayer(_offlineController!),
          ],
          if (getIsBufferingVideo) ...[
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          ]
        ],
      ),
    );
  }

  Widget _videoPlayer(VideoPlayerController controller) {
    if (controller.value.aspectRatio > 1) {
      return Center(
        child: AspectRatio(
          aspectRatio: getController.value.aspectRatio,
          child: VideoPlayer(getController),
        ),
      );
    } else {
      return Center(
        child: SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: getController.value.size.width,
              height: getController.value.size.height,
              child: VideoPlayer(getController),
            ),
          ),
        ),
      );
    }
  }
}
