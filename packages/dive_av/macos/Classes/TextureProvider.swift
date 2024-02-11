// Copyright (c) 2024 Larry Aasen. All rights reserved.

import FlutterMacOS

/// TextureProvider - Saves frames for use by the Flutter Texture Registry.
class TextureProvider: NSObject, FlutterTexture {

  var textureId: Int64 = 0
  let trackingUUID: String
  private let registry: (NSObjectProtocol & FlutterTextureRegistry)?
  private var latestPixelBuffer: CVPixelBuffer?
  private var sampleCount: UInt = 0
  private var copyPixelCount: UInt = 0

  /// Initialize with a tracking UUID and a Flutter Texture Registry.
  init(uuid trackingUUID: String, registry: (NSObjectProtocol & FlutterTextureRegistry)?) {
    assert(registry != nil, "registry cannot be nil")

    self.trackingUUID = trackingUUID
    self.registry = registry
    super.init()
  }

  deinit {
    latestPixelBuffer = nil
  }

  /// Copy the contents of the texture into a `CVPixelBuffer`. */
  /// Conforms to the protocol FlutterTexture.
  /// As o f 10/19/2021: Expects texture format of kCVPixelFormatType_32ARGB, to be used with GL_RGBA8 in CVOpenGLTextureCacheCreateTextureFromImage.
  /// https://github.com/flutter/engine/blob/eaf77ff9e96bbe79c7377b7376c73b9d9243cf7c/shell/platform/darwin/macos/framework/Source/FlutterExternalTextureGL.mm#L62
  func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
    copyPixelCount += 1
    var pixelBuffer: CVPixelBuffer?
    objc_sync_enter(trackingUUID)
    pixelBuffer = latestPixelBuffer
    objc_sync_exit(trackingUUID)

    if let pixelBuffer {
      return Unmanaged.passRetained(pixelBuffer)
    }
    return nil
  }

  /// Save a frame (pixel buffer) and inform the Flutter Texture Registry.
  func captureSample(_ newBuffer: CVPixelBuffer?) {
    if textureId == 0 {
      return
    }

    sampleCount += 1

    objc_sync_enter(trackingUUID)
    latestPixelBuffer = newBuffer
    objc_sync_exit(trackingUUID)

    // Inform the Flutter Texture Registry that a texture frame is available to draw.
    registry?.textureFrameAvailable(textureId)
  }
}
