#include <stdio.h>
#import <libkern/OSAtomic.h>
#import <stdatomic.h>
#import "TextureSource.h"

@interface TextureSource ()
@property NSObject<FlutterTextureRegistry> *registry;
@property(readonly) CVPixelBufferRef volatile latestPixelBuffer;
@property unsigned long _sampleCount;

@end

@implementation TextureSource

- (instancetype)initWithUUID:(NSString *)trackingUUID registry:(NSObject<FlutterTextureRegistry> *)registry {
    self = [super init];
    NSAssert(self, @"super init cannot be nil");
    
    self.trackingUUID = trackingUUID;
    self.registry = registry;
    self.textureId = 0;
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

//    printf("TextureSource: copyPixelBuffer %s\n", self.trackingUUID.UTF8String);
    return pixelBuffer;
}

- (void)captureSample:(CVPixelBufferRef) newBuffer {
    if (self.textureId == 0) return;

    self._sampleCount++;
    CFRetain(newBuffer);
    CVPixelBufferRef old = _latestPixelBuffer;
//    atomic_compare_exchange_strong(<#object#>, <#expected#>, <#desired#>);
    while (!OSAtomicCompareAndSwapPtrBarrier(old, newBuffer, (void **)&_latestPixelBuffer)) {
        old = _latestPixelBuffer;
    }
    if (old != nil) {
        CFRelease(old);
    }
//    printf("TextureSource: before textureFrameAvailable\n");
    [self.registry textureFrameAvailable:self.textureId];
//    printf("TextureSource captureSample: %s: count=%ld\n", self.trackingUUID.UTF8String, self._sampleCount);
}

@end
