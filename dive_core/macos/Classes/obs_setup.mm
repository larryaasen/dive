#include <stdio.h>
#include <string.h>
#include <time.h>
#include <functional>
#include <map>
#include <memory>

#include "obslib/obs.h"
#include "obslib/obs.hpp"
#include "obslib/obs-service.h"
#include "obslib/obs-output.h"
#include "obslib/obs-properties.h"

#include "obs_setup.h"
#include "TextureSource.h"

template<typename T, typename D_T, D_T D>
struct OBSUniqueHandle : std::unique_ptr<T, std::function<D_T>> {
    using base = std::unique_ptr<T, std::function<D_T>>;
    explicit OBSUniqueHandle(T *obj = nullptr) : base(obj, D) {}
    operator T *() { return base::get(); }
};

#define DECLARE_DELETER(x) decltype(x), x

using SourceContext =
    OBSUniqueHandle<obs_source, DECLARE_DELETER(obs_source_release)>;

using SceneContext =
    OBSUniqueHandle<obs_scene, DECLARE_DELETER(obs_scene_release)>;

using DisplayContext =
    OBSUniqueHandle<obs_display, DECLARE_DELETER(obs_display_destroy)>;

#undef DECLARE_DELETER

struct key_cmp_str
{
   bool operator()(char const *a, char const *b) const
   {
      return std::strcmp(a, b) < 0;
   }
};

// obs is not designed for hot reload, so only start it once
bool obs_started = false;

//DisplayContext display;
static SceneContext scene1;

// Map of all created sources where the key is a source UUID and the value is a source pointer
static std::map<const char *, obs_source_t *> uuid_source_list;
static std::map<obs_source_t *, const char *> source_uuid_list;

static std::map<unsigned int, const char *> videomix_uuid_list;

// Map of all texture sources where the key is a source UUID and the value is a texture source pointer
static std::map<const char *, TextureSource *, key_cmp_str> _textureSourceMap;
// A duplicate map of all texture source that provides Objective-C reference counting
static NSMutableDictionary *_textureSources = [NSMutableDictionary new];

static bool reset_video();
static bool reset_audio();
static bool create_service();
static void videomix_callback(void *param, struct video_data *frame);
static void source_frame_callback(void *param, obs_source_t *source, struct obs_source_frame *frame);

extern "C" void addFrameCapture(TextureSource *textureSource) {
    if (textureSource == NULL) {
        printf("addFrameCapture: missing textureSource\n");
        return;
    }
    
    if (textureSource.trackingUUID == NULL || textureSource.trackingUUID.length == 0) {
        printf("addFrameCapture: missing sourceUUID\n");
        return;
    }

    const char *uuid_str = textureSource.trackingUUID.UTF8String;

    @synchronized (_textureSources) {
        TextureSource *source = _textureSources[textureSource.trackingUUID];
        if (source != NULL) {
            printf("addFrameCapture: duplicate texture source: %s\n", uuid_str);
            return;
        }
        [_textureSources setObject:textureSource forKey:textureSource.trackingUUID];
        _textureSourceMap[uuid_str] = textureSource;
    }

    printf("addFrameCapture: added texture source: %s\n", uuid_str);
}

extern "C" void removeFrameCapture(TextureSource *textureSource) {
    if (textureSource == NULL) {
        printf("removeFrameCapture: missing textureSource\n");
        return;
    }
    
    if (textureSource.trackingUUID == NULL || textureSource.trackingUUID.length == 0) {
        printf("removeFrameCapture: missing sourceUUID\n");
        return;
    }

    const char *uuid_str = textureSource.trackingUUID.UTF8String;

    @synchronized (_textureSources) {
        TextureSource *source = _textureSources[textureSource.trackingUUID];
        if (source == NULL) {
            printf("removeFrameCapture: unknown texture source: %s\n", uuid_str);
            return;
        }

        [_textureSources removeObjectForKey:textureSource.trackingUUID];
        _textureSourceMap.erase(uuid_str);
    }
}

SceneContext _add_scene() {
    const char *scene_name = "scene default";
    SceneContext scene{obs_scene_create(scene_name)};
    if (!scene) {
        printf("Couldn't create scene: %s\n", scene_name);
        return scene;
    }
    
    /* set the scene as the primary draw source and go */
    uint32_t channel = 0;
    obs_set_output_source(channel, obs_scene_get_source(scene));

    return scene;
}

static void save_source(NSString *source_uuid, obs_source_t *source) {
    const char *_uuid_str = source_uuid.UTF8String;
    const char *uuid_str = strdup(_uuid_str);
    uuid_source_list[uuid_str] = source;
    source_uuid_list[source] = uuid_str;
}

static void remove_source(const char *uuid_str) {
    obs_source_t *source = uuid_source_list[uuid_str];
    uuid_source_list.erase(uuid_str);
    source_uuid_list.erase(source);
    free((void *)source_uuid_list[source]);
}

static void add_videomix_callback(NSString *tracking_uuid) {
    const char *_tracking_uuid_str = tracking_uuid.UTF8String;
    const char *tracking_uuid_str = strdup(_tracking_uuid_str);
    
    unsigned int index = 0;
    videomix_uuid_list[index] = tracking_uuid_str;
    
    struct video_scale_info *conversion = NULL;
    void *param = (void *)tracking_uuid_str;
    obs_add_raw_video_callback(conversion, videomix_callback, param);
}

static void remove_videomix_callback(NSString *tracking_uuid) {
    unsigned int index=0;
    const char *tracking_uuid_str = videomix_uuid_list[index];
    void *param = (void *)tracking_uuid_str;
    obs_remove_raw_video_callback(videomix_callback, param);

    videomix_uuid_list.erase(index);
    free((void *)tracking_uuid_str);
}

extern "C" bool create_obs(void)
{
    if (obs_started) return true;

    if (!obs_startup("en", NULL, NULL)) {
        printf("Couldn't create OBS\n");
        return false; //throw "Couldn't create OBS";
    }
    
    obs_load_all_modules();
    obs_post_load_modules();

    if (!reset_video()) return false;
    if (!reset_audio()) return false;
    scene1 = _add_scene();
    if (!create_service()) return false;
//    add_video_callback();
    
    return true;
}

static const int cx = 1280;
static const int cy = 720;

static bool reset_video() {
    struct obs_video_info ovi;
    ovi.adapter = 0;
    ovi.fps_num = 30000;
    ovi.fps_den = 1001;
    ovi.graphics_module = "libobs-opengl"; //DL_OPENGL
    ovi.output_format = VIDEO_FORMAT_RGBA;
    ovi.base_width = cx;
    ovi.base_height = cy;
    ovi.output_width = cx;
    ovi.output_height = cy;
    ovi.colorspace = VIDEO_CS_DEFAULT;

    int rv = obs_reset_video(&ovi);
    if (rv != OBS_VIDEO_SUCCESS) {
        printf("Couldn't initialize video: %d\n", rv);
        return false; //throw "Couldn't initialize video";
    }
    return true;
}

static bool reset_audio() {
    struct obs_audio_info ai;
    ai.samples_per_sec = 48000;
    ai.speakers = SPEAKERS_STEREO;
    if (!obs_reset_audio(&ai)) {
        printf("Couldn't initialize audio\n");
        return false;
    }
    return true;
}

static bool create_service() {
    obs_data_t *serviceSettings = obs_data_create();
    const char *url = "rtmp://live-iad05.twitch.tv/app/live_276488556_jo79ChcHLboF2N1NniLSL9yEv7ltFt";
    const char *key = "live_276488556_jo79ChcHLboF2N1NniLSL9yEv7ltFt";
    obs_data_set_string(serviceSettings, "server", url);
    obs_data_set_string(serviceSettings, "key", key);

    const char *service_id = "rtmp_common";
    OBSService service_obj = obs_service_create(
        service_id, "default_service", serviceSettings, nullptr);
//    obs_service_release(service_obj);

    const char *type = "rtmp_output";
    OBSOutput streamOutput = obs_output_create(type, "adv_stream", nullptr, nullptr);
//    obs_output_release(streamOutput);

    OBSEncoder vencoder = obs_video_encoder_create("obs_x264", "test_x264",
                               nullptr, nullptr);
    OBSEncoder aencoder = obs_audio_encoder_create("ffmpeg_aac", "test_aac",
                               nullptr, 0, nullptr);
    obs_encoder_set_video(vencoder, obs_get_video());
    obs_encoder_set_audio(aencoder, obs_get_audio());
    obs_output_set_video_encoder(streamOutput, vencoder);
    obs_output_set_audio_encoder(streamOutput, aencoder, 0);
    
    obs_output_set_service(streamOutput, service_obj);
    
    obs_data_t *outputSettings = obs_data_create();
    obs_data_set_string(outputSettings, "bind_ip", "default");
    obs_data_set_bool(outputSettings, "new_socket_loop_enabled", false);
    obs_data_set_bool(outputSettings, "low_latency_mode_enabled", false);
    obs_data_set_bool(outputSettings, "dyn_bitrate", false);
    obs_output_update(streamOutput, outputSettings);
    
//    obs_output_start(streamOutput);

    return true;
}

static void copy_frame_to_texture(uint32_t width, uint32_t height, OSType pixelFormatType, uint32_t linesize, uint8_t *data, TextureSource *textureSource)
{
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferCreateWithBytes(kCFAllocatorDefault,
                                                   width,
                                                   height,
                                                   pixelFormatType,
                                                   data,
                                                   linesize,
                                                   NULL,
                                                   NULL,
                                                   NULL,
                                                   &pxbuffer);
    if (status != kCVReturnSuccess) {
        NSLog(@"copy_frame_to_source: Operation failed");
        return;
    }
    
    [textureSource captureSample: pxbuffer];
    CFRelease(pxbuffer);
}

static void copy_source_frame_to_texture(struct obs_source_frame *frame, TextureSource *textureSource)
{
    copy_frame_to_texture(frame->width, frame->height, kCMPixelFormat_422YpCbCr8, frame->linesize[0], frame->data[0], textureSource);
}

static void copy_videomix_frame_to_texture(struct video_data *frame, TextureSource *textureSource)
{
    struct obs_video_info ovi;
    obs_get_video_info(&ovi);

    // TODO: the frame has the red and blue swapped
    copy_frame_to_texture(ovi.output_width, ovi.output_height, kCMPixelFormat_32BGRA, frame->linesize[0], frame->data[0], textureSource);
}

static void source_frame_callback(void *param, obs_source_t *source, struct obs_source_frame *frame)
{
    const char *uuid_str = source_uuid_list[source];
    if (uuid_str == NULL) {
        printf("%s: unknown source %s\n", __func__, uuid_str);
        return;
    }

    printf("%s: %s\n", __func__, uuid_str);

    @synchronized (_textureSources) {
        TextureSource *textureSource = _textureSourceMap[uuid_str];
        if (textureSource != NULL) {
            copy_source_frame_to_texture(frame, textureSource);
        } else {
            printf("%s: no texture source for %s\n", __func__, uuid_str);
        }
    }
}

static void videomix_callback(void *param, struct video_data *frame) {
    printf("%s linesize[0] %d\n", __func__, frame->linesize[0]);

    unsigned int index = 0;
    const char *uuid_str = videomix_uuid_list[index];
    @synchronized (_textureSources) {
        TextureSource *textureSource = _textureSourceMap[uuid_str];
        if (textureSource != NULL) {
            copy_videomix_frame_to_texture(frame, textureSource);
        } else {
            printf("%s: no texture source for %s\n", __func__, uuid_str);
        }
    }
}


// TODO: error handling of input paramters, and make this work in the bridge

static bool first = true;

static bool _create_source(NSString *source_uuid, NSString *source_id, NSString *name, obs_data_t *settings, bool frame_source) {
    obs_source_t *source = obs_source_create(source_id.UTF8String, name.UTF8String, settings, nullptr);
    if (!source) {
        printf("%s: Could not create source\n", __func__);
        return false;
    }
    
    if (frame_source) {
        obs_source_add_frame_callback(source, source_frame_callback, nullptr);
    }

    save_source(source_uuid, source);
    obs_sceneitem_t *item = obs_scene_add(scene1, source);
    
    // TODO: add parameters for bound, position, rotation, scale, etc.
    if (!first) {
        vec2 size;
        vec2_set(&size, 1280/2, 720/2);
        obs_sceneitem_set_bounds(item, &size);
        obs_sceneitem_set_bounds_type(item, OBS_BOUNDS_SCALE_INNER);
    } else {
        vec2 size;
        vec2_set(&size, 680, 400);
        obs_sceneitem_set_bounds(item, &size);
        obs_sceneitem_set_bounds_type(item, OBS_BOUNDS_SCALE_INNER);
        
        vec2 pos;
        vec2_set(&pos, 600, 320);
        obs_sceneitem_set_pos(item, &pos);
    }

    first = false;
//    obs_sceneitem_set_pos(item, )
//    obs_sceneitem_set_scale(item, vec2())
    return true;
}

#pragma mark - Bridge functions

bool bridge_release_source(NSString *source_uuid) {
    const char *uuid_str = source_uuid.UTF8String;
    obs_source_t *source = uuid_source_list[uuid_str];
    if (!source) {
        printf("%s: unknown source %s\n", __func__, uuid_str);
        return false;
    }
    obs_source_release(source);
    remove_source(uuid_str);
    return true;
}

bool bridge_create_media_source(NSString *source_uuid, NSString *local_file) {
    // Load video file
    obs_data_t *settings = obs_data_create();
    obs_data_set_default_bool(settings, "is_local_file", true);
    obs_data_set_default_bool(settings, "looping", true);
    obs_data_set_default_bool(settings, "clear_on_media_end", false);
    obs_data_set_string(settings, "local_file", local_file.UTF8String);

    return _create_source(source_uuid, @"ffmpeg_source", @"video file", settings, true);
}

bool bridge_create_video_source(NSString *source_uuid, NSString *device_name, NSString *device_uid) {
    obs_data_t *settings = obs_data_create();
    obs_data_set_string(settings, "device_name", device_name.UTF8String);
    obs_data_set_string(settings, "device", device_uid.UTF8String);
    
    return _create_source(source_uuid, @"av_capture_input", @"camera", settings, true);
}

bool bridge_add_videomix(NSString *tracking_uuid) {
    add_videomix_callback(tracking_uuid);
    return true;
}

bool bridge_remove_videomix(NSString *tracking_uuid) {
    remove_videomix_callback(tracking_uuid);
    return true;
}

#pragma mark - Media Controls

/// Media control: play or pause
bool bridge_media_source_play_pause(NSString *source_uuid, bool pause) {
    const char *uuid_str = source_uuid.UTF8String;
    obs_source_t *source = uuid_source_list[uuid_str];
    if (!source) {
        printf("%s: unknown source %s\n", __func__, uuid_str);
        return false;
    }
    obs_source_media_play_pause(source, pause);
    return true;
}

/// Media control: play or pause
bool bridge_media_source_stop(NSString *source_uuid) {
    const char *uuid_str = source_uuid.UTF8String;
    obs_source_t *source = uuid_source_list[uuid_str];
    if (!source) {
        printf("%s: unknown source %s\n", __func__, uuid_str);
        return false;
    }
    obs_source_media_stop(source);
    return true;
}

#pragma mark - Inputs

NSArray *bridge_input_types() {
    const char *type_id;
    const char *unversioned_type_id;
    bool foundValues = false;
    bool foundDeprecated = false;
    size_t idx = 0;
    NSMutableArray *list = [NSMutableArray new];
    
    while (obs_enum_input_types2(idx++, &type_id, &unversioned_type_id)) {
        const char *name = obs_source_get_display_name(type_id);
        uint32_t caps = obs_get_source_output_flags(type_id);

        if ((caps & OBS_SOURCE_CAP_DISABLED) != 0)
            continue;

        bool deprecated = (caps & OBS_SOURCE_DEPRECATED) != 0;
        if (deprecated) {
//            addSource(popup, unversioned_type_id, name);
        } else {
//            addSource(deprecated, unversioned_type_id, name);
            foundDeprecated = true;
        }
        foundValues = true;
        NSDictionary *typeDict = @{
            @"id": [NSString stringWithUTF8String:unversioned_type_id],
            @"name": [NSString stringWithUTF8String:name]
        };
        [list addObject:typeDict];

//        printf("input type: %s (%s) (%s)\n", name, unversioned_type_id, deprecated ? "deprectated" : "OK");
    }
    return [list copy];
}

NSArray *bridge_video_inputs() {
    const char *video_capture_device_type = "av_capture_input";
    NSMutableArray *list = [NSMutableArray new];
    
//    obs_data_t *defaults = obs_get_source_defaults(video_capture_device_type);
//    if (defaults) {
//        obs_data_release(defaults);
//    }

    obs_properties_t *video_props = obs_get_source_properties(video_capture_device_type);

    if (video_props) {
        obs_property_t *property = obs_properties_first(video_props);
        while (property != nullptr) {
//            const char *name = obs_property_name(property);
            obs_property_type type = obs_property_get_type(property);
            if (type == OBS_PROPERTY_LIST) {
                size_t count = obs_property_list_item_count(property);
                for (size_t index = 0; index < count; index++) {
                    bool disabled = obs_property_list_item_disabled(property, index);
                    const char *name = obs_property_list_item_name(property, index);
                    const char *uid = obs_property_list_item_string(property, index);
                    if (!disabled && name != NULL && uid != NULL && strlen(name) > 0 && strlen(uid) > 0) {
//                        printf("video: %s - %s\n", name, uid);
                        NSDictionary *typeDict = @{
                            @"id": [NSString stringWithUTF8String:uid],
                            @"name": [NSString stringWithUTF8String:name]
                        };
                        [list addObject:typeDict];
                    }
                }
            }
            obs_property_next(&property);
        }
//        obs_property_t *inputs = obs_properties_get(video_props, "device_id");
        obs_properties_destroy(video_props);
    }
    return [list copy];
}
