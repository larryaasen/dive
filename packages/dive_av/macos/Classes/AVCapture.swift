// Copyright (c) 2024 Larry Aasen. All rights reserved.

import AVFoundation
import CoreMedia
import CoreMediaIO
import CoreVideo
import Foundation
import IOSurface

@available(macOS 13.0, *)
class AVCapture: NSObject, AVCaptureAudioDataOutputSampleBufferDelegate,
  AVCaptureVideoDataOutputSampleBufferDelegate, AVObject
{
  var objectId: String = UUID().uuidString

  var captureInfo: AVCaptureInfo?
  var videoInfo: AVCaptureVideoInfo?
  var obsFrame: Data?
  var obsAudioFrame: Data?
  var deviceUUID: String?
  //  var presetFormat: OBSAVCapturePresetInfo?
  var session: AVCaptureSession?
  var deviceInput: AVCaptureDeviceInput?
  var videoOutput: AVCaptureVideoDataOutput?
  var audioOutput: AVCaptureAudioDataOutput?
  var videoQueue: DispatchQueue?
  var audioQueue: DispatchQueue?
  var sessionQueue: DispatchQueue?
  var isDeviceLocked = false
  var isPresetBased = false
  private(set) var isFastPath = false
  private(set) var errorDomain: String?

  var deviceConnectedObserver: NSObjectProtocol?
  var deviceDisconnectedObserver: NSObjectProtocol?

  private var _dropFrameCount = 0
  private var _frameCount = 0

  convenience override init() {
    self.init(captureInfo: nil)
  }

  // Initialize.
  init(captureInfo capture_info: AVCaptureInfo?) {
    super.init()

    enableDALdevices()

    let devices = AVInputs.inputsFromType()
    for device in devices {
      if device.hasMediaType(.video) {
        //        print("\(device.localizedName): \(device.uniqueID)")
      }
    }

    errorDomain = "com.dive.diveavplugin.avcapture"
    sessionQueue = DispatchQueue(label: "session queue")

    videoInfo = AVCaptureVideoInfo(
      colorSpace: .csDefault, videoRange: .rangeDefault, isValid: false)

    let notificationCenter = Foundation.NotificationCenter.default
    let mainQueue = OperationQueue.main

    deviceDisconnectedObserver = notificationCenter.addObserver(
      forName: .AVCaptureDeviceWasDisconnected,
      object: nil,
      queue: mainQueue, using: deviceDisconnected)

    deviceConnectedObserver = notificationCenter.addObserver(
      forName: .AVCaptureDeviceWasDisconnected,
      object: nil,
      queue: mainQueue, using: deviceConnected)

    captureInfo = capture_info
    if let captureInfo {
      let anUUID = captureInfo.uniqueID
      let presetName = "bbb"  // OBSAVCapture.string(fromSettings: captureInfo.settings, withSetting: "preset")
      let isPresetEnabled = false  // obs_data_get_bool(captureInfo.settings, "use_preset")

      if captureInfo.isFastPath {
        isFastPath = true
        isPresetBased = false
      } else {
        //        let isBufferingEnabled = obs_data_get_bool(captureInfo.settings, "buffering")

        //        obs_source_set_async_unbuffered(captureInfo.source, !isBufferingEnabled)
      }

      weak var weakSelf = self

      sessionQueue?.async {
        if let instance = weakSelf {
          if instance.createSession() {
            if instance.switchCaptureDevice(anUUID) {
              var isSessionConfigured = false

              if isPresetEnabled {
                //                isSessionConfigured = instance.configureSession(withPreset: presetName)
              } else {
                isSessionConfigured = instance.configureSession()
              }
              if isSessionConfigured {
                if instance.startCaptureSession() {
                } else {
                  print("Could not start the session")
                }
              } else {
                print("Session not configured")
              }
            }

          } else {
            print("Could not create a session")
          }
        }
      }
    }
  }

  deinit {
    let notificationCenter = Foundation.NotificationCenter.default
    if let deviceDisconnectedObserver = deviceDisconnectedObserver {
      notificationCenter.removeObserver(deviceDisconnectedObserver)

    }
    if let deviceConnectedObserver = deviceConnectedObserver {
      notificationCenter.removeObserver(deviceConnectedObserver)
    }
  }

  private func enableDALdevices() {
    //  The first thing we have to do in-order to be able to start capture is to find the device
    // of interest, if we are interested in screen capture ( for example capturing the screen of
    // an attached iOS device ) we need to enable CoreMediaIO ‘DAL’ plug-ins.
    var property = CMIOObjectPropertyAddress(
      mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyAllowScreenCaptureDevices),
      mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
      mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMaster))
    var allow: UInt32 = 1
    let dataSize: UInt32 = UInt32(MemoryLayout.size(ofValue: allow))
    CMIOObjectSetPropertyData(
      CMIOObjectID(kCMIOObjectSystemObject), &property, 0, nil, dataSize, &allow)
  }

  // Create a session.
  func createSession() -> Bool {
    let session = AVCaptureSession()
    session.beginConfiguration()

    let videoOutput = AVCaptureVideoDataOutput()
    let audioOutput = AVCaptureAudioDataOutput()
    let videoQueue = DispatchQueue(label: "video")
    let audioQueue = DispatchQueue(label: "audio")

    if session.canAddOutput(videoOutput) {
      session.addOutput(videoOutput)
      videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
    }

    if session.canAddOutput(audioOutput) {
      session.addOutput(audioOutput)
      audioOutput.setSampleBufferDelegate(self, queue: audioQueue)
    }

    session.commitConfiguration()

    self.session = session
    self.videoOutput = videoOutput
    self.videoQueue = videoQueue
    self.audioOutput = audioOutput
    self.audioQueue = audioQueue

    return true
  }

  /// Switches to the device with the given unique ID.
  /// - Parameter uniqueID: The unique ID of the device instance to be used.
  /// - Returns: True when successful.
  func switchCaptureDevice(_ uniqueID: String) -> Bool {
    guard let session else {
      print("No session created")
      return false
    }
    guard let videoOutput else { return false }

    let device = AVCaptureDevice(uniqueID: uniqueID)

    if deviceInput != nil || device == nil {
      stopCaptureSession()

      if let deviceInput {
        session.removeInput(deviceInput)
        deviceInput.device.unlockForConfiguration()
      }
      deviceInput = nil
      isDeviceLocked = false
    }

    guard let device else {
      if !uniqueID.isEmpty {
        print("No device selected")
      } else {
        print("Unable to initialize device with unique ID \(uniqueID)")
      }
      return false
    }

    //    let deviceName = device.localizedName.utf8CString as? UnsafePointer<Int8>
    //    obs_data_set_string(captureInfo.settings, "device_name", deviceName)``
    //    obs_data_set_string(captureInfo.settings, "device", device.uniqueID.utf8CString)
    print("Selected device \(device.localizedName)")

    deviceUUID = device.uniqueID

    let isAudioSupported = device.hasMediaType(.audio) || device.hasMediaType(.muxed)

    //    obs_source_set_audio_active(captureInfo.source, isAudioSupported)

    var deviceInput: AVCaptureDeviceInput?
    do {
      deviceInput = try AVCaptureDeviceInput(device: device)
    } catch {
      print("Cannot create capture device input")
      return false
    }
    guard let deviceInput else { return false }

    if device.isPortraitEffectActive {
      print("Portrait effect is active on selected device")
    }
    if device.isCenterStageActive {
      print("Center Stage effect is active on selected device")
    }
    if device.isStudioLightActive {
      print("Studio Light effect is active on selected device")
    }

    session.beginConfiguration()

    if session.canAddInput(deviceInput) {
      session.addInput(deviceInput)
      self.deviceInput = deviceInput
    } else {
      session.commitConfiguration()
      return false
    }

    let deviceFormat = device.activeFormat

    let mediaType = CMFormatDescriptionGetMediaType(deviceFormat.formatDescription)

    if mediaType != kCMMediaType_Video && mediaType != kCMMediaType_Muxed {
      session.removeInput(deviceInput)
      session.commitConfiguration()
      return false
    }

    if isFastPath {
      videoOutput.videoSettings = nil

      var videoSettings = videoOutput.videoSettings

      let targetPixelFormatType = FourCharCode(kCVPixelFormatType_32BGRA)

      videoSettings?[kCVPixelBufferPixelFormatTypeKey as String] = NSNumber(
        value: targetPixelFormatType)

      videoOutput.videoSettings = videoSettings
    } else {
      videoOutput.videoSettings = nil

      let subType = FourCharCode(
        (videoOutput.videoSettings?[kCVPixelBufferPixelFormatTypeKey as String] as? NSNumber)?
          .uint32Value ?? 0)

      if AVCapture.format(fromSubtype: subType) != .none {
        print("Using native fourcc \(subType)")
      } else {
        print("Using fallback fourcc '\(kCVPixelFormatType_32BGRA))' \(subType) unsupported)")

        var videoSettings = videoOutput.videoSettings

        videoSettings?[kCVPixelBufferPixelFormatTypeKey as String] = NSNumber(
          value: kCVPixelFormatType_32BGRA)

        videoOutput.videoSettings = videoSettings
      }

    }

    session.commitConfiguration()

    return true
  }

  func startCaptureSession() -> Bool {
    guard let session else {
      return false
    }
    if !session.isRunning {
      session.startRunning()
    }
    return true
  }

  func stopCaptureSession() {
    guard let session else {
      return
    }
    if session.isRunning {
      session.stopRunning()
    }
    if let captureInfo {
      if captureInfo.isFastPath {
        if let currentSurface = captureInfo.currentSurface {
          IOSurfaceDecrementUseCount(currentSurface)
          self.captureInfo?.currentSurface = nil
        }
        if let previousSurface = captureInfo.previousSurface {
          IOSurfaceDecrementUseCount(previousSurface)
          self.captureInfo?.previousSurface = nil
        }
      } else {
        outputFrame(nil)
      }
    }
  }

  func configureSession(withPreset preset: AVCaptureSession.Preset) throws -> Bool {
    guard let device = deviceInput?.device else {
      print("Unable to set session preset without capture device")
      return false
    }

    guard device.supportsSessionPreset(preset) else {
      print("Preset \(preset.rawValue) not supported by device \(device.localizedName)")
      return false
    }
    guard let session else {
        print("No session")
        return false
    }

    if session.canSetSessionPreset(preset) {
      if isDeviceLocked {
        if preset.rawValue == session.sessionPreset.rawValue {
          if let deviceInput {
            //            deviceInput.device.activeFormat = presetFormat.activeFormat
            //            deviceInput.device.activeVideoMinFrameDuration = presetFormat.minFrameRate
            //            deviceInput.device.activeVideoMaxFrameDuration = presetFormat.maxFrameRate
          }
          //          presetFormat = nil
        }
        deviceInput?.device.unlockForConfiguration()
        isDeviceLocked = false
      }
      session.sessionPreset = preset
    } else {
      print("Preset \(preset.rawValue) not supported by capture session")
      return false
    }

    isPresetBased = true
    return true
  }

  func configureSession() -> Bool {
    /*
    var videoRange: AVCaptureVideoRange
    var colorSpace: Int
    var inputFourCC: FourCharCode

    if !self.isFastPath {
      videoRange = .rangeDefault  // Int(obs_data_get_int(self.captureInfo.settings, "video_range"))
      if !isValidVideoRange(videoRange) {
        print("Unsupported video range: \(videoRange)")
        return false
      }
      var inputFormat: Int
      inputFormat = Int(obs_data_get_int(self.captureInfo.settings, "input_format"))
      inputFourCC = OBSAVCapture.fourCharCodeFromFormat(inputFormat, withRange: videoRange)
      colorSpace = Int(obs_data_get_int(self.captureInfo.settings, "color_space"))
      if !OBSAVCapture.isValidColorspace(colorSpace) {
        self.AVCaptureLog(LOG_DEBUG, withFormat: "Unsupported color space: %d", colorSpace)
        return false
      }
    } else {
      let formatDescription = self.deviceInput.device.activeFormat.formatDescription
      inputFourCC = CMFormatDescriptionGetMediaSubType(formatDescription)
      colorSpace = OBSAVCapture.colorspaceFromDescription(formatDescription)
      videoRange =
        isFullRangeFormat(inputFourCC) ? VIDEO_RANGE_FULL : VIDEO_RANGE_PARTIAL
    }
    let dimensions = OBSAVCapture.dimensionsFromSettings(self.captureInfo.settings)
    if dimensions.width == 0 || dimensions.height == 0 {
      self.AVCaptureLog(LOG_DEBUG, withFormat: "No valid resolution found in settings")
      return false
    }
    var fps = media_frames_per_second()
    if !obs_data_get_frames_per_second(self.captureInfo.settings, "frame_rate", &fps, nil) {
      self.AVCaptureLog(LOG_DEBUG, withFormat: "No valid framerate found in settings")
      return false
    }
    let time = CMTime(value: fps.denominator, timescale: fps.numerator, flags: 1)
    var format: AVCaptureDeviceFormat? = nil
    for formatCandidate in self.deviceInput.device.formats.reversed() {
      let formatDimensions = CMVideoFormatDescriptionGetDimensions(
        formatCandidate.formatDescription)
      if !(formatDimensions.width == dimensions.width)
        || !(formatDimensions.height == dimensions.height)
      {
        continue
      }
      for range in formatCandidate.videoSupportedFrameRateRanges {
        if CMTimeCompare(range.maxFrameDuration, time) >= 0
          && CMTimeCompare(range.minFrameDuration, time) <= 0
        {
          let formatDescription = formatCandidate.formatDescription
          let formatFourCC = CMFormatDescriptionGetMediaSubType(formatDescription)
          if inputFourCC == formatFourCC {
            format = formatCandidate
            inputFourCC = formatFourCC
            break
          }
        }
      }
      if format != nil {
        break
      }
    }
    if format == nil {
      self.AVCaptureLog(
        LOG_WARNING, withFormat: "Frame rate is not supported: %g FPS (%u/%u)",
        media_frames_per_second_to_fps(fps), fps.numerator, fps.denominator)
      return false
    }
    self.session.beginConfiguration()
    self.isDeviceLocked = self.deviceInput.device.lockForConfiguration(&error)
    if !self.isDeviceLocked {
      self.AVCaptureLog(LOG_WARNING, withFormat: "Could not lock devie for configuration")
      return false
    }
    self.AVCaptureLog(
      LOG_INFO,
      withFormat:
        "Capturing '%@' (%@):\n Resolution : %ux%u\n FPS : %g (%u/%u)\n Frame Interval : %g\u{00a0}s\n Input Format : %@\n Requested Color Space : %@ (%d)\n Requested Video Range : %@ (%d)\n Using Format : %@",
      self.deviceInput.device.localizedName, self.deviceInput.device.uniqueID, dimensions.width,
      dimensions.height, media_frames_per_second_to_fps(fps), fps.numerator, fps.denominator,
      media_frames_per_second_to_frame_interval(fps), OBSAVCapture.stringFromSubType(inputFourCC),
      OBSAVCapture.stringFromColorspace(colorSpace), colorSpace,
      OBSAVCapture.stringFromVideoRange(videoRange), videoRange, format!.description)

    if let videoInfo {
      self.videoInfo = AVCaptureVideoInfo(
        colorSpace: videoInfo.colorSpace, videoRange: videoInfo.videoRange, isValid: false)
    }
    self.isPresetBased = false
    if self.presetFormat == nil {
      let presetInfo = OBSAVCapturePresetInfo()
      presetInfo.activeFormat = self.deviceInput.device.activeFormat
      presetInfo.minFrameRate = self.deviceInput.device.activeVideoMinFrameDuration
      presetInfo.maxFrameRate = self.deviceInput.device.activeVideoMaxFrameDuration
      self.presetFormat = presetInfo
    }
    self.deviceInput.device.activeFormat = format!
    self.deviceInput.device.activeVideoMinFrameDuration = time
    self.deviceInput.device.activeVideoMaxFrameDuration = time
    self.session.commitConfiguration()
    */

    return true
  }

  // MARK: - Notification Handlers

  func deviceConnected(_ notification: Notification?) {
    guard let device = notification?.object as? AVCaptureDevice else {
      return
    }

    if !device.uniqueID.isEqual(deviceUUID) {
      //      obs_source_update_properties(captureInfo.source)
      return
    }

    if let device = deviceInput?.device {
      print(
        "Received connect event with active device '\(device.localizedName)' (UUID \(device.uniqueID)"
      )

      //      obs_source_update_properties(captureInfo.source)
      return
    }

    print("Received connect event for device '\(device.localizedName)' (UUID \(device.uniqueID)")

    /*
    var error: Error?
    let presetName = OBSAVCapture.string(fromSettings: captureInfo.settings, withSetting: "preset")
    let isPresetEnabled = obs_data_get_bool(captureInfo.settings, "use_preset")
    let isFastPath = captureInfo.isFastPath
    if switchCaptureDevice(device.uniqueID, withError: &error) {
      var success: Bool
      if isPresetEnabled && !isFastPath {
        success = configureSession(withPreset: presetName, withError: &error)
      } else {
        success = configureSession(&error)
      }
      if success {
        sessionQueue.async(execute: { [self] in
          startCaptureSession()
        })
      } else {
        avCaptureLog(LOG_ERROR, withFormat: error.localizedDescription)
      }
    } else {
      avCaptureLog(LOG_ERROR, withFormat: error.localizedDescription)
    }
       */
    //    obs_source_update_properties(captureInfo.source)
  }

  func deviceDisconnected(_ notification: Notification?) {
    let device = notification?.object as? AVCaptureDevice
    if device == nil {
      return
    }

    /*
    if !(device?.uniqueID.isEqual(to: deviceUUID) ?? false) {
      obs_source_update_properties(captureInfo.source)
      return
    }
    if !deviceInput.device {
      avCaptureLog(
        LOG_ERROR,
        withFormat: "Received disconnect event for inactive device '%@' (UUID %@)",
        device.localizedName, device.uniqueID)
      obs_source_update_properties(captureInfo.source)
      return
    }
    avCaptureLog(
      LOG_INFO,
      withFormat: "Received disconnect event for device '%@' (UUID %@)", device.localizedName,
      device.uniqueID)

    weak var weakSelf = self
    sessionQueue.async(execute: {
      var instance = weakSelf

      instance?.stopSession()
      if let deviceInput = instance?.deviceInput {
        instance?.session.removeInput(deviceInput)
      }

      instance?.deviceInput = nil
      instance = nil
    })
      */

    //    obs_source_update_properties(captureInfo.source)
  }

  // MARK: - AVCapture Delegate Methods (begin)

  /// Called once for each frame that is discarded.
  func captureOutput(
    _ output: AVCaptureOutput,
    didDrop sampleBuffer: CMSampleBuffer,
    from connection: AVCaptureConnection
  ) {
    _dropFrameCount += 1
    print("Did drop video frame \(_dropFrameCount)")
    return
  }

  /// Called whenever an AVCaptureVideoDataOutput instance outputs a new video frame.
  func captureOutput(
    _ output: AVCaptureOutput,
    didOutput sampleBuffer: CMSampleBuffer,
    from connection: AVCaptureConnection
  ) {
    guard var videoInfo else { return }
    let sampleCount = CMSampleBufferGetNumSamples(sampleBuffer)
    if captureInfo == nil || Int(sampleCount) < 1 {
      return
    }

    let presentationTimeStamp = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer)
    let presentationNanoTimeStamp: CMTime = CMTimeConvertScale(
      presentationTimeStamp, timescale: Int32(1E9), method: .default)

    guard let description = CMSampleBufferGetFormatDescription(sampleBuffer) else {
      return
    }
    let mediaType = CMFormatDescriptionGetMediaType(description)

    switch mediaType {
    case kCMMediaType_Video:
      _frameCount += 1
      print("video frame \(_frameCount)")
      let sampleBufferDimensions = CMVideoFormatDescriptionGetDimensions(description)
      let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
      let mediaSubType = CMFormatDescriptionGetMediaSubType(description)

      var newInfo = AVCaptureVideoInfo(
        colorSpace: videoInfo.colorSpace, videoRange: videoInfo.videoRange, isValid: false)
      let usePreset = false  // obs_data_get_bool(captureInfo.settings, "use_preset")

      if isFastPath {
        if mediaSubType != kCVPixelFormatType_32BGRA
          && mediaSubType != kCVPixelFormatType_ARGB2101010LEPacked
        {
          //          captureInfo.lastError() = OBSAVCaptureError_SampleBufferFormat
          if let sampleBufferDescription = captureInfo?.sampleBufferDescription {
            CMFormatDescriptionCreate(
              allocator: kCFAllocatorDefault,
              mediaType: mediaType,
              mediaSubType: mediaSubType,
              extensions: nil,
              formatDescriptionOut: &captureInfo!.sampleBufferDescription)
          }
          //          obs_source_update_properties(captureInfo.source)
          break
        } else {
          //          captureInfo.lastError() = OBSAVCaptureError_NoError
          captureInfo?.sampleBufferDescription = nil
        }

        /*
        CVPixelBufferLockBaseAddress(imageBuffer, [])
        let frameSurface = CVPixelBufferGetIOSurface(imageBuffer) as? IOSurfaceRef
        CVPixelBufferUnlockBaseAddress(imageBuffer, [])

        let previousSurface: IOSurfaceRef? = nil

        if frameSurface && !pthread_mutex_lock(0x0) {
          var frameSize = captureInfo.frameSize

          if frameSize.size.width != sampleBufferDimensions.width
            || frameSize.size.height != sampleBufferDimensions.height
          {
            frameSize = CGRect(
              x: 0, y: 0, width: sampleBufferDimensions.width, height: sampleBufferDimensions.height
            )
          }
          previousSurface = captureInfo.currentSurface
          captureInfo.currentSurface = frameSurface

          CFRetain(captureInfo.currentSurface)
          IOSurfaceIncrementUseCount(captureInfo.currentSurface)
          pthread_mutex_unlock(0x0)

          newInfo.isValid = true

          if videoInfo.isValid != newInfo.isValid {
            obs_source_update_properties(captureInfo.source)
          }

          captureInfo.frameSize = frameSize
          videoInfo = newInfo
        }

        if previousSurface {
          IOSurfaceDecrementUseCount(previousSurface)
        }
        */

        break
      } else {
        guard var frame = captureInfo?.videoFrame else {
          break
        }

        frame.timestamp = UInt64(presentationNanoTimeStamp.value)

        let videoFormat = AVCapture.format(fromSubtype: mediaSubType)

        if videoFormat == AVVideoFormat.none {
          //          captureInfo.lastError() = OBSAVCaptureError_SampleBufferFormat
          if let sampleBufferDescription = captureInfo?.sampleBufferDescription {
            CMFormatDescriptionCreate(
              allocator: kCFAllocatorDefault,
              mediaType: mediaType,
              mediaSubType: mediaSubType,
              extensions: nil,
              formatDescriptionOut: &captureInfo!.sampleBufferDescription)
          }
        } else {

          //          captureInfo.lastError() = OBSAVCaptureError_NoError
          captureInfo?.sampleBufferDescription = nil
          #if DEBUG
            if frame.format != AVVideoFormat.none && frame.format != videoFormat {
              print("Switching fourcc")  //: '%@' (0x%x) -> '%@' (0x%x)",
              //                OBSAVCapture.string(fromFourCharCode: frame.format), frame.format,
              //                OBSAVCapture.string(fromFourCharCode: mediaSubType), mediaSubType)
            }
          #endif
          let isFrameYuv = formatIsYUV(frame.format)
          let isSampleBufferYuv = formatIsYUV(videoFormat)

          frame.format = videoFormat
          frame.width = sampleBufferDimensions.width
          frame.height = sampleBufferDimensions.height

          var isSampleBufferFullRange = isFullRangeFormat(pixelFormat: mediaSubType)

          if isSampleBufferYuv {
            var sampleBufferColorSpace = colorspaceFrom(description: description)
            let sampleBufferRangeType =
              isSampleBufferFullRange
              ? AVCaptureVideoRange.rangeFull
              : AVCaptureVideoRange.rangePartial

            var isColorSpaceMatching = false

            let configuredColorSpace = AVCaptureVideoColorspace.csDefault  // obs_data_get_int(captureInfo.settings, "color_space")

            if usePreset {
              isColorSpaceMatching = sampleBufferColorSpace == videoInfo.colorSpace
            } else {
              isColorSpaceMatching = configuredColorSpace == videoInfo.colorSpace
            }

            var isVideoRangeMatching = false
            let configuredVideoRangeType = AVCaptureVideoRange.rangeDefault  // obs_data_get_int(captureInfo.settings, "video_range")

            if usePreset {
              isVideoRangeMatching = sampleBufferRangeType == videoInfo.videoRange
            } else {
              isVideoRangeMatching = configuredVideoRangeType == videoInfo.videoRange
              isSampleBufferFullRange = configuredVideoRangeType == AVCaptureVideoRange.rangeFull
            }

            if isColorSpaceMatching && isVideoRangeMatching {
              newInfo.isValid = true
            } else {
              frame.fullRange = isSampleBufferFullRange

              let success = videoFormatGetParametersForFormat(
                colorSpace: &sampleBufferColorSpace,
                range: sampleBufferRangeType,
                format: frame.format,
                matrix: &frame.colorMatrix,
                rangeMin: &frame.colorRangeMin,
                rangeMax: &frame.colorRangeMax)

              if !success {
                if let sampleBufferDescription = captureInfo?.sampleBufferDescription {
                  CMFormatDescriptionCreate(
                    allocator: kCFAllocatorDefault,
                    mediaType: mediaType,
                    mediaSubType: mediaSubType,
                    extensions: nil,
                    formatDescriptionOut: &captureInfo!.sampleBufferDescription)
                }
                newInfo.isValid = false
              } else {
                newInfo.colorSpace = sampleBufferColorSpace
                newInfo.videoRange = sampleBufferRangeType
                newInfo.isValid = true
              }
            }
          } else if !isFrameYuv && !isSampleBufferYuv {
            newInfo.isValid = true
          }

          if newInfo.isValid != videoInfo.isValid {
            //            obs_source_update_properties(captureInfo.source)
          }

          videoInfo = newInfo

          if newInfo.isValid {
            if let imageBuffer {
              CVPixelBufferLockBaseAddress(imageBuffer, .readOnly)

              if !CVPixelBufferIsPlanar(imageBuffer) {
                frame.linesize[0] = UInt32(CVPixelBufferGetBytesPerRow(imageBuffer))
                if let buffer = CVPixelBufferGetBaseAddress(imageBuffer) {
                  // Save the image buffer
                  frame.data[0] = buffer
                }
              } else {
                let planeCount = CVPixelBufferGetPlaneCount(imageBuffer)

                for i in 0..<planeCount {
                  frame.linesize[i] = UInt32(CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, i))
                  if let buffer = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, i) {
                    frame.data[i] = buffer
                  }
                }
              }

              outputFrame(frame)
              CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly)
            }
          } else {
            outputFrame(nil)
          }

          break

        }
      }

      break

    case kCMMediaType_Audio:
      var requiredBufferListSize: size_t
      var status = noErr

      /*
      status = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(
        sampleBuffer,
        bufferListSizeNeededOut: &requiredBufferListSize,
        bufferListOut: nil,
        bufferListSize: 0,
        blockBufferAllocator: nil,
        blockBufferMemoryAllocator: nil,
        flags: kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment)
      if status != noErr {
        captureInfo.lastAudioError = OBSAVCaptureError_AudioBuffer
        obs_source_update_properties(captureInfo.source)
        break
      }

      let bufferList = malloc(requiredBufferListSize) as? AudioBufferList
      let blockBuffer: CMBlockBuffer? = nil
      var error = noErr
      error = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(
        sampleBuffer,
        bufferListSizeNeededOut: nil,
        bufferListOut: &bufferList,
        bufferListSize: requiredBufferListSize,
        blockBufferAllocator: kCFAllocatorSystemDefault,
        blockBufferMemoryAllocator: kCFAllocatorSystemDefault,
        flags: kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment,
        blockBufferOut: &blockBuffer)

      if error == noErr {
        captureInfo.lastAudioError = OBSAVCaptureError_NoError

        let audio = captureInfo.audioFrame

        for i in 0..<Int(bufferList.mNumberBuffers) {
          audio?.data[i] = bufferList.mBuffers[i].mData
        }

        audio?.timestamp = presentationNanoTimeStamp.value
        audio?.frames = UInt32(CMSampleBufferGetNumSamples(sampleBuffer))

        let basicDescription =
          CMAudioFormatDescriptionGetStreamBasicDescription(description)
          as? AudioStreamBasicDescription

        audio.samples_per_sec = UInt32(basicDescription?.mSampleRate ?? 0)
        audio.speakers = speaker_layout(rawValue: basicDescription?.mChannelsPerFrame)

        switch basicDescription.mBitsPerChannel {
        case 8:
          audio.format = AudioFormat.u8bit  // AUDIO_FORMAT_U8BIT
        case 16:
          audio.format = AudioFormat.s16bit  // AUDIO_FORMAT_16BIT
        case 32:
          audio.format = AudioFormat.s32bit  // AUDIO_FORMAT_32BIT
        default:
          audio.format = AudioFormat.unknown  // AUDIO_FORMAT_UNKNOWN
        }

        //        obs_source_output_audio(captureInfo.source, audio)
      } else {
        //        captureInfo.lastAudioError = OBSAVCaptureError_AudioBuffer
        //        obs_source_output_audio(captureInfo.source, nil)
      }
         */
      break
    default:
      break
    }

  }

  // MARK: - AVCapture Delegate Methods (end)

  class func format(fromSubtype subtype: FourCharCode) -> AVVideoFormat {
    switch subtype {
    case FourCharCode(kCVPixelFormatType_422YpCbCr8):
      return .uyvy
    case FourCharCode(kCVPixelFormatType_422YpCbCr8_yuvs):
      return .yuy2
    case FourCharCode(kCVPixelFormatType_32BGRA):
      return .bgra
    case FourCharCode(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange),
      FourCharCode(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange):
      return .nv12
    case FourCharCode(kCVPixelFormatType_420YpCbCr10BiPlanarFullRange),
      FourCharCode(kCVPixelFormatType_420YpCbCr10BiPlanarVideoRange):
      return .p010
    default:
      return .none
    }
  }

  func colorspaceFrom(description: CMFormatDescription) -> AVCaptureVideoColorspace {
    guard
      let matrix = CMFormatDescriptionGetExtension(
        description, extensionKey: kCMFormatDescriptionExtension_YCbCrMatrix
      )
    else {
      return .csDefault
    }

    let is601 = CFStringCompare(
      (matrix as! CFString), kCVImageBufferYCbCrMatrix_ITU_R_601_4,
      CFStringCompareFlags(rawValue: 0))
    let is709 = CFStringCompare(
      (matrix as! CFString), kCVImageBufferYCbCrMatrix_ITU_R_709_2,
      CFStringCompareFlags(rawValue: 0))
    let is2020 = CFStringCompare(
      (matrix as! CFString), kCVImageBufferYCbCrMatrix_ITU_R_2020, CFStringCompareFlags(rawValue: 0)
    )

    if is601 == CFComparisonResult.compareEqualTo {
      return .cs601
    } else if is709 == CFComparisonResult.compareEqualTo {
      return .cs709
    } else if is2020 == CFComparisonResult.compareEqualTo {
      guard
        let transferFunction = CMFormatDescriptionGetExtension(
          description, extensionKey: kCMFormatDescriptionExtension_TransferFunction)
      else {
        return .csDefault
      }

      let isPQ = CFStringCompare(
        (transferFunction as! CFString), kCVImageBufferTransferFunction_SMPTE_ST_2084_PQ,
        CFStringCompareFlags(rawValue: 0))
      let isHLG = CFStringCompare(
        (transferFunction as! CFString), kCVImageBufferTransferFunction_ITU_R_2100_HLG,
        CFStringCompareFlags(rawValue: 0))

      if isPQ == CFComparisonResult.compareEqualTo {
        return .cs2100PQ
      } else if isHLG == CFComparisonResult.compareEqualTo {
        return .cs2100HLG
      }

    }
    return .csDefault
  }

  func outputFrame(_ frame: AVCaptureVideoFrame?) {
    if let captureInfo, let callback = captureInfo.frameCallback {
      callback(frame)
    }
  }

  func videoFormatGetParametersForFormat(
    colorSpace: inout AVCaptureVideoColorspace,
    range: AVCaptureVideoRange,
    format: AVVideoFormat,
    matrix: inout [Float],
    rangeMin: inout [Float],
    rangeMax: inout [Float]
  ) -> Bool {
    var bpc: UInt32
    switch format {
    case .i010, .p010, .i210, .v210, .r10L:
      bpc = 10
    case .i412, .ya2L:
      bpc = 12
    case .p216, .p416:
      bpc = 16
    default:
      bpc = 8
    }
    return videoFormatGetParametersForBpc(
      colorSpace: &colorSpace, range: range, matrix: &matrix, rangeMin: &rangeMin,
      rangeMax: &rangeMax, bpc: &bpc)
  }

  struct BppInfo {
    var rangeMin: [Float]
    var rangeMax: [Float]
    var blackLevels: [[Float]]
    var floatRangeMin: [Float]
    var floatRangeMax: [Float]
  }

  let bppInfo = [BppInfo](
    repeating: BppInfo(
      rangeMin: [Float](repeating: 0.0, count: 3),
      rangeMax: [Float](repeating: 0.0, count: 3),
      blackLevels: [[Float]](repeating: [Float](repeating: 0.0, count: 3), count: 2),
      floatRangeMin: [Float](repeating: 0.0, count: 3),
      floatRangeMax: [Float](repeating: 0.0, count: 3)), count: 9)

  var matricesInitialized = false

  func videoFormatGetParametersForBpc(
    colorSpace: inout AVCaptureVideoColorspace, range: AVCaptureVideoRange,
    matrix: inout [Float], rangeMin: inout [Float], rangeMax: inout [Float], bpc: inout UInt32
  ) -> Bool {

    //        return false

    if !matricesInitialized {
      //            initializeMatrices()
      matricesInitialized = true
    }

    switch colorSpace {
    case .csDefault, .csRGB:
      colorSpace = .cs709
    case .cs2100HLG:
      colorSpace = .cs2100PQ
    default:
      break
    }

    bpc = bpc < 8 ? 8 : bpc > 16 ? 16 : bpc
    let bpcIndex = Int(bpc - 8)
    assert(bpcIndex < bppInfo.count)

    let success = false
    //        for format in formatInfo {
    //            if format.colorSpace == colorSpace {
    //                success = true
    //                let fullRange = range == .full
    //                let selectedMatrix = format.matrix[bpcIndex][fullRange ? 1 : 0]
    //                matrix = Array(selectedMatrix[0..<16])
    //
    //                if !rangeMin.isEmpty {
    //                    let srcRangeMin = fullRange ? fullMin : bppInfo[bpcIndex].floatRangeMin
    //                    rangeMin = Array(srcRangeMin[0..<3])
    //                }
    //
    //                if !rangeMax.isEmpty {
    //                    let srcRangeMax = fullRange ? fullMax : bppInfo[bpcIndex].floatRangeMax
    //                    rangeMax = Array(srcRangeMax[0..<3])
    //                }
    //
    //                break
    //            }
    //        }

    return success
  }

  enum AVAudioFormat {
    case unknown
    case u8bit
    case s16bit
    case s32bit
    case float
    case u8bitPlanar
    case s16bitPlanar
    case s32bitPlanar
    case floatPlanar
  }

  enum AVCaptureVideoColorspace {
    case csDefault
    case cs601
    case cs709
    case csRGB
    case cs2100PQ
    case cs2100HLG
  }

  enum AVCaptureVideoRange {
    case rangeDefault
    case rangePartial
    case rangeFull
  }

  struct AVCaptureVideoInfo {
    var colorSpace: AVCaptureVideoColorspace
    var videoRange: AVCaptureVideoRange
    var isValid: Bool
  }

  func isValidVideoRange(_ videoRange: AVCaptureVideoRange) -> Bool {
    switch videoRange {
    case .rangeDefault, .rangePartial, .rangeFull:
      return true
    }
  }

  func isFullRangeFormat(pixelFormat: FourCharCode) -> Bool {
    switch pixelFormat {
    case kCVPixelFormatType_420YpCbCr8PlanarFullRange,
      kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
      kCVPixelFormatType_420YpCbCr10BiPlanarFullRange,
      kCVPixelFormatType_422YpCbCr8FullRange:
      return true
    default:
      return false
    }
  }

  enum AVVideoFormat: Int {
    case none
    // planar 4:2:0 formats
    case i420  // three-plane
    case nv12  // two-plane, luma and packed chroma
    // packed 4:2:2 formats
    case yvyu
    case yuy2  // YUYV
    case uyvy
    // packed uncompressed formats
    case rgba
    case bgra
    case bgrx
    case y800  // grayscale
    // planar 4:4:4
    case i444
    // more packed uncompressed formats
    case bgr3
    // planar 4:2:2
    case i422
    // planar 4:2:0 with alpha
    case i40A
    // planar 4:2:2 with alpha
    case i42A
    // planar 4:4:4 with alpha
    case yuva
    // packed 4:4:4 with alpha
    case ayuv
    // planar 4:2:0 format, 10 bpp
    case i010  // three-plane
    case p010  // two-plane, luma and packed chroma
    // planar 4:2:2 format, 10 bpp
    case i210
    // planar 4:4:4 format, 12 bpp
    case i412
    // planar 4:4:4:4 format, 12 bpp
    case ya2L
    // planar 4:2:2 format, 16 bpp
    case p216  // two-plane, luma and packed chroma
    // planar 4:4:4 format, 16 bpp
    case p416  // two-plane, luma and packed chroma
    // packed 4:2:2 format, 10 bpp
    case v210
    // packed uncompressed 10-bit format
    case r10L
  }

  // enum VideoFormat {
  //   case i420, nv12, i422, i210, yvyu, yuy2, uyvy, i444, i412, i40a, i42a, yuva, ya2l, ayuv, i010,
  //     p010, p216, p416, v210
  //   case none, rgba, bgra, bgrx, y800, bgr3, r10l
  // }

  func formatIsYUV(_ format: AVVideoFormat) -> Bool {
    switch format {
    case .i420, .nv12, .i422, .i210, .yvyu, .yuy2, .uyvy, .i444, .i412, .i40A, .i42A, .yuva, .ya2L,
      .ayuv, .i010, .p010, .p216, .p416, .v210:
      return true
    case .none, .rgba, .bgra, .bgrx, .y800, .bgr3, .r10L:
      return false
    }
  }

  struct AVCaptureInfo {
    var capture: Any?
    var uniqueID: String
    var previousSurface: IOSurfaceRef?
    var currentSurface: IOSurfaceRef?
    //    var texture: OBSAVCaptureTexture?
    //    var effect: OBSAVCaptureEffect?
    var videoFrame: AVCaptureVideoFrame = AVCaptureVideoFrame()
    //    var audioFrame: OBSAVCaptureAudioFrame?
    var frameSize: NSRect = NSRect.zero
    var mutex: pthread_mutex_t?
    var settings: UnsafeMutableRawPointer?
    var source: UnsafeMutableRawPointer?
    var isFastPath: Bool = false
    var lastError: String?
    var sampleBufferDescription: CMFormatDescription?
    var lastAudioError: String?
    var frameCallback: ((_ frame: AVCaptureVideoFrame?) -> Void)? = nil
  }

  public struct AVCaptureVideoFrame {
    var data = [UnsafeMutableRawPointer?](
      repeating: UnsafeMutablePointer(nil), count: MAX_AV_PLANES)
    var linesize = [UInt32](repeating: 0, count: MAX_AV_PLANES)
    var width: Int32 = 0
    var height: Int32 = 0
    var timestamp: UInt64 = 0
    var format: AVVideoFormat = AVVideoFormat.none
    var colorMatrix = [Float](repeating: 0, count: 16)
    var fullRange: Bool = false
    var maxLuminance: UInt16 = 0
    var colorRangeMin = [Float](repeating: 0, count: 3)
    var colorRangeMax = [Float](repeating: 0, count: 3)
    var flip: Bool = false
    var flags: UInt8 = 0
    var trc = AVVideoTRC.VIDEO_TRC_DEFAULT
    var prevFrame: Bool = false
  }

  enum AVVideoTRC: Int {
    case VIDEO_TRC_DEFAULT
    case VIDEO_TRC_SRGB
    case VIDEO_TRC_PQ
    case VIDEO_TRC_HLG
  }

  static let MAX_AV_PLANES: Int = 8
}

class AVInputs {
  static func inputsFromType() -> [AVCaptureDevice] {
    #if os(iOS)
      let session = AVCaptureDevice.DiscoverySession(
        deviceTypes: [
          .builtInWideAngleCamera,
          .builtInTelephotoCamera,
        ],
        mediaType: .video,
        position: .unspecified)
      return session.devices
    #elseif os(macOS)
      if #available(macOS 15.0, *) {
        let session = AVCaptureDevice.DiscoverySession(
          deviceTypes: [
            .builtInWideAngleCamera
          ],
          mediaType: .video,
          position: .unspecified)
        return session.devices
      } else {
        return AVCaptureDevice.devices(for: .video)
      }
    #endif
  }

  /// Returns all microphones on the device.
  static public func getListOfMicrophones() -> [AVCaptureDevice] {
    if #available(macOS 15.0, *) {
      let session = AVCaptureDevice.DiscoverySession(
        deviceTypes: [
          .builtInMicrophone
        ],
        mediaType: .audio,
        position: .unspecified)

      return session.devices
    } else {
      return AVCaptureDevice.devices(for: .audio)
    }
  }
}
