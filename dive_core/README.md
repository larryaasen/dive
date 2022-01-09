# dive_core

## Components

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
