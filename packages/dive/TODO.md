# TODO

1. TBD

## Goal
1. Enable Flutter developers to use a framework for video recording and streaming

## Requirements
1. Must be fast!
1. Must be able to process 4K image streams at 60 FPS.


## Benchmarks
1. Create a frame with a red background in under 1 ms.

### Benchmarks from Image package in Dart
```
flutter: 2022/1/21 16:45:16.381 createBaseImage elapsed: 3ms
flutter: 2022/1/21 16:45:16.550 copyResize1 elapsed: 168ms
flutter: 2022/1/21 16:45:16.552 copyInto1 elapsed: 2ms
flutter: 2022/1/21 16:45:16.694 copyResize2 elapsed: 141ms
flutter: 2022/1/21 16:45:16.697 copyInto2 elapsed: 2ms
flutter: 2022/1/21 16:45:16.698 drawString elapsed: 0ms
flutter: 2022/1/21 16:49:18.791 encodePng elapsed: 193ms
```

### FPS for text generator stream using Image package
The best I can achieve:
```
flutter: 2022/1/21 18:24:27.458 createBaseImage elapsed: 3ms
flutter: 2022/1/21 18:24:27.459 drawString elapsed: 1ms
flutter: 2022/1/21 18:24:27.553 encodePng elapsed: 93ms
```

The best FPS with just text streams and no images: 920-960 FPS

Do I need to use a Texture widget for increased performance, or can
the Image widget handle 30 FPS?
* Based on an experiment it seems like it can handle 1280/720 frames at 31 FPS.

### FPS Using Flutter's dart:ui Image and Canvas
I can make a frame with two images and a timer text in about 54ms in Run, and 60 in debug.
Could get that lower with some easy optimization.
- it takes about 11ms to call: picture.toImage()

## Layers

FFI layer for an engine:
-creates image and returns handle (address), performs operations on the handle,
-sources create frames in Dart or FFI
-to render a scene, a compositing engine needs the frames and data from all 
sources in the scene. It needs a scene, sources, and properties.
-the problem with large sized FFI or plugin frameworks is the duplication of all
code. The Dart layer and FFI layer each needs their own Scene class.

-A compositing engine processes items in the stream like this:
-source 0: resize source and draw source.
-source 1: resize source and draw source.
-source 2: resize source and draw source.
-maybe the FFI layer only knows basic operations and the Dart layer coordinates
the drawing sequence.

## Next steps
I need to do one of these two steps:
* Build a native FFI plugin to process all of the frames.
* Get the original obslib plugin to work.