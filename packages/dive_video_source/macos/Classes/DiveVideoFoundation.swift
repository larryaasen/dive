import AVFoundation
import Accelerate

public class DiveSynchronized: NSObject {
    let serialQueue: DispatchQueue = DispatchQueue(label: "com.dive.serialSyncQueue")

    func synchronized(_ lock: Any, closure: () -> ()) {
        serialQueue.sync {
            closure()
        }
    }

    func synchronized_Sync(_ lock: Any, closure: () -> ()) {
        objc_sync_enter(lock)
        defer { objc_sync_exit(lock) }
        closure()
    }
}

struct DiveFrameRate {
    private var _last: Date?
    private var _frameCount: Int = 0
    private var _frameRate: Double = 0
    
    var fps: Double { get { _frameRate }}

    mutating func countFrame() -> Double {
        let now = Date()
        _frameCount += 1
        if _last == nil {
            _last = now
        } else {
            let interval = now.timeIntervalSince(_last!)
            if !interval.isLess(than: 1.0) {
                _frameRate = Double(_frameCount) / interval
                _last = now
                _frameCount = 0
                return _frameRate
            }
        }
        return 0
    }
    
    func formatted() -> String { String(format: "%.2f", fps) }
}

struct DiveTimestamp {
    public typealias DiveTimeValue = Int64
    
    static let millisecondScale: Int32 = 1000
    static let microsecondScale: Int32 = millisecondScale * 1000
    static let nanosecondScale:  Int32 = microsecondScale * 1000
    static let defaultScale:     Int32 = nanosecondScale

    let timestampValue: DiveTimeValue
}

struct DiveFramePlane {
    let data: UnsafeMutableRawPointer
    let lineSize: Int
    let length: Int
    let image: NSImage?
}

public struct DiveFrame {
    let timestamp: DiveTimestamp
    let planes: [DiveFramePlane]
    let width: Int
    let height: Int
}

private class CaptureDevices {
    static let shared = CaptureDevices()

    /// A duplicate map of all texture source that provides Objective-C reference counting
    private var _devices = [String: DiveVideoDevice]()

    @discardableResult
    func add(uniqueID: String, device: DiveVideoDevice) -> Bool {
        if exists(uniqueID: uniqueID) { return false }
        _devices[uniqueID] = device
        return true
    }
    
    func device(uniqueID: String) -> DiveVideoDevice? {
        if !exists(uniqueID: uniqueID) { return nil }
        return _devices[uniqueID]
    }

    func exists(uniqueID: String) -> Bool { return _devices[uniqueID] != nil }
    
    func remove(uniqueID: String) -> Bool {
        if !exists(uniqueID: uniqueID) { return false }
        _devices[uniqueID] = nil
        return true
    }
}

extension DiveVideoDevice {
    func setupSession() -> Bool {
        if let input = try? AVCaptureDeviceInput.init(device: captureDevice) {
            let output = AVCaptureVideoDataOutput.init()
            let session = AVCaptureSession.init()
            if session.canAddInput(input) && session.canAddOutput(output) {
                session.beginConfiguration()

                session.addInput(input)
                session.addOutput(output)
                
                let queue = DispatchQueue(label: "dive_video_source." + captureDevice.uniqueID)
                output.setSampleBufferDelegate(self, queue: queue)

                session.commitConfiguration()
                captureSession = session
                
                return true
            }
        }
        return false
    }
    
    func start() -> Bool {
        guard let captureSession = captureSession else { return false }
        captureSession.startRunning()
        return true
    }
}

extension DiveVideoDevice: AVCaptureVideoDataOutputSampleBufferDelegate {

    /// Dropped frames.
    public func captureOutput(_ output: AVCaptureOutput,
                       didDrop sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        let count = CMSampleBufferGetNumSamples(sampleBuffer)
        DiveLog.message("dropped frames: \(count)")
    }

    /// Output frames.
    public func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        
        // Track the frame rate of this device.
        synchronized(frameRate) {
            let fps = frameRate.countFrame()
            if fps != 0 {
                DiveLog.message("frame rate: \(frameRate.formatted()) fps")
            }
        }

        let count = CMSampleBufferGetNumSamples(sampleBuffer)
        frameCount += count
        if !isCapturing || count < 1 { return }
        
        if let frame = frameFromSampleBuffer(sampleBuffer) {
            sendFrame(frame)
        }
    }
    
    func sendFrame(_ frame: DiveFrame) {
        if let channelCallback = channelCallback {
            Callbacks.frameCallback(channelCallback: channelCallback, frame: frame)
        }
    }
    
    func frameFromSampleBuffer(_ sampleBuffer: CMSampleBuffer) -> DiveFrame? {
        let timestamp = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer)
        let timestampAdjusted = CMTimeConvertScale(timestamp,
                                                   timescale: DiveTimestamp.defaultScale,
                                                   method: .default)
        
        let ts = DiveTimestamp(timestampValue: timestampAdjusted.value)

        if let img = CMSampleBufferGetImageBuffer(sampleBuffer) {
            CVPixelBufferLockBaseAddress(img, .readOnly)
            defer { CVPixelBufferUnlockBaseAddress(img, .readOnly) }
            
            // kCVPixelFormatType_422YpCbCr8: QuickTime file format wrapping UYVY (the Apple identifier is 2vuy) uncompressed video essence, typically multiplexed with soundtrack audio.
                        
            if let description = CMSampleBufferGetFormatDescription(sampleBuffer) {
                let dimensions = CMVideoFormatDescriptionGetDimensions(description)
                let width = Int(dimensions.width)
                let height = Int(dimensions.height)
                var planes = [DiveFramePlane]()
                if (CVPixelBufferIsPlanar(img)) {
                    let count = CVPixelBufferGetPlaneCount(img)
                    for index in 0..<count {
                        let lineSize = CVPixelBufferGetBytesPerRowOfPlane(img, index)
                        if let data = CVPixelBufferGetBaseAddressOfPlane(img, index) {
                            let plane = DiveFramePlane(data: data, lineSize: lineSize, length: lineSize*height, image: nil)
                            planes.append(plane)
                        }
                    }
                } else {
                    let lineSize = CVPixelBufferGetBytesPerRow(img)
                    let subType = CMFormatDescriptionGetMediaSubType(description)
                    if let data = CVPixelBufferGetBaseAddress(img), subType == kCMPixelFormat_422YpCbCr8 {
                        if let image = ConvertImage().convert(width: vImagePixelCount(width),
                                                           height: vImagePixelCount(height),
                                                           pixelFormatType: kCVPixelFormatType_422YpCbCr8, // pixel format is 2vuy
                                                              linesize: lineSize, data: data) {
                            let plane = DiveFramePlane(data: image, lineSize: lineSize, length: lineSize*height, image: nil)
                            planes.append(plane)
                        }
                    }
                }
                let frame = DiveFrame(timestamp: ts,
                                      planes: planes,
                                      width: width,
                                      height: height)
                return frame
            }
        }
        return nil
    }
    
    func convertToImage(imageBuffer: CVImageBuffer) -> NSImage? {
        let ciImage = CIImage(cvImageBuffer: imageBuffer)
        let context = CIContext(options: nil)
        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        if let cgImage = context.createCGImage(ciImage, from: CGRect(x: 0, y: 0, width: width, height: height)) {
            let nsImage = NSImage(cgImage: cgImage, size: CGSize(width: width, height: height))
            return nsImage
        }
        return nil
    }
}

public class DiveVideoFoundation {
    /// Returns a Map of inputs.
    func cameraInputs() -> [[String: String]] {
        var inputs = [[String: String]]()
        for device in AVCaptureDevice.devices() {
            if device.hasMediaType(.video) || device.hasMediaType(.muxed) {
                let name = device.localizedName
                let id = device.uniqueID
                let input = ["name": name, "id": id]
                inputs.append(input)
            }
        }
        return inputs
    }
    
    func createCaptureDevice(uniqueID: String) -> DiveVideoDevice? {
        if CaptureDevices.shared.exists(uniqueID: uniqueID) { return nil }
        if let device = AVCaptureDevice.init(uniqueID: uniqueID) {
            let videoDevice = DiveVideoDevice(captureDevice: device)
            CaptureDevices.shared.add(uniqueID: uniqueID, device: videoDevice)
            return videoDevice
        }
        return nil
    }
    
    func verifyAuthorizationStatus(_ mediaType: AVMediaType) -> Bool {
        let authStatus = AVCaptureDevice.authorizationStatus(for: mediaType)
        switch authStatus {
            case .authorized:
                return true
            case .notDetermined: fallthrough
            case .restricted: fallthrough
            case .denied: fallthrough
            default:
                return false
        }
    }
}

class ConvertImage {
    private lazy var pixelRange: vImage_YpCbCrPixelRange = {
        // video range 8-bit, unclamped
        return vImage_YpCbCrPixelRange(Yp_bias: 16,
                                                 CbCr_bias: 128,
                                                 YpRangeMax: 235,
                                                 CbCrRangeMax: 240,
                                                 YpMax: 255,
                                                 YpMin: 0,
                                                 CbCrMax: 255,
                                       CbCrMin: 1)
    }()

    private lazy var conversionInfo: vImage_YpCbCrToARGB? = {
        var infoYpCbCrToARGB = vImage_YpCbCrToARGB()
        var pr = pixelRange
        let error = vImageConvert_YpCbCrToARGB_GenerateConversion(kvImage_YpCbCrToARGBMatrix_ITU_R_709_2,
                                                      &pr,
                                                      &infoYpCbCrToARGB,
                                                      kvImage422YpCbYpCr8,
                                                      kvImageARGB8888,
                                                      vImage_Flags(kvImageNoFlags))
        return error == kvImageNoError ? infoYpCbCrToARGB : nil
    }()
    
    func convert(width: vImagePixelCount, height: vImagePixelCount, pixelFormatType: OSType, linesize: size_t, data: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer? {
        guard var conversionInfo = conversionInfo else {
            return nil
        }
        
        var src = vImage_Buffer(data: data, height: height, width: width, rowBytes: linesize)
        let upscaleImageData = malloc(Int(width*height)*4)
//        defer { free(upscaleImageData) }
        var dst = vImage_Buffer(data: upscaleImageData, height: height, width: width, rowBytes: Int(width) * 4)
        let permuteMap: [UInt8] = [3, 2, 1, 0]
        let alpha: UInt8 = 255
        let error = vImageConvert_422CbYpCrYp8ToARGB8888(&src,
                                             &dst,
                                             &conversionInfo,
                                             permuteMap,
                                             alpha,
                                             vImage_Flags(kvImageNoFlags))
        if error != kvImageNoError {
            print("image covert error: \(error)")
            free(upscaleImageData)
            return nil
        }
        return upscaleImageData
    }
}
