#import <OpenGL/OpenGL.h>

#ifdef __cplusplus
extern "C" {
#endif

@class TextureSource;
void test_function(void);
bool create_obs(void);
void addFrameCapture(TextureSource *textureSource);
void removeFrameCapture(TextureSource *textureSource);

#ifdef __cplusplus
}
#endif
