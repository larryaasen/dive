// Copyright (c) 2024 Larry Aasen. All rights reserved.

import CoreVideo
import FlutterMacOS
import Foundation

/// TextureProvider - Saves frames for use by the Flutter Texture Registry.
@available(macOS 13.0, *)
class TextureProvider: NSObject, FlutterTexture {

  var textureId: Int64 = 0

  private let registry: (NSObjectProtocol & FlutterTextureRegistry)
  private var latestPixelBuffer: CVPixelBuffer?
  private var sampleCount: UInt = 0
  private var copyPixelCount: UInt = 0

  /// Initialize with a Flutter Texture Registry.
  init(registry: (NSObjectProtocol & FlutterTextureRegistry)) {
    //    self.trackingUUID = trackingUUID
    self.registry = registry
    super.init()
  }

  deinit {
    latestPixelBuffer = nil
  }

  func register() -> Int64 {
    textureId = registry.register(self)
    if textureId != 0 {
    }
    return textureId

  }

  /// Copy the contents of the texture into a `CVPixelBuffer`. */
  /// Conforms to the protocol FlutterTexture.
  /// As o f 10/19/2021: Expects texture format of kCVPixelFormatType_32ARGB, to be used with GL_RGBA8 in CVOpenGLTextureCacheCreateTextureFromImage.
  /// https://github.com/flutter/engine/blob/eaf77ff9e96bbe79c7377b7376c73b9d9243cf7c/shell/platform/darwin/macos/framework/Source/FlutterExternalTextureGL.mm#L62
  func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
    copyPixelCount += 1
    var pixelBuffer: CVPixelBuffer?
    objc_sync_enter(textureId)
    pixelBuffer = latestPixelBuffer
    objc_sync_exit(textureId)

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

    objc_sync_enter(textureId)
    latestPixelBuffer = newBuffer
    objc_sync_exit(textureId)

    // Inform the Flutter Texture Registry that a texture frame is available to draw.
    registry.textureFrameAvailable(textureId)

  }

  func onCaptureFrame(frame: AVCapture.AVCaptureVideoFrame?) {
    if frame != nil {
    }
  }

  func onCapturePixelBuffer(_ pixelBuffer: CVPixelBuffer?) {
    if pixelBuffer != nil {
      captureSample(pixelBuffer)
    }
  }

  /*
  func copyFrameToTexture(
    width: Int, height: Int, pixelFormatType: OSType, linesize: Int,
    data: UnsafeMutablePointer<UInt8>, shouldSwapRedBlue: Bool = false
  ) {
    var data = captureFrames(
      width: width, height: height, pixelFormatType: pixelFormatType, linesize: linesize, data: data
    )
    var upscaleImage = false
    var upscaleImageData: UnsafeMutablePointer<UInt8>? = nil
    // If pixel format is 2vuy
    if pixelFormatType == kCVPixelFormatType_422YpCbCr8 {
      upscaleImage = true
      upscaleImageData = upscaleImage(
        width: width, height: height, pixelFormatType: pixelFormatType, linesize: linesize,
        data: data)
      if let upscaleImageData = upscaleImageData {
        data = upscaleImageData
        linesize = width * 4
        pixelFormatType = kCVPixelFormatType_32ARGB
      }
    }

    if shouldSwapRedBlue {
      data = swapBlueRedColors(data: data, count: linesize * height)
    }
    var pxbuffer: CVPixelBuffer?
    let attributes: [String: Any] = [
      kCVPixelBufferPixelFormatTypeKey as String: pixelFormatType,
      kCVPixelBufferOpenGLCompatibilityKey as String: true,
      kCVPixelBufferMetalCompatibilityKey as String: true,
    ]
    let status = CVPixelBufferCreate(
      kCFAllocatorDefault,
      width,
      height,
      pixelFormatType,
      attributes as CFDictionary,
      &pxbuffer)
    if status != kCVReturnSuccess {
      print("copyFrameToTexture: Operation failed")
      return
    }
    CVPixelBufferLockBaseAddress(pxbuffer!, [])
    let copyBaseAddress = CVPixelBufferGetBaseAddress(pxbuffer!)
    memcpy(copyBaseAddress, dataToUse, linesize * height)
    CVPixelBufferUnlockBaseAddress(pxbuffer!, [])
    if shouldSwapRedBlue {
      dataToUse.deallocate()
    }

    captureSample(pxbuffer!)

    if upscaleImage, let upscaleImageData = upscaleImageData {
      free(upscaleImageData)
    }
  }
     */
}
