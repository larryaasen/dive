#import <AVFoundation/AVFoundation.h>

#include <stdio.h>
#include <time.h>

#include <functional>
#include <memory>

#import <Cocoa/Cocoa.h>
#import <AppKit/AppKit.h>
#import <OpenGL/OpenGL.h>

#include <obslib/obs.h>
#include "obslib/obs.hpp"
#include "obslib/obs-service.h"
#include "obslib/obs-output.h"
#include "obslib/obs-properties.h"

#include "TextureSource.h"
NSMutableArray *sources = [NSMutableArray new];

void addFrameCapture(TextureSource *textureSource) {
    [sources addObject:textureSource];
}

void removeFrameCapture(TextureSource *textureSource) {
    [sources removeObject:textureSource];
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

void test_function() {
    printf("test function\n");
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
     
    // display = CreateDisplay(nullptr);
    // obs_display_add_draw_callback(
    //     display.get(),
    //     [](void *, uint32_t, uint32_t) {
    //         // obs_render_main_texture();
    //         printf("render\n");
    //     },
    //     nullptr
    // );

    obs_load_all_modules();
    obs_post_load_modules();
    
    obs_data_t *camerSettings = obs_data_create();
//    for (AVCaptureDevice *dev in [AVCaptureDevice devices]) {
//        if ([dev hasMediaType:AVMediaTypeVideo] ||
//            [dev hasMediaType:AVMediaTypeMuxed]) {
//            printf("camera: name %s, id %s\n", dev.localizedName.UTF8String, dev.uniqueID.UTF8String);
//            obs_data_set_string(camerSettings, "device_name", dev.localizedName.UTF8String);
//            obs_data_set_string(camerSettings, "device", dev.uniqueID.UTF8String);
//            break;
//        }
//    }
    
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
        if (zz == 1) {
            obs_data_set_string(camerSettings, "device_name", device.localizedName.UTF8String);
            obs_data_set_string(camerSettings, "device", device.uniqueID.UTF8String);
            break;
        }
    }
    
//    obs_properties_t *prop = obs_source_properties();
    
//    for (AVCaptureDevice *device in session.devices) {
//        NSString *s = @"{ ";
//        s = [s stringByAppendingFormat:@"\"id\": %@, ", device.uniqueID];
//        s = [s stringByAppendingFormat:@"\"name\": %@, ", device.localizedName];
//        s = [s stringByAppendingFormat:@"\"facing\": %@, ", device.position == AVCaptureDevicePositionFront ? @"front" : @"back"];
//        s = [s stringByAppendingFormat:@"\"orientation\": 0, "];
//        s = [s stringByAppendingFormat:@"\"forcedShutterSound\": false"];
//        s = [s stringByAppendingString:@" }"];
//        printf("camera device: %s\n", s.UTF8String);
//        if (device.position == AVCaptureDevicePositionFront) {
//            obs_data_set_string(camerSettings, "device_name", device.localizedName.UTF8String);
//            obs_data_set_string(camerSettings, "device", device.uniqueID.UTF8String);
//            break;
//        }
//    }

//    obs_data_set_string(camerSettings, "device_name", "FaceTime HD Camera");
//    obs_data_set_string(camerSettings, "device", "0x8020000005ac8514");
    
    // return true;

    // Load camera
    obs_source_t *source = obs_source_create("av_capture_input", "camera", camerSettings, nullptr);
    if (!source)
        throw "Couldn't create camera source";
    SourceContext cameraSource{source};
    obs_source_add_frame_callback(cameraSource, frame_callback, nullptr);

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

    SceneContext scene{obs_scene_create("test scene")};
    if (!scene) {
        printf("Couldn't create scene\n");
        return false;
    }

    obs_sceneitem_t *sceneitem;
//    sceneitem = obs_scene_add(scene, videoSource);
    sceneitem = obs_scene_add(scene, cameraSource);
    
    /* set the scene as the primary draw source and go */
    uint32_t channel = 0;
    obs_set_output_source(channel, obs_scene_get_source(scene));
    
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
    
    obs_output_start(streamOutput); 

    return true;
}

static void copy_frame_to_source(struct obs_source_frame *frame, TextureSource *textureSource)
{
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


    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferCreateWithBytes(kCFAllocatorDefault,
                                                   frame->width,
                                                   frame->height,
                                                   kCVPixelFormatType_32ARGB,
                                                   frame->data[0],
                                                   frame->width * 4,
                                                   NULL,
                                                   NULL,
                                                   NULL,
                                                   &pxbuffer);
    if (status != kCVReturnSuccess) {
        NSLog(@"copy_frame_to_source: Operation failed");
        return;
    }

    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    
    [textureSource captureSample: pxbuffer];
}

static void frame_callback(void *param, obs_source_t *source, struct obs_source_frame *frame)
{
    obs_data_t *settings = obs_source_get_settings(source);
    const char *device = obs_data_get_string(settings, "device");
    printf("frame_callback called for device %s\n", device);

    @synchronized (sources) {
        for (TextureSource *textureSource in sources) {
            copy_frame_to_source(frame, textureSource);
        }
    }
}
