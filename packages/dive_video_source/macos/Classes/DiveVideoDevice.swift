import AVFoundation
import FlutterMacOS

public class DiveVideoDevice: DiveSynchronized {
    let captureDevice: AVCaptureDevice
    var captureSession: AVCaptureSession?
    var channelCallback: FlutterMethodChannel?
    var isCapturing: Bool = true
    var frameCount: Int = 0
    var frameRate = DiveFrameRate()

    init(captureDevice: AVCaptureDevice) { self.captureDevice = captureDevice }
}
