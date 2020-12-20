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

bool    bridge_create_scene(NSString *tracking_uuid, NSString *scene_name);
bool    bridge_release_scene(NSString *scene_uuid);
bool    bridge_release_source(NSString *source_uuid);
bool    bridge_create_media_source(NSString *sourc_uuid, NSString *local_file);
bool    bridge_create_video_source(NSString *source_uuid, NSString *device_name, NSString *device_uid);
bool    bridge_create_image_source(NSString *source_uuid, NSString *file);
int64_t bridge_add_source(NSString *scene_uuid, NSString *source_uuid);
NSDictionary *bridge_sceneitem_get_info(NSString *scene_uuid, int64_t item_id);
bool bridge_sceneitem_set_info(NSString *scene_uuid, int64_t item_id, NSDictionary *info);

bool    bridge_add_videomix(NSString *tracking_uuid);
bool    bridge_remove_videomix(NSString *tracking_uuid);

#pragma mark - Media Controls

bool bridge_media_source_play_pause(NSString *source_uuid, bool pause);
bool bridge_media_source_stop(NSString *source_uuid);

#pragma mark - Inputs

NSArray *bridge_input_types();
NSArray *bridge_video_inputs();

#ifdef __cplusplus
}
#endif
