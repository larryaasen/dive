#import "TextureSource.h"

@interface TextureSource ()
@property NSObject<FlutterTextureRegistry> *registry;
@property(readonly) CVPixelBufferRef volatile latestPixelBuffer;
@property unsigned long sampleCount;
@property unsigned long copyPixelCount;

@end

/// TextureSource - Saves frames for use by the Flutter Texture Registry.
@implementation TextureSource

/// Initialize with a tracking UUID and a Flutter Texture Registry.
- (instancetype)initWithUUID:(NSString *)trackingUUID registry:(NSObject<FlutterTextureRegistry> *)registry {
    self = [super init];
    NSAssert(self, @"super init cannot be nil");
    NSAssert(trackingUUID, @"trackingUUID cannot be nil");
    NSAssert(registry, @"registry cannot be nil");
    
    self.trackingUUID = trackingUUID;
    self.registry = registry;
    self.textureId = 0;
    return self;
}

- (void)dealloc {
    if (_latestPixelBuffer) {
        CFRelease(_latestPixelBuffer);
        _latestPixelBuffer = NULL;
    }
}

/// Copy the contents of the texture into a `CVPixelBuffer`. */
/// Conforms to the protocol FlutterTexture.
/// As o f 10/19/2021: Expects texture format of kCVPixelFormatType_32ARGB, to be used with GL_RGBA8 in CVOpenGLTextureCacheCreateTextureFromImage.
/// https://github.com/flutter/engine/blob/eaf77ff9e96bbe79c7377b7376c73b9d9243cf7c/shell/platform/darwin/macos/framework/Source/FlutterExternalTextureGL.mm#L62
- (CVPixelBufferRef)copyPixelBuffer {
    _copyPixelCount++;
    CVPixelBufferRef pixelBuffer = NULL;
    @synchronized (_trackingUUID) {
        pixelBuffer = _latestPixelBuffer;
    }

    if (pixelBuffer != NULL) {
        CFRetain(pixelBuffer);
    }
    return pixelBuffer;
}

/// Save a frame (pixel buffer) and inform the Flutter Texture Registry.
- (void)captureSample:(CVPixelBufferRef) newBuffer {
    if (self.textureId == 0) return;

    _sampleCount++;

    @synchronized (_trackingUUID) {
        if (_latestPixelBuffer) {
            CFRelease(_latestPixelBuffer);
        }
        _latestPixelBuffer = newBuffer;
    }

    /// Inform the Flutter Texture Registry that a texture frame is available to draw.
    [self.registry textureFrameAvailable:self.textureId];
}

@end
