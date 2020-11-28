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
bool create_obs(void);
void addFrameCapture(TextureSource *textureSource);
void removeFrameCapture(TextureSource *textureSource);

#ifdef __cplusplus
}
#endif
