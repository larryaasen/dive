# Dive UI Example

Demonstrates how to use the dive_ui plugin.

## Example 1 - Media Player

This example shows how to use dive_ui, dive_core, and dive_obslib to build a
media player. This media player demonstrates these features using 129 lines of code:
* Display a file selector button `DiveVideoPickerButton` that opens the file selector dialog.
* Display a file selector dialog to select a media/video file.
* Use `DiveCoreElements` to track the scene, video mix (`DiveVideoMix`), audio source, and media source.
* Create a scene (`DiveScene`) and display the video mix using the `DiveMeterPreview` widget playing the video.
* Display audio meters in both horizontal and vertical orientations.
* Display media player control bar `DiveMediaButtonBar` with play/pause buttom, stop buttons, and elapsed
time.
* Usage: flutter run lib/main_example1.dart -d macos

![image](example1-media-player.png)

## Writing an app with Dive UI

1. Add dive_ui to your pubspec.yaml file.
1. In the macos/Podfile, in the target 'Runner' section, add: ```pod 'obslib', :path => '/Users/larry/Projects/obslib-framework'```
1. Open Xcode and load the Runner.xcworkspace file.
1. Select the Runner target, under the General tab. Change the Deployment Target to 10.13.
1. In section Signing & Capabilities, in the App Sandbox, check both Network boxes, 
Camera, Audio Input, USB, and in File Access set all to Read/Write.
1. In the Info section, add the Privacy keys for Desktop Folder, Camera, Microphone, Documents Folder,
and Downloads Folder.
1. In the Build Phases section, add a New Run Script Phase. Add this to the Shell:
```
# Copy the framework resources to a specific folder in the app Resources
cp -R ${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}/obslib.framework/Resources/data ${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}
rsync ${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}/obslib.framework/PlugIns/* ${TARGET_BUILD_DIR}/${PLUGINS_FOLDER_PATH}
```
1. From command line: flutter run -d macos

## TODO - Examples to be created

1. Example showing how to display an image.
1. Example showing how to display a video camera.
1. Example showing how to stream a video mix.
1. Example showing how to scrub a video forward and backward.
1. Example showing 720p and 1080p videos.
1. Example showing how to position an image in the mix.