#include <stdio.h>
#import <libkern/OSAtomic.h>

#import "TextureSource.h"

@interface TextureSource ()
@property NSString *name;
@property NSObject<FlutterTextureRegistry> *registry;
@property(readonly) CVPixelBufferRef volatile latestPixelBuffer;
@property unsigned long _sampleCount;

@end

@implementation TextureSource

- (instancetype)initWithName:(NSString *)name registry:(NSObject<FlutterTextureRegistry> *)registry {
    self = [super init];
    NSAssert(self, @"super init cannot be nil");
    
    self.name = name;
    self.registry = registry;
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

    printf("copyPixelBuffer\n");
    return pixelBuffer;
}

- (void)captureSample:(CVPixelBufferRef) newBuffer {
    self._sampleCount++;
    CFRetain(newBuffer);
    CVPixelBufferRef old = _latestPixelBuffer;
    while (!OSAtomicCompareAndSwapPtrBarrier(old, newBuffer, (void **)&_latestPixelBuffer)) {
        old = _latestPixelBuffer;
    }
    if (old != nil) {
        CFRelease(old);
    }
    [self.registry textureFrameAvailable:self.textureId];
    printf("captureSample: count: %ld\n", self._sampleCount);
}

@end
