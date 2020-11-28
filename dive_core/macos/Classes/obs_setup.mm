#import <AVFoundation/AVFoundation.h>

#include <stdio.h>
#include <time.h>

#include <functional>
#include <memory>

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <OpenGL/OpenGL.h>

#include "obslib/obs.h"
#include "obslib/obs.hpp"
#include "obslib/obs-service.h"
#include "obslib/obs-output.h"
#include "obslib/obs-properties.h"

#include "TextureSource.h"

static NSMutableArray *_textureSources = [NSMutableArray new];

extern "C" void addFrameCapture(TextureSource *textureSource) {
    if (textureSource.source_id == NULL || textureSource.source_id.length == 0) {
        printf("addFrameCapture: missing source_id\n");
        return;
    }
        
    @synchronized (_textureSources) {
        for (TextureSource *textureSource in _textureSources) {
            if ([textureSource.source_id isEqualToString: textureSource.source_id]) {
                printf("addFrameCapture: duplicate source_id: %s\n", textureSource.source_id.UTF8String);
                return;
            }
        }

        [_textureSources addObject:textureSource];
        printf("addFrameCapture: added source_id: %s\n", textureSource.source_id.UTF8String);
    }
}

extern "C" void removeFrameCapture(TextureSource *textureSource) {
    @synchronized (_textureSources) {
        [_textureSources removeObject:textureSource];
    }
}

static const int cx = 1280;
static const int cy = 720;

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

// obs is not designed for hot reload, so only start it once
bool obs_started = false;

DisplayContext display;

static void frame_callback(void *param, obs_source_t *source, struct obs_source_frame *frame);
static void print_input_types();
static void print_video_inputs();

SceneContext _add_scene() {
    const char *scene_name = "scene 1";
    SceneContext scene1{obs_scene_create(scene_name)};
    if (!scene1) {
        printf("Couldn't create scene: %s\n", scene_name);
        return scene1;
    }
    
    /* set the scene as the primary draw source and go */
    uint32_t channel = 0;
    obs_set_output_source(channel, obs_scene_get_source(scene1));

    return scene1;
}


extern "C" bool create_obs(void)
{
    if (obs_started) return true;

    if (!obs_startup("en", NULL, NULL)) {
        printf("Couldn't create OBS\n");
        return false; //throw "Couldn't create OBS";
    }

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

    int rv = obs_reset_video(&ovi);
    if (rv != OBS_VIDEO_SUCCESS) {
        printf("Couldn't initialize video: %d\n", rv);
        return false; //throw "Couldn't initialize video";
    }
    
    struct obs_audio_info ai;
    ai.samples_per_sec = 48000;
    ai.speakers = SPEAKERS_STEREO;
    if (!obs_reset_audio(&ai)) {
        printf("Couldn't initialize audio\n");
        return false;
    }

    obs_load_all_modules();
    obs_post_load_modules();
    
    print_input_types();
    print_video_inputs();
//    return true;
    
    SceneContext scene1 = _add_scene();
    
    // get list of regular cameras
    AVCaptureDeviceDiscoverySession *session = [AVCaptureDeviceDiscoverySession
        discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera, AVCaptureDeviceTypeExternalUnknown]
        mediaType:AVMediaTypeVideo
        position:AVCaptureDevicePositionUnspecified];

    // create json object for each camera
    for (int zz=0; zz!=session.devices.count; zz++) {
        AVCaptureDevice *device = session.devices[zz];
        NSString *s = @"{ ";
        s = [s stringByAppendingFormat:@"\"id\": %@, ", device.uniqueID];
        s = [s stringByAppendingFormat:@"\"name\": %@, ", device.localizedName];
        s = [s stringByAppendingFormat:@"\"facing\": %@ ", device.position == AVCaptureDevicePositionFront ? @"front" : @"back"];
        s = [s stringByAppendingString:@" }"];
        printf("camera device: %s\n", s.UTF8String);

        obs_data_t *camerSettings = obs_data_create();
        obs_data_set_string(camerSettings, "device_name", device.localizedName.UTF8String);
        obs_data_set_string(camerSettings, "device", device.uniqueID.UTF8String);

        // Load camera
        SourceContext cameraSource{obs_source_create("av_capture_input", "camera", camerSettings, nullptr)};
        if (!cameraSource)
            throw "Couldn't create camera source";
        obs_source_add_frame_callback(cameraSource, frame_callback, nullptr);
        obs_scene_add(scene1, cameraSource);
    }
    
    // Load video file
    obs_data_t *fileSettings = obs_data_create();
    obs_data_set_default_bool(fileSettings, "is_local_file", true);
    obs_data_set_default_bool(fileSettings, "looping", true);
    obs_data_set_default_bool(fileSettings, "clear_on_media_end", false);
    obs_data_set_string(fileSettings, "local_file", "/Users/larry/Downloads/Nicholas-Nationals-Play-Ball.mp4");

    SourceContext videoSource{
        obs_source_create("ffmpeg_source", "video file", fileSettings, nullptr)};
    if (!videoSource)
        throw "Couldn't create video source";
    obs_source_update(videoSource, fileSettings);
//    obs_scene_add(scene, videoSource);

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

// obs_source_frame:
//    uint8_t *data[MAX_AV_PLANES];
//    uint32_t linesize[MAX_AV_PLANES];
//    uint32_t width;
//    uint32_t height;
//    uint64_t timestamp;
//
//    enum video_format format;
//    float color_matrix[16];
//    bool full_range;
//    float color_range_min[3];
//    float color_range_max[3];
//    bool flip;

static void copy_frame_to_source(struct obs_source_frame *frame, TextureSource *textureSource)
{
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferCreateWithBytes(kCFAllocatorDefault,
                                                   frame->width,
                                                   frame->height,
                                                   kCMPixelFormat_422YpCbCr8,
                                                   frame->data[0],
                                                   frame->linesize[0],
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

static void frame_callback(void *param, obs_source_t *source, struct obs_source_frame *frame)
{
    const char *id = obs_source_get_unversioned_id(source);

    @synchronized (_textureSources) {
        for (TextureSource *textureSource in _textureSources) {
            if (strcmp(textureSource.source_id.UTF8String, id)) {
                copy_frame_to_source(frame, textureSource);
            }
        }
    }
}

static void print_input_types() {
    const char *type_id;
    const char *unversioned_type_id;
    bool foundValues = false;
    bool foundDeprecated = false;
    size_t idx = 0;
    
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

        printf("input type: %s (%s) (%s)\n", name, unversioned_type_id, deprecated ? "deprectated" : "OK");
    }
}

static void print_video_inputs() {
    const char *video_capture_device_type = "av_capture_input";
    
    obs_data_t *defaults = obs_get_source_defaults(video_capture_device_type);
    if (defaults) {
        obs_data_release(defaults);
    }

    obs_properties_t *video_props = obs_get_source_properties(video_capture_device_type);

    if (video_props) {
        obs_property_t *property = obs_properties_first(video_props);
        while (property != nullptr) {
            const char *name = obs_property_name(property);
            obs_property_type type = obs_property_get_type(property);
            if (type == OBS_PROPERTY_LIST) {
                size_t count = obs_property_list_item_count(property);
                for (size_t index = 0; index < count; index++) {
                    bool disabled = obs_property_list_item_disabled(property, index);
                    const char *name = obs_property_list_item_name(property, index);
                    const char *uid = obs_property_list_item_string(property, index);
                    if (!disabled && name != NULL && uid != NULL && strlen(name) > 0 && strlen(uid) > 0) {
                        printf("video: %s - %s\n", name, uid);
                    }
                }
            }
            obs_property_next(&property);
        }
        obs_property_t *inputs = obs_properties_get(video_props, "device_id");
        obs_properties_destroy(video_props);
    }
}
