import 'package:rxdart/rxdart.dart';

enum PlaybackState { pause, play, next, previous, pauseOnlyCtrl, playOnlyCtrl }

/// Controller to sync playback between animated child (story) views. This
/// helps make sure when stories are paused, the animation (gifs/slides) are
/// also paused.
/// Another reason for using the controller is to place the stories on `paused`
/// state when a media is loading.
class StoryController {
  /// Stream that broadcasts the playback state of the stories.
  final playbackNotifier = BehaviorSubject<PlaybackState>();

  /// Notify listeners with a [PlaybackState.pause] state
  void pause([bool onlyCtrl = false]) {
    playbackNotifier
        .add(onlyCtrl ? PlaybackState.pauseOnlyCtrl : PlaybackState.pause);
  }

  /// Notify listeners with a [PlaybackState.play] state
  void play([bool onlyCtrl = false]) {
    playbackNotifier
        .add(onlyCtrl ? PlaybackState.playOnlyCtrl : PlaybackState.play);
  }

  void next() {
    playbackNotifier.add(PlaybackState.next);
  }

  void previous() {
    playbackNotifier.add(PlaybackState.previous);
  }

  /// Remember to call dispose when the story screen is disposed to close
  /// the notifier stream.
  void dispose() {
    playbackNotifier.close();
  }
}
