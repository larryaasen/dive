#import <FlutterMacOS/FlutterMacOS.h>

@interface TextureSource : NSObject <FlutterTexture>

@property NSString *name;
@property int64_t textureId;
@property NSString *source_id;

- (instancetype)initWithName:(NSString *)name registry:(NSObject<FlutterTextureRegistry> *)registry;
- (void)captureSample:(CVPixelBufferRef) newBuffer;

@end
