# Dive UI Example

Demonstrates how to use the dive_ui plugin.

## Writing an app with Dive UI

1. Add dive_ui to your pubspec.yaml file.
1. In the macos/Podfile, in the target 'Runner' section, add: ```pod 'obslib', :path => '/Users/larry/Projects/obslib-framework'```
1. Open Xcode and load the Runner.xcworkspace file.
1. Select the Runner target, under the General tab. Change the Deployment Target to 10.13.
1. From command line: flutter run -d macos
