//
//  obs_setup.h
//
//  Created by Larry Aasen on 11/23/20.
//

#pragma once

#ifdef __cplusplus
extern "C" {
#endif

@class TextureSource;
void addFrameCapture(TextureSource *textureSource);
void removeFrameCapture(TextureSource *textureSource);

bool create_obs(void);

#pragma mark - Bridge functions

bool bridge_release_source(NSString *source_uuid);
bool bridge_create_media_source(NSString *sourc_uuid, NSString *local_file);
bool bridge_create_video_source(NSString *source_uuid, NSString *device_name, NSString *device_uid);

#pragma mark - Media Controls

bool bridge_media_source_play_pause(NSString *source_uuid, bool pause);
bool bridge_media_source_stop(NSString *source_uuid);

#pragma mark - Inputs

NSArray *bridge_input_types();
NSArray *bridge_video_inputs();

#ifdef __cplusplus
}
#endif
