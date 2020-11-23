import AVFoundation
import Cocoa
import FlutterMacOS

let _imageProducer = ImageFrameProducer()

public class DiveCorePlugin: NSObject, FlutterPlugin {
    struct Method {
        static let LoadImage = "loadImage"
        static let GetPlatformVersion = "getPlatformVersion"
        static let GetDevicesDescription = "getDevicesDescription"
        static let DisposeTexture = "disposeTexture"
        static let InitializeTexture = "initializeTexture"
        static let GetDevices = "getDevices"
    }
    
    static let _channelName = "dive_core.io/plugin"
    static var textureRegistry: FlutterTextureRegistry?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        textureRegistry = registrar.textures
        
        let channel = FlutterMethodChannel(name: _channelName, binaryMessenger: registrar.messenger)
        let instance = DiveCorePlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        print("DiveCorePlugin registered.")
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        print("DiveCorePlugin.handle method: \(call.method)")
        let arguments = call.arguments != nil ? call.arguments as? [String: Any] : nil
        switch call.method {
        case Method.InitializeTexture:
            result(initializeTexture(arguments))
        case Method.LoadImage:
            _imageProducer.loadImage()
            result("done")
        case Method.GetDevicesDescription:
            result(getDevicesDescription())
        case Method.GetDevices:
            result(getDevices())
        case Method.GetPlatformVersion:
            result(getPlatformVersion())
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func disposeTexture(_ arguments: [String: Any]?) -> Bool {
        var rv = false
        if let args = arguments {
            if let texturedId = args["textureId"] as! Int64? {
                DiveCorePlugin.textureRegistry?.unregisterTexture(texturedId)
                rv = true
            }
        }
        return rv
    }

    private func initializeTexture(_ arguments: [String: Any]?) -> Int64 {
        return 0
        if let source = TextureSource(name: "camera", registry: DiveCorePlugin.textureRegistry) {
            if let texturedId = DiveCorePlugin.textureRegistry?.register(source) {
                source.textureId = texturedId
                return texturedId
            }
        }
        return 0
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
        create_obs()
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

public class ImageFrameProducer {
    
    public func loadImage() {
        let path = "/Users/larry/Downloads/Nicholas-Nationals-Play-Ball.jpg"
        print(path)
    }
}

public class LibObs {

  func CreateOBS() -> Bool {
    return true
//    create_obs()
  }
}
