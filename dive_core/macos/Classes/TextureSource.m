#include <stdio.h>
#import <libkern/OSAtomic.h>

#import "TextureSource.h"
#import "dive_core.h"

@interface TextureSource ()
@property NSString *name;
@property NSObject<FlutterTextureRegistry> *registry;
@property(readonly) CVPixelBufferRef volatile latestPixelBuffer;
@end

@implementation TextureSource

- (instancetype)initWithName:(NSString *)name registry:(NSObject<FlutterTextureRegistry> *)registry {
    self = [super init];
    NSAssert(self, @"super init cannot be nil");
    
    self.name = name;
    self.registry = registry;
    
//    addFrameCapture(self);
    return self;
}

- (void)dealloc {
    if (_latestPixelBuffer) {
        CFRelease(_latestPixelBuffer);
    }
}

- (CVPixelBufferRef)copyPixelBuffer {
    CVPixelBufferRef pixelBuffer = _latestPixelBuffer;
    while (!OSAtomicCompareAndSwapPtrBarrier(pixelBuffer, nil, (void **)&_latestPixelBuffer)) {
        pixelBuffer = _latestPixelBuffer;
    }
    
    return pixelBuffer;
}

- (void)captureSample:(CVPixelBufferRef) newBuffer {
    CVPixelBufferRef old = _latestPixelBuffer;
    while (!OSAtomicCompareAndSwapPtrBarrier(old, newBuffer, (void **)&_latestPixelBuffer)) {
        old = _latestPixelBuffer;
    }
    if (old != nil) {
        CFRelease(old);
    }
    [self.registry textureFrameAvailable:self.textureId];
    test_function();
}

@end
