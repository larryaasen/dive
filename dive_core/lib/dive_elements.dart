import 'package:dive_core/dive_media_source.dart';
import 'package:dive_core/dive_sources.dart';
import 'package:dive_core/dive_output.dart';

class DiveCoreElements {
  final List<DiveAudioSource> audioSources = [];
  final List<DiveImageSource> imageSources = [];
  final List<DiveMediaSource> mediaSources = [];
  final List<DiveVideoSource> videoSources = [];
  final List<DiveVideoMix> videoMixes = [];
  final streamingOutput = DiveOutput();
  DiveScene currentScene;
}
