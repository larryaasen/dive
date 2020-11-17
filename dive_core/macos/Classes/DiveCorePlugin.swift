import AVFoundation
import Cocoa
import FlutterMacOS

let _imageProducer = ImageFrameProducer()

public class DiveCorePlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "dive_core", binaryMessenger: registrar.messenger)
    let instance = DiveCorePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    print("DiveCorePlugin registered.")
    
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    print("DiveCorePlugin.handle method: \(call.method)")
    switch call.method {
      case "ImageFrameProducer.loadImage":
        _imageProducer.publish()
      result("done")
    case "getDevicesDescription":
      result(getDevicesDescription())
    case "getDevices":
      result(getDevices())
    case "getPlatformVersion":
      result(getPlatformVersion())
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func getPlatformVersion() -> String {
      let msg = "macOS " + ProcessInfo.processInfo.operatingSystemVersionString
      return msg
  }

  private func getDevicesDescription() -> String {
      let devices = captureDevices()
      return "\(devices)"
  }

  private func getDevices() -> [[String: Any]] {
      let devices = captureDevices()
      var deviceList = [[String: Any]]()
      for device in devices {
        var data = [String: Any]()
        data["id"] = device.uniqueID
        data["name"] = device.localizedName
        data["mediaType"] = mediaTypeName(device.activeFormat.mediaType)
        deviceList.append(data)
      }
      return deviceList
  }

  private func captureDevices() -> [AVCaptureDevice] {
    let devices = AVCaptureDevice.devices()
    return devices

    // if #available(macOS 10.15, *) {
    //   let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(
    //   deviceTypes: [ .builtInWideAngleCamera, .externalUnknown ],
    //   mediaType: .video,
    //   position: .unspecified
    //   )
    //   deviceMsg = "\(deviceDiscoverySession.devices)"
    // }
  }

  private func mediaTypeName(_ mediaType: AVMediaType) -> String {
    switch mediaType {
    case .audio:
        return "audio"
    case .video:
        return "video"
    default:
        return "text"
    }
  }
}

public class LibObs {

  func CreateOBS() -> Bool {
    create_obs()
  }
}

public class ImageFrameProducer {

    func publish() {
      let obs = LibObs()
      let rv = obs.CreateOBS()
      return
    }
    
  public func loadImage() {
    let path = "/Users/larry/Downloads/Nicholas-Nationals-Play-Ball.jpg"
    
  }
    
    public func setup() {
    }
}
