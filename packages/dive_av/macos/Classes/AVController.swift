// Copyright (c) 2024 Larry Aasen. All rights reserved.

import AVFoundation
import FlutterMacOS

@available(macOS 13.0, *)
class AVController {
  var callbacks: AVCallbacks?

  init(callbacks: AVCallbacks) {
    self.callbacks = callbacks
  }

  // TODO: maybe rename objectId to sourceId???

  private var avObjects: [String: AVObject] = [:]

  /// Creates an audio source and returns the source ID.
  public func createAudioSource(deviceUniqueID: String) throws -> String {
    let captureInfo = AVCapture.AVCaptureInfo(uniqueID: deviceUniqueID, useAudio: true)
    let avCapture = try AVCapture(captureInfo: captureInfo)
    let sourceId = avCapture.objectId
    avObjects[sourceId] = avCapture

    avCapture.captureInfo?.audioBufferCallback = { [self] magnitude in
      processAudioBuffer(sourceId, magnitude, avCapture)
    }

    return sourceId
  }

  public func createVideoSource(deviceUniqueID: String, textureId: Int64? = nil) throws -> String {
    let captureInfo = AVCapture.AVCaptureInfo(uniqueID: deviceUniqueID, useVideo: true)
    let avCapture = try AVCapture(captureInfo: captureInfo)
    avObjects[avCapture.objectId] = avCapture

    if let textureId, textureId != 0 {
      if let provider = _textureProviders[textureId] {
        avCapture.captureInfo?.pixelBufferCallback = { [self] pixelBuffer in
          convertPixelBuffer(pixelBuffer, provider, avCapture)
        }
      } else {
        print("createVideoSource: unknown textureProvider")
      }
    } else {
      print("createVideoSource: unknown textureId=$textureId")
    }
    return avCapture.objectId
  }

  func convertPixelBuffer(
    _ pixelBuffer: CVPixelBuffer?, _ provider: TextureProvider, _ avCapture: AVCapture
  ) {
    if let pixelBuffer {
      let convertedPixelBuffer = avCapture.convert(pixelBuffer: pixelBuffer)
      provider.onCapturePixelBuffer(convertedPixelBuffer)
    } else {
      provider.onCapturePixelBuffer(nil)
    }
  }

  func processAudioBuffer(_ sourceId: String, _ magnitude: [Float], _ avCapture: AVCapture) {
    guard let callbacks else { return }
    callbacks.volMeterCallback(
      sourceId: sourceId, magnitude: magnitude, peak: [], inputPeak: [])
  }

  public func removeSource(objectId: String) -> Bool {
    if let avObject = avObjects.removeValue(forKey: objectId) {
      if let avObject = avObject as? AVCapture {
        // Swtich to an empty device that will just stop this session.
        let _ = avObject.switchCaptureDevice("")
      }
      return true
    }
    return false
  }

  public func initializeTexture(textureRegistry: FlutterTextureRegistry) -> Int64 {
    let provider = TextureProvider(registry: textureRegistry)
    let textureId = provider.register()
    if textureId != 0 {
      _saveTextureProvider(provider)
    }
    return textureId
  }

  public func disposeTexture(textureRegistry: FlutterTextureRegistry, textureId: Int64) -> Bool {
    if let provider = _textureProviders[textureId] {
      _removeTextureProvider(provider)
      textureRegistry.unregisterTexture(textureId)
      return true
    }

    return false
  }

  public func inputsFromType(mediaType: AVMediaType, typeId: String) -> [[String: String]] {
    var inputs: [[String: String]] = []
    let devices =
      mediaType == .video
      ? AVInputs.inputsFromVideoType() : mediaType == .audio ? AVInputs.inputsFromAudioType() : []
    for device in devices {
      if device.hasMediaType(mediaType) {
        print("dive_av: \(device.localizedName): \(device.uniqueID)")
        inputs.append([
          "uniqueID": device.uniqueID, "localizedName": device.localizedName, "typeId": typeId,
        ])
      }
    }

    return inputs
  }

  /// Map of all texture providers where the key is a source UUID and the value is a texture provider pointer
  private var _textureProviders: [Int64: TextureProvider] = [:]

  private func _saveTextureProvider(_ textureProvider: TextureProvider) {
    guard textureProvider.textureId != 0 else {
      print("_saveTextureProvider: missing textureProvider.textureId")
      return
    }

    let provider = _textureProviders[textureProvider.textureId]
    if provider != nil {
      print("_saveTextureProvider: duplicate texture provider: \(textureProvider.textureId)")
      return
    }
    _textureProviders[textureProvider.textureId] = textureProvider
  }

  private func _removeTextureProvider(_ textureProvider: TextureProvider) {
    guard textureProvider.textureId != 0 else {
      print("_removeTextureProvider: missing textureProvider.textureId")
      return
    }

    let provider = _textureProviders[textureProvider.textureId]
    if provider == nil {
      print("_removeTextureProvider: unknown texture provider: \(textureProvider.textureId)")
      return
    }

    _textureProviders.removeValue(forKey: textureProvider.textureId)
  }
}
