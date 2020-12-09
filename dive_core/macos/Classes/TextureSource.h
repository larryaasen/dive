#import <FlutterMacOS/FlutterMacOS.h>

@interface TextureSource : NSObject <FlutterTexture>

@property int64_t textureId;
@property NSString *sourceUUID;

- (instancetype)initWithSourceUUID:(NSString *)sourceUUID registry:(NSObject<FlutterTextureRegistry> *)registry;
- (void)captureSample:(CVPixelBufferRef) newBuffer;

@end
