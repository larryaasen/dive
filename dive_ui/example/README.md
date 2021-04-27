# Dive UI Example

Demonstrates how to use the dive_ui plugin.

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
