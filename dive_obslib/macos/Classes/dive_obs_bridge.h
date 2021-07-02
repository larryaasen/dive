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

#pragma mark - Bridge functions

bool    bridge_source_add_frame_callback(const char *source_uuid, int64_t source_ptr);
bool    bridge_create_source(const char *source_uuid, const char *source_id, const char *name, bool frame_source);
bool    bridge_release_source(NSString *source_uuid);
bool    bridge_create_media_source(NSString *sourc_uuid, NSString *local_file);
bool    bridge_create_video_source(NSString *source_uuid, NSString *device_name, NSString *device_uid);
bool    bridge_create_image_source(NSString *source_uuid, NSString *file);
int64_t bridge_add_source(NSString *scene_uuid, NSString *source_uuid);
NSDictionary *bridge_sceneitem_get_info(int64_t sceneitem_pointer);
bool bridge_sceneitem_set_info(int64_t sceneitem_pointer, NSDictionary *info);

bool    bridge_add_videomix(const char *tracking_uuid);
bool    bridge_remove_videomix(const char *tracking_uuid);
bool    bridge_change_video_framerate(int32_t numerator, int32_t denominator);
bool    bridge_change_video_resolution(int32_t base_width, int32_t base_height, int32_t output_width, int32_t output_height);

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
