//
//  dive_obs_bridge.h
//
//  Created by Larry Aasen on 11/23/20.
//

#pragma once

#ifdef __cplusplus
extern "C" {
#endif

NS_ASSUME_NONNULL_BEGIN

@class TextureSource;
void addFrameCapture(TextureSource *textureSource);
void removeFrameCapture(TextureSource *textureSource);

bool bridge_obs_startup(void);

bool load_obs(void);

#pragma mark - Bridge functions

bool    bridge_source_add_frame_callback(const char *source_uuid, int64_t source_ptr);
bool    bridge_create_source(const char *source_uuid, const char *source_id, const char *name, bool frame_source);
int64_t bridge_create_scene(NSString *tracking_uuid, NSString *scene_name);
bool    bridge_release_scene(NSString *scene_uuid);
bool    bridge_release_source(NSString *source_uuid);
bool    bridge_create_media_source(NSString *sourc_uuid, NSString *local_file);
bool    bridge_create_video_source(NSString *source_uuid, NSString *device_name, NSString *device_uid);
bool    bridge_create_image_source(NSString *source_uuid, NSString *file);
int64_t bridge_add_source(NSString *scene_uuid, NSString *source_uuid);
NSDictionary *bridge_sceneitem_get_info(int64_t scene_pointer, int64_t item_id);
bool bridge_sceneitem_set_info(int64_t scene_pointer, int64_t item_id, NSDictionary *info);

bool    bridge_add_videomix(const char *tracking_uuid);
bool    bridge_remove_videomix(const char *tracking_uuid);

#pragma mark - Stream Controls

bool bridge_stream_output_start();
bool bridge_stream_output_stop();
int bridge_output_get_state();

#pragma mark - Media Controls

bool bridge_media_source_play_pause(NSString *source_uuid, bool pause);
bool bridge_media_source_restart(NSString *source_uuid);
bool bridge_media_source_stop(NSString *source_uuid);
int64_t bridge_media_source_get_duration(NSString *source_uuid);
int64_t bridge_media_source_get_time(NSString *source_uuid);
bool bridge_media_source_set_time(NSString *source_uuid, int64_t ms);
int bridge_media_source_get_state(NSString *source_uuid);

#pragma mark - Volume Level

int64_t bridge_volmeter_add_callback(int64_t volmeter_pointer);

#pragma mark - Inputs

NSArray *bridge_input_types();
NSArray *bridge_inputs_from_type(const char *input_type_id);
NSArray *bridge_audio_inputs();
NSArray *bridge_video_inputs();

NS_ASSUME_NONNULL_END

#ifdef __cplusplus
}
#endif
