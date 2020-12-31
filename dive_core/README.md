# dive_core

## Building the obslib Framework

1: Starting by building OBS from source code. Here are the recommended build instructions: https://obsproject.com/wiki/Install-Instructions#macos-build-directions

    
    cd ~/obs-studio
    ./CI/full-build-macos.sh

Sometimes, the build will fail. Usually, it succeeds on the second attempt.


2: Next, build the macOS Framework.
- open obslib-framework.xcodeproj
- build


## OBS

input (camera) -> source -> scene -> channel -> final texture -> rtmp service -> -> encoder -> rtmp output
input (camera) -> source -> scene -> channel -> final texture -> rtmp service -> -> encoder -> rtmp output

source:
<- input (camera)
<- input (video file)

scene:
- [channels]

channel:
- source

source:
- input
- output stream

input:
- camera
- video file
- static image
- scene

YAML Config File:
- max_channels: 64

## OBS Video Format
MacBook Pro Camera: OBS video_format VIDEO_FORMAT_UYVY