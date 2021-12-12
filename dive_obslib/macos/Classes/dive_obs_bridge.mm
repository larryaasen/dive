#include <stdio.h>
#include <string.h>
#include <time.h>
#include <functional>
#include <map>
#include <memory>

#include "obslib/obs.h"
#include "obslib/obs-service.h"
#include "obslib/obs-output.h"
#include "obslib/obs-properties.h"

#include "dive_obs_bridge.h"
#include "TextureSource.h"
#include <dive_obslib/dive_obslib-Swift.h>

template<typename T, typename D_T, D_T D>
struct OBSUniqueHandle : std::unique_ptr<T, std::function<D_T>> {
    using base = std::unique_ptr<T, std::function<D_T>>;
    explicit OBSUniqueHandle(T *obj = nullptr) : base(obj, D) {}
    operator T *() { return base::get(); }
};

struct key_cmp_str
{
   bool operator()(char const *a, char const *b) const
   {
      return std::strcmp(a, b) < 0;
   }
};

/// Map of all created scenes where the key is a scene UUID and the value is a scene pointer
static std::map<const char *, obs_scene_t *, key_cmp_str> uuid_scene_list;
static std::map<obs_scene_t *, const char *> scene_uuid_list;

/// Map of all created sources where the key is a source UUID and the value is a source pointer
static std::map<const char *, obs_source_t *, key_cmp_str> uuid_source_list;
static std::map<obs_source_t *, const char *> source_uuid_list;

static std::map<unsigned int, const char *> videomix_uuid_list;

/// Map of all texture sources where the key is a source UUID and the value is a texture source pointer
static std::map<const char *, TextureSource *, key_cmp_str> _textureSourceMap;
/// A duplicate map of all texture source that provides Objective-C reference counting
static NSMutableDictionary *_textureSources = [NSMutableDictionary new];

static void videomix_callback(void *param, struct video_data *frame);
static void source_frame_callback(void *param, obs_source_t *source, struct obs_source_frame *frame);

bool bridge_obs_startup(void)
{
    // You must call obs_startup in this plugin because it must run on
    // the main thread. Do not call in FFI because it does not run on the
    // main thread.
    return obs_startup("en", NULL, NULL);
}

void addFrameCapture(TextureSource *textureSource) {
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

void removeFrameCapture(TextureSource *textureSource) {
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

static void save_scene(NSString *tracking_uuid, obs_scene_t *scene) {
    const char *_uuid_str = tracking_uuid.UTF8String;
    const char *uuid_str = strdup(_uuid_str);
    uuid_scene_list[uuid_str] = scene;
    scene_uuid_list[scene] = uuid_str;
}

static void remove_scene(const char *uuid_str) {
    obs_scene_t *scene = uuid_scene_list[uuid_str];
    uuid_scene_list.erase(uuid_str);
    scene_uuid_list.erase(scene);
    free((void *)scene_uuid_list[scene]);
}

static void save_source(const char *source_uuid, obs_source_t *source) {
    const char *uuid_str = strdup(source_uuid);
    uuid_source_list[uuid_str] = source;
    source_uuid_list[source] = uuid_str;
}

static void remove_source(const char *uuid_str) {
    obs_source_t *source = uuid_source_list[uuid_str];
    uuid_source_list.erase(uuid_str);
    source_uuid_list.erase(source);
    free((void *)source_uuid_list[source]);
}

void logMessage(const char *function_name, int line, const char *msg) {
    printf("%s:%d %s\n", function_name, line, msg);
}

void logVideoActive(const char *function_name, int line) {
    const char *msg = obs_video_active() == 1 ? "OBS video(active)" : "OBS video(not active)";
    logMessage(function_name, line, msg);
}

static void add_videomix_callback(const char *tracking_uuid) {
    const char *tracking_uuid_str = strdup(tracking_uuid);
    
    unsigned int index=0;   // TODO: this should not be hard coded
    videomix_uuid_list[index] = tracking_uuid_str;
    
    struct video_scale_info *conversion = NULL;
    void *param = (void *)tracking_uuid_str;
    obs_add_raw_video_callback(conversion, videomix_callback, param);
    printf("%s: videomix added\n", __func__);
}

static bool remove_videomix_callback() {
    unsigned int index=0;   // TODO: this should not be hard coded
    const char *tracking_uuid_str = videomix_uuid_list[index];
    if (tracking_uuid_str == NULL) return false;
    void *param = (void *)tracking_uuid_str;
    obs_remove_raw_video_callback(videomix_callback, param);

    printf("%s: videomix removed\n", __func__);
    videomix_uuid_list.erase(index);
    free((void *)tracking_uuid_str);
    return true;
}

/// The videomix callback causes the video output to be enabled. Sometimes, such as during
/// a framerate change, the video output cannot be enabled. Use this method to disable
/// the video output, temporarily. Works with [_unsuspend_videomix].
const char *_suspend_videomix() {
    unsigned int index=0;   // TODO: this should not be hard coded
    const char *tracking_uuid_str = strdup(videomix_uuid_list[index]);
    if (tracking_uuid_str == NULL) return NULL;
    remove_videomix_callback();
    printf("%s: videomix suspended\n", __func__);
    return tracking_uuid_str;
}

void _unsuspend_videomix(const char *tracking_uuid_str) {
    add_videomix_callback(tracking_uuid_str);
    printf("%s: videomix unsuspended\n", __func__);
}

int _change_video_framerate(int32_t numerator, int32_t denominator) {
    struct obs_video_info ovi;
    int rv = OBS_VIDEO_FAIL;
    if (obs_get_video_info(&ovi)) {
        ovi.fps_num = numerator;
        ovi.fps_den = denominator;
        rv = obs_reset_video(&ovi);
    }
    printf("%s: framerate changed\n", __func__);
    return rv;
}

int _change_video_resolution(int32_t base_width, int32_t base_height, int32_t output_width, int32_t output_height) {
    struct obs_video_info ovi;
    int rv = OBS_VIDEO_FAIL;
    if (obs_get_video_info(&ovi)) {
        ovi.base_width = base_width;
        ovi.base_height = base_height;
        ovi.output_width = output_width;
        ovi.output_height = output_height;
        rv = obs_reset_video(&ovi);
    }
    printf("%s: resolution changed\n", __func__);
    return rv;
}

/// Change the frame rate.
/// When video output is active, like with a video mix, it must be removed temporarily during
/// the called to `obs_reset_video()`.
bool bridge_change_video_framerate(int32_t numerator, int32_t denominator) {
    const char *tracking_uuid_str = _suspend_videomix();
    if (tracking_uuid_str == NULL) return false;
    if (_change_video_framerate(numerator, denominator) != OBS_VIDEO_SUCCESS) return false;
    _unsuspend_videomix(tracking_uuid_str);
    free((void *)tracking_uuid_str);
    return true;
}

/// Change the frame rate.
/// When video output is active, like with a video mix, it must be removed temporarily during
/// the called to `obs_reset_video()`.
bool bridge_change_video_resolution(int32_t base_width, int32_t base_height, int32_t output_width, int32_t output_height) {
    const char *tracking_uuid_str = _suspend_videomix();
    if (tracking_uuid_str == NULL) return false;
    if (_change_video_resolution(base_width, base_height, output_width, output_height) != OBS_VIDEO_SUCCESS) return false;
    _unsuspend_videomix(tracking_uuid_str);
    free((void *)tracking_uuid_str);
    return true;
}

static uint8_t *swap_blue_red_colors(uint8_t *data, size_t dataSize) {
    uint8_t *newData = (uint8_t *)malloc(dataSize);
    memcpy(newData, data, dataSize);
    
    for (unsigned int zz=0; zz<dataSize; zz+=4) {
        // swap bytes 0 and 2 out of 0-3
        uint8_t temp = newData[zz];
        newData[zz] = newData[zz+2];
        newData[zz+2] = temp;
    }
    return newData;
}

// TODO: remove this
void BufferReleaseBytesCallback(void *releaseRefCon, const void *baseAddress) {
    free((void *)baseAddress);
    return;
}

bool captureSampleFrame = false;
bool useSampleFrame = false;
int frameCount = 0;

NSData *theData = NULL;

static void copy_frame_to_texture(size_t width, size_t height, OSType pixelFormatType, size_t linesize, uint8_t *data,
                                  TextureSource *textureSource, bool shouldSwapRedBlue=false)
{
//    NSLog(@"pixelFormatType=%@, linesize=%ld", NSFileTypeForHFSTypeCode(pixelFormatType), linesize);
////     If pixel format is 2vuy
//    if (pixelFormatType == kCVPixelFormatType_422YpCbCr8) {
//        NSLog(@"%s: pixelFormatType %@ not yet supported", __func__, NSFileTypeForHFSTypeCode(pixelFormatType));
//        return;
//    }

    if (captureSampleFrame) {
        frameCount++;
        if (frameCount == 100) {
            NSMutableArray *lines = [NSMutableArray new];
            [lines addObject:[NSString stringWithFormat:@"\n"]];
            [lines addObject:[NSString stringWithFormat:@"width=%ld;", width]];
            [lines addObject:[NSString stringWithFormat:@"height=%ld;", height]];
            [lines addObject:[NSString stringWithFormat:@"pixelFormatType=%d;", pixelFormatType]];
            [lines addObject:[NSString stringWithFormat:@"linesize=%ld;", linesize]];
            
            NSData *theData = [NSData dataWithBytesNoCopy:&data[0]
                                                   length:linesize*height
                                             freeWhenDone:NO];
            [theData writeToFile:@"demo_frame" atomically:NO];
            printf("%s", [[lines componentsJoinedByString:@"\n"] cStringUsingEncoding:NSASCIIStringEncoding]);
        }
    }
    else if (useSampleFrame) {
        if (theData == NULL) {
            NSString *path =
              [[NSBundle mainBundle] pathForResource:@"demo_frame"
                                              ofType:@""];
            theData = [NSData dataWithContentsOfFile:path];
        }
        data = (uint8_t *)[theData bytes];
    }
    else {
        if (shouldSwapRedBlue) {
           data = swap_blue_red_colors(data, linesize*height);
       }
    }

    CVPixelBufferRef pxbuffer = NULL;
    NSDictionary* attributes = @{
        (id)kCVPixelBufferPixelFormatTypeKey : @(pixelFormatType),
        (id)kCVPixelBufferOpenGLCompatibilityKey : @YES,
        (id)kCVPixelBufferMetalCompatibilityKey : @YES
    };

    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault,
                                          width,
                                          height,
                                          pixelFormatType,
                                          (__bridge CFDictionaryRef)attributes,
                                          &pxbuffer);
    if (status != kCVReturnSuccess) {
        NSLog(@"copy_frame_to_source: Operation failed");
        return;
    }
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);

    void *copyBaseAddress = CVPixelBufferGetBaseAddress(pxbuffer);
    memcpy(copyBaseAddress, data, linesize*height);

    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);

    if (shouldSwapRedBlue) {
        free(data);
    }

    [textureSource captureSample: pxbuffer];
    
    // On Flutter <=2.0, the release must be called here.
    // On Flutter >=2.2, this release will break things.
    CFRelease(pxbuffer);
}

static void copy_planar_frame_to_texture(size_t width, size_t height, OSType pixelFormatType, uint32_t linesize[], uint8_t *data[], TextureSource *textureSource)
{
    CVPixelBufferRef pixelBufferOut = NULL;
    size_t plane_count = 3;
    size_t planeWidths[3] = {width, width/2, width/2};
    size_t planeHeights[3] = {height, height/2, height/2};
    size_t planeBytesPerRows[3] = {linesize[0], linesize[1], linesize[2]};
    uint8_t *plane_ptrs[3] = {data[0], data[1], data[2]};
    size_t contiguous_buf_size =
        (planeBytesPerRows[0]*planeHeights[0]) +
        (planeBytesPerRows[1]*planeHeights[1]) +
        (planeBytesPerRows[2]*planeHeights[2]);
    NSDictionary* attributes = @{
        (id)kCVPixelBufferPixelFormatTypeKey : @(pixelFormatType),
        (id)kCVPixelBufferOpenGLCompatibilityKey : @YES,
        (id)kCVPixelBufferMetalCompatibilityKey : @YES
    };

    CVReturn status = CVPixelBufferCreateWithPlanarBytes(
                                       kCFAllocatorDefault,
                                       width,
                                       height,
                                       pixelFormatType,
                                       NULL,
                                       contiguous_buf_size,
                                       plane_count,
                                       (void **)plane_ptrs,
                                       planeWidths,
                                       planeHeights,
                                       planeBytesPerRows,
                                       NULL,
                                       NULL,
                                       (__bridge CFDictionaryRef)attributes,
                                       &pixelBufferOut);

    if (status != kCVReturnSuccess) {
        NSLog(@"copy_planar_frame_to_texture: Operation failed");
        return;
    }
    
    [textureSource captureSample: pixelBufferOut];
    CFRelease(pixelBufferOut);
}

static void copy_source_frame_to_texture(struct obs_source_frame *frame, TextureSource *textureSource)
{
    if (frame->format == VIDEO_FORMAT_UYVY) {
        copy_frame_to_texture(frame->width, frame->height, kCVPixelFormatType_422YpCbCr8, frame->linesize[0], frame->data[0], textureSource);
    } else if (frame->format == VIDEO_FORMAT_I420) {
        copy_planar_frame_to_texture(frame->width, frame->height, kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange, frame->linesize, frame->data, textureSource);
    }
}

static void copy_videomix_frame_to_texture(struct video_data *frame, TextureSource *textureSource)
{
    struct obs_video_info ovi;
    obs_get_video_info(&ovi);

    copy_frame_to_texture(ovi.output_width, ovi.output_height, kCVPixelFormatType_32BGRA, frame->linesize[0], frame->data[0], textureSource, true);
}

static void source_frame_callback(void *param, obs_source_t *source, struct obs_source_frame *frame)
{
    const char *uuid_str = source_uuid_list[source];
    if (uuid_str == NULL) {
        printf("%s: unknown source %s\n", __func__, uuid_str);
        return;
    }

//    printf("%s: %s\n", __func__, uuid_str);

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
//    printf("%s linesize[0] %d\n", __func__, frame->linesize[0]);

    // TODO: need lock around the use of videomix_uuid_list. Maybe use @synchronized (_textureSources) below
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

// TODO: implement sources: color source.


// TODO: error handling of input paramters, and make this work in the bridge

static obs_source_t *_create_source(const char *source_uuid, const char *source_id, const char *name, obs_data_t *settings, bool frame_source) {
    obs_source_t *source = obs_source_create(source_id, name, settings, nullptr);
    if (!source) {
        printf("%s: Could not create source\n", __func__);
        return NULL;
    }
    
    if (frame_source) {
        obs_source_add_frame_callback(source, source_frame_callback, nullptr);
    }

    save_source(source_uuid, source);

    return source;
}

#pragma mark - New Bridge functions to keep

bool bridge_source_add_frame_callback(const char *source_uuid, int64_t source_ptr) {
    obs_source_t *source = (obs_source_t *)source_ptr;
    obs_source_add_frame_callback(source, source_frame_callback, nullptr);
    save_source(source_uuid, source);
    return true;
}

bool bridge_add_videomix(const char *tracking_uuid) {
    add_videomix_callback(tracking_uuid);
    return true;
}

bool bridge_remove_videomix(const char *tracking_uuid) {
    remove_videomix_callback();
    return true;
}

#pragma mark - Bridge functions

bool bridge_create_source(const char *source_uuid, const char *source_id, const char *name, bool frame_source) {
    obs_data_t *settings = NULL;
    return _create_source(source_uuid, source_id, name, settings, frame_source);
}

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
    obs_data_t *settings = obs_get_source_defaults("ffmpeg_source");
    obs_data_set_bool(settings, "is_local_file", true);
    obs_data_set_bool(settings, "looping", false);
    obs_data_set_bool(settings, "clear_on_media_end", false);
    obs_data_set_bool(settings, "close_when_inactive", true);
    obs_data_set_bool(settings, "restart_on_activate", false);
    obs_data_set_string(settings, "local_file", local_file.UTF8String);
    
    // TODO: add this file open check to propvide feedback on failures
//    FILE *fp = fopen(local_file.UTF8String, "r");
//    if (fp == NULL) {
//        int errnum = errno;
//        fprintf(stderr, "Value of errno: %d\n", errno);
//        perror("Error printed by perror");
//        fprintf(stderr, "Error opening file: %s\n", strerror( errnum ));
//    }
//    fclose(fp);

    obs_source_t *source = _create_source(source_uuid.UTF8String, "ffmpeg_source", "video file", settings, true);
    return source != NULL;
}

// TODO: creating a video source breaks the Flutter connection to the device.
bool bridge_create_video_source(NSString *source_uuid, NSString *device_name, NSString *device_uid) {
    obs_data_t *settings = obs_data_create();
    obs_data_set_string(settings, "device_name", device_name.UTF8String);
    obs_data_set_string(settings, "device", device_uid.UTF8String);
    
    obs_source_t *source = _create_source(source_uuid.UTF8String, "av_capture_input", "camera", settings, true);
    return source != NULL;
}

bool bridge_create_image_source(NSString *source_uuid, NSString *file) {
    obs_data_t *settings = obs_data_create();
    obs_data_set_string(settings, "file", file.UTF8String);
    
    obs_source_t *source = _create_source(source_uuid.UTF8String, "image_source", "image", settings, true);
    return source != NULL;
}

/// Add an existing source to an existing scene.
int64_t bridge_add_source(NSString *scene_uuid, NSString *source_uuid) {
    const char *scene_uuid_str = scene_uuid.UTF8String;
    obs_scene_t *scene = uuid_scene_list[scene_uuid_str];
    if (!scene) {
        printf("%s: unknown scene %s\n", __func__, scene_uuid_str);
        return 0;
    }

    const char *source_uuid_str = source_uuid.UTF8String;
    obs_source_t *source = uuid_source_list[source_uuid_str];
    if (!source) {
        printf("%s: unknown source %s\n", __func__, source_uuid_str);
        return 0;
    }

    obs_sceneitem_t *item = obs_scene_add(scene, source);
    int64_t item_id = obs_sceneitem_get_id(item);

    return item_id;
}

static NSDictionary *_convert_transform_vec2_to_dict(vec2 vec) {
    NSDictionary *dict = @{
        @"x": [[NSNumber alloc] initWithFloat:vec.x],
        @"y": [[NSNumber alloc] initWithFloat:vec.y]
    };

    return dict;
}

static NSDictionary *_convert_transform_info_to_dict(obs_transform_info *info) {
    NSDictionary *infoDict = @{
        @"pos": _convert_transform_vec2_to_dict(info->pos),
        @"rot": [[NSNumber alloc] initWithFloat:info->rot],
        @"scale": _convert_transform_vec2_to_dict(info->scale),
        @"alignment": [[NSNumber alloc] initWithUnsignedInteger:info->alignment],
        @"bounds_type": [[NSNumber alloc] initWithUnsignedInteger:info->bounds_type],
        @"bounds_alignment": [[NSNumber alloc] initWithUnsignedInteger:info->bounds_alignment],
        @"bounds": _convert_transform_vec2_to_dict(info->bounds)
    };

    return infoDict;
}

/// Get the transform info for a scene item.

/// TODO: refactor scene_uuid into scene pointer
NSDictionary *bridge_sceneitem_get_info(int64_t sceneitem_pointer) {
    obs_sceneitem_t *item = (obs_sceneitem_t *)sceneitem_pointer;
    obs_transform_info info;
    obs_sceneitem_get_info(item, &info);
    return _convert_transform_info_to_dict(&info);
}

/// Set the transform info for a scene item.
bool bridge_sceneitem_set_info(int64_t sceneitem_pointer, NSDictionary *info) {
    obs_sceneitem_t *item = (obs_sceneitem_t *)sceneitem_pointer;

    obs_transform_info item_info;
    item_info.pos.x = [info[@"pos"][@"x"] floatValue];
    item_info.pos.y = [info[@"pos"][@"y"] floatValue];
    item_info.rot = [info[@"rot"] floatValue];
    item_info.scale.x = [info[@"scale"][@"x"] floatValue];
    item_info.scale.y = [info[@"scale"][@"y"] floatValue];
    item_info.alignment = [info[@"alignment"] unsignedIntValue];
    item_info.bounds_type = (obs_bounds_type)[info[@"bounds_type"] unsignedIntValue];
    item_info.bounds_alignment = [info[@"bounds_alignment"] unsignedIntValue];
    item_info.bounds.x = [info[@"bounds"][@"x"] floatValue];
    item_info.bounds.y = [info[@"bounds"][@"y"] floatValue];
    
    obs_sceneitem_set_info(item, &item_info);

    return false;
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

bool bridge_media_source_restart(NSString *source_uuid) {
    const char *uuid_str = source_uuid.UTF8String;
    obs_source_t *source = uuid_source_list[uuid_str];
    if (!source) {
        printf("%s: unknown source %s\n", __func__, uuid_str);
        return false;
    }
    obs_source_media_restart(source);
    return true;
}

/// Media control: stop
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

/// Media control: get time
int64_t bridge_media_source_get_duration(NSString *source_uuid) {
    const char *uuid_str = source_uuid.UTF8String;
    obs_source_t *source = uuid_source_list[uuid_str];
    if (!source) {
        printf("%s: unknown source %s\n", __func__, uuid_str);
        return 0;
    }

    return obs_source_media_get_duration(source);
}

/// Media control: get time
int64_t bridge_media_source_get_time(NSString *source_uuid) {
    const char *uuid_str = source_uuid.UTF8String;
    obs_source_t *source = uuid_source_list[uuid_str];
    if (!source) {
        printf("%s: unknown source %s\n", __func__, uuid_str);
        return 0;
    }

    return obs_source_media_get_time(source);
}

/// Media control: set time
bool bridge_media_source_set_time(NSString *source_uuid, int64_t ms) {
    const char *uuid_str = source_uuid.UTF8String;
    obs_source_t *source = uuid_source_list[uuid_str];
    if (!source) {
        printf("%s: unknown source %s\n", __func__, uuid_str);
        return false;
    }

    obs_source_media_set_time(source, ms);
    return true;
}

// TODO: implement signals from media source: obs_source_get_signal_handler

/// Media control: get state
int bridge_media_source_get_state(NSString *source_uuid) {
    const char *uuid_str = source_uuid.UTF8String;
    obs_source_t *source = uuid_source_list[uuid_str];
    if (!source) {
        printf("%s: unknown source %s\n", __func__, uuid_str);
        return false;
    }

    obs_media_state state = obs_source_media_get_state(source);
    return state;
}

#pragma mark - Volume Level

NSMutableArray<NSNumber *> *_magnitudeNumbers = [NSMutableArray arrayWithCapacity:MAX_AUDIO_CHANNELS];
NSMutableArray<NSNumber *> *_peakNumbers = [NSMutableArray arrayWithCapacity:MAX_AUDIO_CHANNELS];
NSMutableArray<NSNumber *> *_inputPeakNumbers = [NSMutableArray arrayWithCapacity:MAX_AUDIO_CHANNELS];
NSNumber *zeroNumber = @0;

NSArray<NSNumber *> *toFloatArray(NSMutableArray<NSNumber *> *numbers, const float values[], int array_size) {
    [numbers removeAllObjects];
    for (int zz=0; zz!=array_size; zz++) {
        [numbers addObject:[NSNumber numberWithFloat:values[zz]]];
    }
    return numbers;
}

void _volume_level_callback(void *param,
                const float magnitude[MAX_AUDIO_CHANNELS],
                const float peak[MAX_AUDIO_CHANNELS],
                const float input_peak[MAX_AUDIO_CHANNELS])
{
    int64_t volmeter_pointer = (int64_t)param;
    @synchronized (_magnitudeNumbers) {
        [[Callbacks shared] volMeterCallbackWithPointer:volmeter_pointer
                                              magnitude:toFloatArray(_magnitudeNumbers, magnitude, MAX_AUDIO_CHANNELS)
                                                   peak:toFloatArray(_peakNumbers, peak, MAX_AUDIO_CHANNELS)
                                              inputPeak:toFloatArray(_inputPeakNumbers, input_peak, MAX_AUDIO_CHANNELS)
                                              arraySize:MAX_AUDIO_CHANNELS];
    }
}

/// Adds a callback to a volume meter, and returns the number of channels which are configured for this source.
int64_t bridge_volmeter_add_callback(int64_t volmeter_pointer) {
    obs_volmeter_t *volmeter = (obs_volmeter_t *)volmeter_pointer;
    obs_volmeter_add_callback(volmeter, _volume_level_callback, (void *)volmeter_pointer);
    return obs_volmeter_get_nr_channels(volmeter);
}

#pragma mark - Inputs

/// Get a list of input types.
/// @return array of dictionaries with keys `id` and `name`.
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

/// Get a list of inputs from input type.
/// @return array of dictionaries with keys `id` and `name`.
NSArray *bridge_inputs_from_type(const char *input_type_id) {
    NSMutableArray *list = [NSMutableArray new];

    obs_properties_t *video_props = obs_get_source_properties(input_type_id);

    if (video_props) {
        obs_property_t *property = obs_properties_first(video_props);
        while (property != nullptr) {
            obs_property_type type = obs_property_get_type(property);
            if (type == OBS_PROPERTY_LIST) {
                size_t count = obs_property_list_item_count(property);
                for (size_t index = 0; index < count; index++) {
                    bool disabled = obs_property_list_item_disabled(property, index);
                    const char *name = obs_property_list_item_name(property, index);
                    const char *uid = obs_property_list_item_string(property, index);
                    if (!disabled && name != NULL && uid != NULL && strlen(name) > 0 && strlen(uid) > 0) {
                        NSDictionary *typeDict = @{
                            @"id": [NSString stringWithUTF8String:uid],
                            @"name": [NSString stringWithUTF8String:name],
                            @"type_id": [NSString stringWithUTF8String:input_type_id]
                        };
                        [list addObject:typeDict];
                    }
                }
            }
            obs_property_next(&property);
        }
        obs_properties_destroy(video_props);
    }
    return [list copy];
}

#ifdef __APPLE__
#define INPUT_AUDIO_SOURCE "coreaudio_input_capture"
#define OUTPUT_AUDIO_SOURCE "coreaudio_output_capture"
#elif _WIN32
#define INPUT_AUDIO_SOURCE "wasapi_input_capture"
#define OUTPUT_AUDIO_SOURCE "wasapi_output_capture"
#else
#define INPUT_AUDIO_SOURCE "pulse_input_capture"
#define OUTPUT_AUDIO_SOURCE "pulse_output_capture"
#endif

/// Get a list of video capture inputs from input type `coreaudio_input_capture`.
/// @return array of dictionaries with keys `id` and `name`.
NSArray *bridge_audio_inputs() {
    return bridge_inputs_from_type(INPUT_AUDIO_SOURCE);
}

/// Get a list of video capture inputs from input type `av_capture_input`.
/// @return array of dictionaries with keys `id` and `name`.
NSArray *bridge_video_inputs() {
    return bridge_inputs_from_type("av_capture_input");
}
