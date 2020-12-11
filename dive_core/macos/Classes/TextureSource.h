#import <FlutterMacOS/FlutterMacOS.h>

@interface TextureSource : NSObject <FlutterTexture>

@property int64_t textureId;
@property NSString *trackingUUID;

- (instancetype)initWithUUID:(NSString *)sourceUUID registry:(NSObject<FlutterTextureRegistry> *)registry;
- (void)captureSample:(CVPixelBufferRef) newBuffer;

@end
