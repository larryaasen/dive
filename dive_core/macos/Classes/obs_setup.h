//
//  obs_setup.h
//
//  Created by Larry Aasen on 11/23/20.
//

#pragma once

#import <OpenGL/OpenGL.h>

#ifdef __cplusplus
extern "C" {
#endif

@class TextureSource;
void addFrameCapture(TextureSource *textureSource);
void removeFrameCapture(TextureSource *textureSource);

bool create_obs(void);

bool bridge_create_source(NSString *uuid, NSString *device_name, NSString *device_uid, bool frame_source);
bool bridge_release_source(NSString *uuid);

NSArray *bridge_input_types();
NSArray *bridge_video_inputs();

#ifdef __cplusplus
}
#endif
