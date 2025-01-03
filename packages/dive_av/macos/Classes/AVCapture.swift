// Copyright (c) 2024 Larry Aasen. All rights reserved.

import AVFoundation
import Accelerate
import CoreAudio
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

    enum ParameterError: Error {
        case invalidParameter(reason: String)
    }

    override init() {
        print("Do not use this initializer.")
    }

    // Designated initializer.
    init(captureInfo: AVCaptureInfo) throws {
        if !captureInfo.useAudio && !captureInfo.useVideo {
            throw ParameterError.invalidParameter(
                reason: "captureInfo must use audio or video")
        }
        super.init()

        enableDALdevices()

        errorDomain = "com.dive.diveavplugin.avcapture"
        sessionQueue = DispatchQueue(label: "session queue")

        if captureInfo.useVideo {
            videoInfo = AVCaptureVideoInfo(
                colorSpace: .csDefault, videoRange: .rangeDefault,
                isValid: false)
        }

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

        self.captureInfo = captureInfo

        let anUUID = captureInfo.uniqueID
        //      let presetName = "bbb"  // OBSAVCapture.string(fromSettings: captureInfo.settings, withSetting: "preset")
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
                    } else {
                        print("Could not setup the session")
                    }

                } else {
                    print("Could not create a session")
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

    /// The first thing we have to do to be able to start capture is to find the device
    /// of interest, if we are interested in screen capture ( for example capturing the screen of
    /// an attached iOS device ) we need to enable CoreMediaIO ‘DAL’ plug-ins.
    private func enableDALdevices() {
        var property = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(
                kCMIOHardwarePropertyAllowScreenCaptureDevices),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain))
        var allow: UInt32 = 1
        let dataSize: UInt32 = UInt32(MemoryLayout.size(ofValue: allow))
        CMIOObjectSetPropertyData(
            CMIOObjectID(kCMIOObjectSystemObject), &property, 0, nil, dataSize,
            &allow)
    }

    // Create a session.
    func createSession() -> Bool {
        let session = AVCaptureSession()
        session.beginConfiguration()

        if captureInfo?.useVideo == true {
            let videoOutput = AVCaptureVideoDataOutput()
            let videoQueue = DispatchQueue(label: "video")
            if session.canAddOutput(videoOutput) {
                session.addOutput(videoOutput)
                videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
                self.videoOutput = videoOutput
                self.videoQueue = videoQueue
            }
        }
        let audioOutput = AVCaptureAudioDataOutput()
        let audioQueue = DispatchQueue(label: "audio")

        if session.canAddOutput(audioOutput) {
            session.addOutput(audioOutput)
            audioOutput.setSampleBufferDelegate(self, queue: audioQueue)
        }

        session.commitConfiguration()

        self.session = session
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
            if uniqueID.isEmpty {
                print("dive_av: No device selected")
            } else {
                print(
                    "dive_av: Unable to initialize device with unique ID \(uniqueID)"
                )
            }
            return false
        }

        //    if captureInfo?.useVideo == true {
        //      guard let videoOutput else { return false }
        //    }

        //    let deviceName = device.localizedName.utf8CString as? UnsafePointer<Int8>
        //    obs_data_set_string(captureInfo.settings, "device_name", deviceName)``
        //    obs_data_set_string(captureInfo.settings, "device", device.uniqueID.utf8CString)
        print("dive_av: Selected device \(device.localizedName)")

        deviceUUID = device.uniqueID

        //    let isAudioSupported = device.hasMediaType(.audio) || device.hasMediaType(.muxed)

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

            //      print(deviceInput.set.keys)
            //      print(videoSettings.values)

        } else {
            session.commitConfiguration()
            return false
        }

        let deviceFormat = device.activeFormat

        let mediaType = CMFormatDescriptionGetMediaType(
            deviceFormat.formatDescription)

        if mediaType == kCMMediaType_Muxed {
            print("media type is muxed")
        } else if mediaType == kCMMediaType_Audio {
            print("media type has audio")
        } else if mediaType == kCMMediaType_Video {
            print("media type has video")
        }

        if captureInfo?.useVideo == true {
            if mediaType != kCMMediaType_Video
                && mediaType != kCMMediaType_Muxed
            {
                session.removeInput(deviceInput)
                session.commitConfiguration()
                return false
            }
        }

        if isFastPath {
            if captureInfo?.useVideo == true, let videoOutput = videoOutput {
                videoOutput.videoSettings = nil

                var videoSettings = videoOutput.videoSettings

                let targetPixelFormatType = FourCharCode(
                    kCVPixelFormatType_32BGRA)

                videoSettings?[kCVPixelBufferPixelFormatTypeKey as String] =
                    NSNumber(
                        value: targetPixelFormatType)

                videoOutput.videoSettings = videoSettings
            }
        } else {
            if captureInfo?.useVideo == true, let videoOutput = videoOutput {
                videoOutput.videoSettings = nil

                let subType = FourCharCode(
                    (videoOutput.videoSettings?[
                        kCVPixelBufferPixelFormatTypeKey as String] as? NSNumber)?
                        .uint32Value ?? 0)

                if AVCapture.format(fromSubtype: subType) != .none {
                    if subType == kCVPixelFormatType_422YpCbCr8 {
                        print(
                            "dive_av: Using native fourcc kCVPixelFormatType_422YpCbCr8"
                        )
                    } else {
                        print("dive_av: Using native fourcc \(subType)")
                    }
                } else {
                    let fallbackType = kCVPixelFormatType_32ARGB
                    print(
                        "dive_av: Using fallback fourcc '\(fallbackType))' \(subType) unsupported)"
                    )

                    var videoSettings = videoOutput.videoSettings

                    videoSettings?[kCVPixelBufferPixelFormatTypeKey as String] =
                        NSNumber(
                            value: fallbackType)

                    videoOutput.videoSettings = videoSettings
                }
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
                outputPixelBuffer(nil)
            }
        }
    }

    func configureSession(withPreset preset: AVCaptureSession.Preset) throws
        -> Bool
    {
        guard let device = deviceInput?.device else {
            print("Unable to set session preset without capture device")
            return false
        }

        guard device.supportsSessionPreset(preset) else {
            print(
                "Preset \(preset.rawValue) not supported by device \(device.localizedName)"
            )
            return false
        }
        guard let session else {
            print("No session")
            return false
        }

        if session.canSetSessionPreset(preset) {
            if isDeviceLocked {
                if preset.rawValue == session.sessionPreset.rawValue {
                    //          if let deviceInput {
                    //            deviceInput.device.activeFormat = presetFormat.activeFormat
                    //            deviceInput.device.activeVideoMinFrameDuration = presetFormat.minFrameRate
                    //            deviceInput.device.activeVideoMaxFrameDuration = presetFormat.maxFrameRate
                    //          }
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

        if let device = deviceInput?.device {
            print(
                "Received connect event with active device '\(device.localizedName)' \(device.uniqueID)"
            )

            //      obs_source_update_properties(captureInfo.source)
            return
        }

        print(
            "Received connect event for device '\(device.localizedName)' \(device.uniqueID)"
        )

        if !device.uniqueID.isEqual(deviceUUID) {
            //      obs_source_update_properties(captureInfo.source)
            return
        }

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
        guard let device = notification?.object as? AVCaptureDevice else {
            return
        }

        if let deviceConnected = deviceInput?.device {
            print(
                "Received disconnect event for inactive device '\(deviceConnected.localizedName)' \(deviceConnected.uniqueID)"
            )
            //      obs_source_update_properties(captureInfo.source)
            return
        }

        print(
            "Received disconnect event for device '\(device.localizedName)' \(device.uniqueID)"
        )

        /*
         if !(device?.uniqueID.isEqual(to: deviceUUID) ?? false) {
         obs_source_update_properties(captureInfo.source)
         return
         }

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

    /// Called whenever a video frame is dropped.
    func captureOutput(
        _ output: AVCaptureOutput,
        didDrop sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        _dropFrameCount += 1
        print("Did drop video frame \(_dropFrameCount)")
        return
    }

    var noMore = false

    /// Called whenever an AVCaptureVideoDataOutput instance outputs a new video frame.
    /// Called whenever an AVCaptureAudioDataOutput instance outputs a new audio sample buffer.
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        if noMore { return }
        guard let captureInfo = captureInfo else {
            return
        }

        //    guard let captureInfo else { return }
        let sampleCount = CMSampleBufferGetNumSamples(sampleBuffer)
        guard sampleCount > 0 else { return }

        //    let presentationTimeStamp = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer)
        //    let presentationNanoTimeStamp: CMTime = CMTimeConvertScale(
        //      presentationTimeStamp, timescale: Int32(1E9), method: .default)

        guard let description = CMSampleBufferGetFormatDescription(sampleBuffer)
        else { return }
        let mediaType = CMFormatDescriptionGetMediaType(description)

        switch mediaType {
        case kCMMediaType_Video:
            _frameCount += 1
            //      let sampleBufferDimensions = CMVideoFormatDescriptionGetDimensions(description)
            //      let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
            let pixelBuffer: CVPixelBuffer? = CMSampleBufferGetImageBuffer(
                sampleBuffer)
            outputPixelBuffer(pixelBuffer)
            return

        /*
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
             */

        case kCMMediaType_Audio:
            let audioFrame = captureInfo.audioFrame

            // Handle audio sample buffer
            var audioBufferListSizeNeeded: Int = 0
            var blockBuffer: CMBlockBuffer?

            // First call to get the required buffer size
            var status =
                CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(
                    sampleBuffer,
                    bufferListSizeNeededOut: &audioBufferListSizeNeeded,
                    bufferListOut: nil,
                    bufferListSize: 0,
                    blockBufferAllocator: nil,
                    blockBufferMemoryAllocator: nil,
                    flags:
                        kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment,
                    blockBufferOut: nil
                )

            guard status == noErr else {
                let error = CMSampleBufferError(status: status)
                print("Unable to get required buffer size: \(error.message)")
                return
            }

            // Allocate the required buffer size
            let audioBufferList = UnsafeMutablePointer<AudioBufferList>
                .allocate(
                    capacity: audioBufferListSizeNeeded)
            defer {
                audioBufferList.deallocate()
            }

            // Second call to get the actual audio buffer list
            status = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(
                sampleBuffer,
                bufferListSizeNeededOut: nil,
                bufferListOut: audioBufferList,
                bufferListSize: audioBufferListSizeNeeded,
                blockBufferAllocator: kCFAllocatorSystemDefault,
                blockBufferMemoryAllocator: kCFAllocatorSystemDefault,
                flags:
                    kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment,
                blockBufferOut: &blockBuffer
            )

            guard status == noErr else {
                let error = CMSampleBufferError(status: status)
                print("Unable to get audio sample buffer: \(error.message)")
                return
            }

            guard
                let basicDescription =
                    CMAudioFormatDescriptionGetStreamBasicDescription(
                        description)?
                    .pointee
            else { return }

            audioFrame.sampleRate = basicDescription.mSampleRate
            audioFrame.channelsPerFrame = basicDescription.mChannelsPerFrame
            audioFrame.bitsPerChannel = basicDescription.mBitsPerChannel
            audioFrame.format = convertCAFormat(
                formatFlags: basicDescription.mFormatFlags,
                bits: basicDescription.mBitsPerChannel)

//            printAudioFormatFlags(basicDescription.mFormatFlags)

            // Process the audio buffer list
            let audioBufferListPointer = UnsafeMutableAudioBufferListPointer(
                audioBufferList)
            var bufferIndex = -1
            for audioBuffer in audioBufferListPointer {
                bufferIndex += 1
                if bufferIndex == AVCapture.MAX_AV_PLANES {
                    if !audioFrame.channelCountError {
                        print(
                            "Channels Per Frame (\(audioFrame.channelsPerFrame)) is greater than MAX_AV_PLANES (\(AVCapture.MAX_AV_PLANES))"
                        )
                    }
                    audioFrame.channelCountError = true
                    break
                }

                let sampleCount = Int(audioBuffer.mDataByteSize) / 4  // 4 bytes per 24-bit sample in 32-bit space
                let samples = UnsafeBufferPointer(
                    start: audioBuffer.mData?.assumingMemoryBound(
                        to: UInt32.self), count: sampleCount)
                
                /// Convert to dB.
                func toDb(value: Float) -> Float {
                    let dB = value > 0 ? 20 * log10(value) : -60.0
                    return dB
                }

                // Helper function to calculate the average power in dB for all 24-bit samples stored in 4-byte integers
                func calculateAveragePowerInDB(samples: [UInt32]) -> Float {
                    guard !samples.isEmpty else { return -Float.infinity }

                    // Sum of squares for RMS calculation
                    var sumOfSquares: Float = 0.0
                    var sumOfAmps: Float = 0.0

                    for sample in samples {
//                        if sample == 0 {
//                            print("zer")
//                        }

                        // Extract the lower 24 bits and treat as a signed 24-bit integer
                        let lower24Bits = sample & 0x00FF_FFFF

                        // Convert to a signed 24-bit integer by checking if the 24th bit is set
                        let amplitude: Float
                        if (lower24Bits & 0x0080_0000) != 0 {  // If the 24th bit is set, it's negative
                            amplitude =
                                Float(Int32(lower24Bits) - (1 << 24))
                                / Float(1 << 23)
                        } else {
                            amplitude =
                                Float(Int32(lower24Bits)) / Float(1 << 23)
                        }

                        // Add squared normalized amplitude to sum of squares
                        sumOfSquares += amplitude * amplitude
                        
                        sumOfAmps += amplitude
                    }

                    // Calculate RMS over the entire buffer
                    let rms = sqrt(sumOfSquares / Float(samples.count))
                    
                    let avg = sumOfAmps / Float(samples.count)

                    // Convert RMS to dB
//                    let dB = toDb(value: rms)
                    let dB = toDb(value: avg)

                    return dB
                }

                // Calculate the average dB power level for the entire buffer
                let averagePowerInDB = calculateAveragePowerInDB(
                    samples: Array(samples))

                audioFrame.movingAverage[bufferIndex] = averagePowerInDB
            }

            if let callback = captureInfo.audioBufferCallback {
                callback(audioFrame.movingAverage)
            }

            break
        default:
            break
        }
    }

    /// Handle your audio data here
    private func processAudioData(
        _ audioData: Data, formatDescription: CMFormatDescription
    ) {

        let movingAverage = movingAverageFilter(audioData)

        if let captureInfo, let callback = captureInfo.audioBufferCallback {
            callback([movingAverage])
        }
    }

    // Perform a moving average filter on the audio data.
    private func movingAverageFilter(_ audioData: Data) -> Float {
        if audioData.count == 0 { return 0.0 }

        var total = 0
        audioData.forEach { value in
            if value != 0 {
                let valueInt = Int(value)
                if valueInt != 0 {
                    total += valueInt
                }
            }
        }
        let average = Float(total) / Float(audioData.count)
        return average
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

    func colorspaceFrom(description: CMFormatDescription)
        -> AVCaptureVideoColorspace
    {
        guard
            let matrix = CMFormatDescriptionGetExtension(
                description,
                extensionKey: kCMFormatDescriptionExtension_YCbCrMatrix
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
            (matrix as! CFString), kCVImageBufferYCbCrMatrix_ITU_R_2020,
            CFStringCompareFlags(rawValue: 0)
        )

        if is601 == CFComparisonResult.compareEqualTo {
            return .cs601
        } else if is709 == CFComparisonResult.compareEqualTo {
            return .cs709
        } else if is2020 == CFComparisonResult.compareEqualTo {
            guard
                let transferFunction = CMFormatDescriptionGetExtension(
                    description,
                    extensionKey: kCMFormatDescriptionExtension_TransferFunction
                )
            else {
                return .csDefault
            }

            let isPQ = CFStringCompare(
                (transferFunction as! CFString),
                kCVImageBufferTransferFunction_SMPTE_ST_2084_PQ,
                CFStringCompareFlags(rawValue: 0))
            let isHLG = CFStringCompare(
                (transferFunction as! CFString),
                kCVImageBufferTransferFunction_ITU_R_2100_HLG,
                CFStringCompareFlags(rawValue: 0))

            if isPQ == CFComparisonResult.compareEqualTo {
                return .cs2100PQ
            } else if isHLG == CFComparisonResult.compareEqualTo {
                return .cs2100HLG
            }

        }
        return .csDefault
    }

    //  func outputFrame(_ frame: AVCaptureVideoFrame?) {
    //    if let captureInfo, let callback = captureInfo.frameCallback {
    //      callback(frame)
    //    }
    //  }

    func outputPixelBuffer(_ pixelBuffer: CVPixelBuffer?) {
        if let captureInfo, let callback = captureInfo.pixelBufferCallback {
            callback(pixelBuffer)
        }
    }

    /// Convert pixelBuffer to a pixelBuffer with format type kCVPixelFormatType_32ARGB.
    func convert(pixelBuffer: CVPixelBuffer) -> CVPixelBuffer? {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        guard var data = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            return nil
        }

        let shouldSwapRedBlue = false

        var formatType = CVPixelBufferGetPixelFormatType(pixelBuffer)
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        var linesize = CVPixelBufferGetBytesPerRow(pixelBuffer)
        var upscaleImageData: UnsafeMutableRawPointer?

        // If pixel format is 2vuy
        if formatType == kCVPixelFormatType_422YpCbCr8 {
            upscaleImageData = upscaleImage(
                width: width, height: height, pixelFormatType: formatType,
                linesize: linesize, data: data)
            if let upscaleImageData {
                data = upscaleImageData
                linesize = width * 4
                formatType = kCVPixelFormatType_32ARGB
            }

        } else {
            print("AVCapture.convert: unkown format type: \(formatType)")
            assert(
                false, "AVCapture.convert: unkown format type: \(formatType)")
            return nil
        }

        if CVPixelBufferIsPlanar(pixelBuffer) {
            //              let planeCount = CVPixelBufferGetPlaneCount(imageBuffer)
            //
            //              for i in 0..<planeCount {
            //                frame.linesize[i] = UInt32(CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, i))
            //                if let buffer = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, i) {
            //                  frame.data[i] = buffer
            //                }
            //              }
        } else {
            // Save the image buffer

            if shouldSwapRedBlue {
                //           data = swap_blue_red_colors(data, linesize*height);
            }

            var pxbuffer: CVPixelBuffer? = nil
            let attributes =
                [
                    kCVPixelBufferPixelFormatTypeKey as String: Int(formatType),
                    kCVPixelBufferOpenGLCompatibilityKey as String: true,
                    kCVPixelBufferMetalCompatibilityKey as String: true,
                ] as [String: Any]

            let status = CVPixelBufferCreate(
                kCFAllocatorDefault,
                width,
                height,
                formatType,
                attributes as CFDictionary,
                &pxbuffer)
            if status != kCVReturnSuccess || pxbuffer == nil {
                print("AVCapture.convert: CVPixelBufferCreate operation failed")
                return nil
            }

            CVPixelBufferLockBaseAddress(
                pxbuffer!, CVPixelBufferLockFlags(rawValue: 0))
            defer {
                CVPixelBufferUnlockBaseAddress(
                    pxbuffer!, CVPixelBufferLockFlags(rawValue: 0))
            }

            guard let copyBaseAddress = CVPixelBufferGetBaseAddress(pxbuffer!)
            else {
                print("Error: could not get pixel buffer base address")
                return nil
            }

            memcpy(copyBaseAddress, data, linesize * height)

            if shouldSwapRedBlue {
                // free(data)
            }

            if let upscaleImageData {
                free(upscaleImageData)
            }

            return pxbuffer

        }

        return nil
    }

    var conversionInfo = vImage_YpCbCrToARGB()
    var conversionInfoAvailable = false

    func upscaleImage(
        width: Int, height: Int, pixelFormatType: OSType, linesize: Int,
        data: UnsafeMutableRawPointer
    ) -> UnsafeMutableRawPointer? {
        if !conversionInfoAvailable {
            var pixelRange = vImage_YpCbCrPixelRange(
                Yp_bias: 16, CbCr_bias: 128, YpRangeMax: 235, CbCrRangeMax: 240,
                YpMax: 255, YpMin: 0,
                CbCrMax: 255, CbCrMin: 1)  // video range 8-bit, unclamped
            // let pixelRange = vImage_YpCbCrPixelRange(Yp_bias: 16, CbCr_bias: 128, YpRangeMax: 235, CbCrRangeMax: 240, YpMax: 235, YpMin: 16, CbCrMax: 240, CbCrMin: 16) // video range 8-bit, clamped to video range
            // let pixelRange = vImage_YpCbCrPixelRange(Yp_bias: 0, CbCr_bias: 128, YpRangeMax: 255, CbCrRangeMax: 255, YpMax: 255, YpMin: 1, CbCrMax: 255, CbCrMin: 0) // full range 8-bit, clamped to full range
            let convertError = vImageConvert_YpCbCrToARGB_GenerateConversion(
                kvImage_YpCbCrToARGBMatrix_ITU_R_709_2,
                &pixelRange,
                &conversionInfo,
                kvImage422YpCbYpCr8,
                kvImageARGB8888,
                vImage_Flags(kvImagePrintDiagnosticsToConsole))
            conversionInfoAvailable = convertError == kvImageNoError
        }

        var upscaleImageData: UnsafeMutableRawPointer? = nil

        if conversionInfoAvailable {
            var src = vImage_Buffer(
                data: data, height: vImagePixelCount(height),
                width: vImagePixelCount(width),
                rowBytes: linesize)
            upscaleImageData = UnsafeMutableRawPointer.allocate(
                byteCount: width * height * 4,
                alignment: MemoryLayout<UInt8>.alignment)
            var dest = vImage_Buffer(
                data: upscaleImageData, height: vImagePixelCount(height),
                width: vImagePixelCount(width),
                rowBytes: width * 4)
            let permuteMap: [UInt8] = [3, 2, 1, 0]
            let alpha: UInt8 = 255
            let flags = vImage_Flags(kvImagePrintDiagnosticsToConsole)

            let imageError = vImageConvert_422CbYpCrYp8ToARGB8888(
                &src, &dest, &conversionInfo, permuteMap, alpha, flags)

            if imageError != kvImageNoError {
                print("image convert error: \(imageError)")
                upscaleImageData?.deallocate()
                upscaleImageData = nil
            }
        }

        return upscaleImageData
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
            colorSpace: &colorSpace, range: range, matrix: &matrix,
            rangeMin: &rangeMin,
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
            blackLevels: [[Float]](
                repeating: [Float](repeating: 0.0, count: 3), count: 2),
            floatRangeMin: [Float](repeating: 0.0, count: 3),
            floatRangeMax: [Float](repeating: 0.0, count: 3)), count: 9)

    var matricesInitialized = false

    func videoFormatGetParametersForBpc(
        colorSpace: inout AVCaptureVideoColorspace, range: AVCaptureVideoRange,
        matrix: inout [Float], rangeMin: inout [Float], rangeMax: inout [Float],
        bpc: inout UInt32
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
        case .i420, .nv12, .i422, .i210, .yvyu, .yuy2, .uyvy, .i444, .i412,
            .i40A, .i42A, .yuva, .ya2L,
            .ayuv, .i010, .p010, .p216, .p416, .v210:
            return true
        case .none, .rgba, .bgra, .bgrx, .y800, .bgr3, .r10L:
            return false
        }
    }

    public class AVCaptureInfo {
        var capture: Any?
        let uniqueID: String
        var previousSurface: IOSurfaceRef?
        var currentSurface: IOSurfaceRef?
        //    var texture: OBSAVCaptureTexture?
        //    var effect: OBSAVCaptureEffect?
        var videoFrame: AVCaptureVideoFrame = AVCaptureVideoFrame()
        var audioFrame: AVCaptureAudioFrame = AVCaptureAudioFrame()
        var frameSize: NSRect = NSRect.zero
        var mutex: pthread_mutex_t?
        var settings: UnsafeMutableRawPointer?
        var source: UnsafeMutableRawPointer?
        var isFastPath: Bool = false
        var lastError: String?
        var sampleBufferDescription: CMFormatDescription?
        var lastAudioError: String?
        //    var frameCallback: ((_ frame: AVCaptureVideoFrame?) -> Void)? = nil
        var audioBufferCallback: ((_ magnitude: [Float]) -> Void)? = nil
        var pixelBufferCallback: ((_ frame: CVPixelBuffer?) -> Void)? = nil

        var useAudio: Bool = false
        var useVideo: Bool = false

        init(uniqueID: String, useAudio: Bool = false, useVideo: Bool = false) {
            self.uniqueID = uniqueID
            self.useAudio = useAudio
            self.useVideo = useVideo
        }
    }

    public class AVCaptureAudioFrame {
        /// Audio data planes
        /// - Note: Using UnsafePointer to match C-style array of pointers
        var data: [UnsafePointer<UInt8>?]

        var movingAverage: [Float]

        /// Number of audio frames
        var frames: UInt32

        /// Sampling rate. The number of frames per second of the data in the stream, when playing the stream at normal speed.
        var sampleRate: Float64

        /// The number of channels in each frame of audio data.
        var channelsPerFrame: UInt32

        /// The number of bits for one audio sample.
        var bitsPerChannel: UInt32

        var format: DiveAVAudioFormat

        /// Timestamp for the audio data
        var timestamp: UInt64

        var channelCountError: Bool

        /// Initializer with default values
        init(
            data: [UnsafePointer<UInt8>?] = Array(
                repeating: nil, count: MAX_AV_PLANES),
            movingAverage: [Float] = Array(
                repeating: 0.0, count: MAX_AV_PLANES),
            frames: UInt32 = 0,
            sampleRate: Float64 = 44100,
            channelsPerFrame: UInt32 = 1,
            bitsPerChannel: UInt32 = 0,
            format: DiveAVAudioFormat = .unknown,
            timestamp: UInt64 = 0,
            channelCountError: Bool = false
        ) {
            self.data = data
            self.movingAverage = movingAverage
            self.frames = frames
            self.sampleRate = sampleRate
            self.channelsPerFrame = channelsPerFrame
            self.bitsPerChannel = bitsPerChannel
            self.format = format
            self.timestamp = timestamp
            self.channelCountError = channelCountError
        }
    }

    enum SpeakerLayout {
        case mono
        case stereo
        case quad
        case surround5_1
        case surround7_1
    }

    public class AVCaptureVideoFrame {
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

    static let MAX_AV_PLANES: Int = 10

    // First, assuming you have an enum for audio_format defined like this:
    enum DiveAVAudioFormat {
        case unknown
        case float
        case floatPlanar
        case u8bit
        case u8bitPlanar
        case bit16
        case bit16Planar
        case bit32
        case bit32Planar
    }

    // Then the converted function:
    func convertCAFormat(formatFlags: UInt32, bits: UInt32) -> DiveAVAudioFormat
    {
        let planar = (formatFlags & kAudioFormatFlagIsNonInterleaved) != 0

        if (formatFlags & kAudioFormatFlagIsFloat) != 0 {
            return planar ? .floatPlanar : .float
        }

        if (formatFlags & kAudioFormatFlagIsSignedInteger) == 0 && bits == 8 {
            return planar ? .u8bitPlanar : .u8bit
        }

        // not float? not signed int? no clue, fail
        if (formatFlags & kAudioFormatFlagIsSignedInteger) == 0 {
            return .unknown
        }

        if bits == 16 {
            return planar ? .bit16Planar : .bit16
        } else if bits == 32 {
            return planar ? .bit32Planar : .bit32
        }

        return .unknown
    }

    @available(*, deprecated)
    func printAudioFormatFlags(_ formatFlags: UInt32) {
        var flagsSet: [String] = []

        print("AudioFormatFlags values:")
        func flagName(_ formatFlags: UInt32, _ flag: UInt32, _ flagName: String)
            -> String
        {
            print("\(flagName): \(String(format: "%08X", flag))")
            return (formatFlags & flag != 0) ? flagName : ""
        }

        flagsSet.append(
            flagName(
                formatFlags, kAudioFormatFlagIsFloat, "kAudioFormatFlagIsFloat")
        )
        flagsSet.append(
            flagName(
                formatFlags, kAudioFormatFlagIsBigEndian,
                "kAudioFormatFlagIsBigEndian"))
        flagsSet.append(
            flagName(
                formatFlags, kAudioFormatFlagIsSignedInteger,
                "kAudioFormatFlagIsSignedInteger"))
        flagsSet.append(
            flagName(
                formatFlags, kAudioFormatFlagIsPacked,
                "kAudioFormatFlagIsPacked"))
        flagsSet.append(
            flagName(
                formatFlags, kAudioFormatFlagIsAlignedHigh,
                "kAudioFormatFlagIsAlignedHigh"))
        flagsSet.append(
            flagName(
                formatFlags, kAudioFormatFlagIsNonInterleaved,
                "kAudioFormatFlagIsNonInterleaved"))
        flagsSet.append(
            flagName(
                formatFlags, kAudioFormatFlagIsNonMixable,
                "kAudioFormatFlagIsNonMixable"))
        flagsSet.append(
            flagName(
                formatFlags, kAudioFormatFlagsAreAllClear,
                "kAudioFormatFlagsAreAllClear"))
        flagsSet.append(
            flagName(
                formatFlags, kLinearPCMFormatFlagIsFloat,
                "kLinearPCMFormatFlagIsFloat"))
        flagsSet.append(
            flagName(
                formatFlags, kLinearPCMFormatFlagIsBigEndian,
                "kLinearPCMFormatFlagIsBigEndian"))
        flagsSet.append(
            flagName(
                formatFlags, kLinearPCMFormatFlagIsSignedInteger,
                "kLinearPCMFormatFlagIsSignedInteger"))
        flagsSet.append(
            flagName(
                formatFlags, kLinearPCMFormatFlagIsPacked,
                "kLinearPCMFormatFlagIsPacked"))
        flagsSet.append(
            flagName(
                formatFlags, kLinearPCMFormatFlagIsAlignedHigh,
                "kLinearPCMFormatFlagIsAlignedHigh"))
        flagsSet.append(
            flagName(
                formatFlags, kLinearPCMFormatFlagIsNonInterleaved,
                "kLinearPCMFormatFlagIsNonInterleaved"))
        flagsSet.append(
            flagName(
                formatFlags, kLinearPCMFormatFlagIsNonMixable,
                "kLinearPCMFormatFlagIsNonMixable"))
        flagsSet.append(
            flagName(
                formatFlags, kLinearPCMFormatFlagsSampleFractionShift,
                "kLinearPCMFormatFlagsSampleFractionShift"))
        flagsSet.append(
            flagName(
                formatFlags, kLinearPCMFormatFlagsSampleFractionMask,
                "kLinearPCMFormatFlagsSampleFractionMask"))
        flagsSet.append(
            flagName(
                formatFlags, kLinearPCMFormatFlagsAreAllClear,
                "kLinearPCMFormatFlagsAreAllClear"))
        flagsSet.append(
            flagName(
                formatFlags, kAppleLosslessFormatFlag_16BitSourceData,
                "kAppleLosslessFormatFlag_16BitSourceData"))
        flagsSet.append(
            flagName(
                formatFlags, kAppleLosslessFormatFlag_20BitSourceData,
                "kAppleLosslessFormatFlag_20BitSourceData"))
        flagsSet.append(
            flagName(
                formatFlags, kAppleLosslessFormatFlag_24BitSourceData,
                "kAppleLosslessFormatFlag_24BitSourceData"))
        flagsSet.append(
            flagName(
                formatFlags, kAppleLosslessFormatFlag_32BitSourceData,
                "kAppleLosslessFormatFlag_32BitSourceData"))
        flagsSet.append(
            flagName(
                formatFlags, kAudioFormatFlagsNativeEndian,
                "kAudioFormatFlagsNativeEndian"))
        flagsSet.append(
            flagName(
                formatFlags, kAudioFormatFlagsCanonical,
                "kAudioFormatFlagsCanonical"))
        flagsSet.append(
            flagName(
                formatFlags, kAudioFormatFlagsAudioUnitCanonical,
                "kAudioFormatFlagsAudioUnitCanonical"))
        flagsSet.append(
            flagName(
                formatFlags, kAudioFormatFlagsNativeFloatPacked,
                "kAudioFormatFlagsNativeFloatPacked"))

        print("")

        if flagsSet.isEmpty {
            print("No AudioFormatFlags set")
        } else {
            let flags = flagsSet.compactMap { $0.isEmpty ? nil : $0 }.joined(
                separator: "\n")
            let ff = String(format: "%08X", formatFlags)
            print("AudioFormatFlags set: 0x(\(ff))\n\(flags)")
        }
    }

}

class AVInputs {
    static func inputsFromVideoType() -> [AVCaptureDevice] {
        #if os(iOS)
            let deviceTypes = [
                AVCaptureDevice.DeviceType.builtInWideAngleCamera,
                AVCaptureDevice.DeviceType.builtInTelephotoCamera,
            ]
        #elseif os(macOS)
            let deviceTypes = [
                AVCaptureDevice.DeviceType.builtInWideAngleCamera,
                AVCaptureDevice.DeviceType.externalUnknown,
                AVCaptureDevice.DeviceType.deskViewCamera,
            ]
        #endif

        let session = AVCaptureDevice.DiscoverySession(
            deviceTypes: deviceTypes,
            mediaType: .video,
            position: .unspecified)

        return session.devices
    }

    /// Returns all microphones on the device.
    static public func inputsFromAudioType() -> [AVCaptureDevice] {
        let session = AVCaptureDevice.DiscoverySession(
            deviceTypes: [
                .builtInMicrophone
            ],
            mediaType: .audio,
            position: .unspecified)

        return session.devices
    }
}

struct CMSampleBufferError {
    let status: OSStatus

    var message: String {
        switch status {
        case kCMSampleBufferError_AllocationFailed:
            return "Allocation failed"
        case kCMSampleBufferError_RequiredParameterMissing:
            return "Required parameter missing"
        case kCMSampleBufferError_AlreadyHasDataBuffer:
            return "Already has data buffer"
        case kCMSampleBufferError_BufferNotReady:
            return "Buffer not ready"
        case kCMSampleBufferError_SampleIndexOutOfRange:
            return "Sample index out of range"
        case kCMSampleBufferError_BufferHasNoSampleSizes:
            return "Buffer has no sample sizes"
        case kCMSampleBufferError_BufferHasNoSampleTimingInfo:
            return "Buffer has no sample timing info"
        case kCMSampleBufferError_ArrayTooSmall:
            return "Array too small"
        case kCMSampleBufferError_InvalidEntryCount:
            return "Invalid entry count"
        case kCMSampleBufferError_CannotSubdivide:
            return "Cannot subdivide"
        case kCMSampleBufferError_SampleTimingInfoInvalid:
            return "Sample timing info invalid"
        case kCMSampleBufferError_InvalidMediaTypeForOperation:
            return "Invalid media type for operation"
        case kCMSampleBufferError_InvalidSampleData:
            return "Invalid sample data"
        case kCMSampleBufferError_InvalidMediaFormat:
            return "Invalid media format"
        case kCMSampleBufferError_Invalidated:
            return "Invalidated"
        case kCMSampleBufferError_DataFailed:
            return "Data failed"
        case kCMSampleBufferError_DataCanceled:
            return "Data canceled"
        default:
            return "Unknown error"
        }
    }
}
