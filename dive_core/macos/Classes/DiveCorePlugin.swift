import AVFoundation
import Cocoa
import FlutterMacOS

// let _imageProducer = ImageFrameProducer()

public class DiveCorePlugin: NSObject, FlutterPlugin {
    struct Method {
        static let LoadImage = "loadImage"
        static let GetPlatformVersion = "getPlatformVersion"
        static let DisposeTexture = "disposeTexture"
        static let InitializeTexture = "initializeTexture"
        static let GetInputTypes = "getInputTypes"
        static let GetVideoInputs = "getVideoInputs"
        static let CreateMediaSource = "createMediaSource"
        static let CreateVideoSource = "createVideoSource"
        static let CreateVideoMix = "createVideoMix"
        static let MediaPlayPause = "mediaPlayPause"
        static let MediaStop = "mediaStop"
    }
    
    static let _channelName = "dive_core.io/plugin"
    static var textureRegistry: FlutterTextureRegistry?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        textureRegistry = registrar.textures
        
        let channel = FlutterMethodChannel(name: _channelName, binaryMessenger: registrar.messenger)
        let instance = DiveCorePlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        
        create_obs()

        print("DiveCorePlugin registered.")
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        print("DiveCorePlugin.handle method: \(call.method)")
        let arguments = call.arguments != nil ? call.arguments as? [String: Any] : nil
        switch call.method {
        case Method.InitializeTexture:
            result(initializeTexture(arguments))
        case Method.LoadImage:
//            _imageProducer.loadImage()
            result("done")
        case Method.GetPlatformVersion:
            result(getPlatformVersion())
        case Method.GetInputTypes:
            result(getInputTypes())
        case Method.GetVideoInputs:
            result(getVideoInputs())
        case Method.CreateMediaSource:
            result(createMediaSource(arguments))
        case Method.CreateVideoSource:
            result(createVideoSource(arguments))
        case Method.CreateVideoMix:
            result(createVideoMix(arguments))
        case Method.MediaPlayPause:
            result(mediaPlayPause(arguments))
        case Method.MediaStop:
            result(mediaStop(arguments))
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
        guard let args = arguments, let trackingUUID = args["tracking_uuid"] as! String? else {
            return 0
        }
        if let source = TextureSource(uuid: trackingUUID, registry: DiveCorePlugin.textureRegistry) {
            if let texturedId = DiveCorePlugin.textureRegistry?.register(source) {
                source.textureId = texturedId
                source.trackingUUID = trackingUUID
                addFrameCapture(source)
                return texturedId
            }
        }
        return 0
    }

    private func getPlatformVersion() -> String {
        let msg = "macOS " + ProcessInfo.processInfo.operatingSystemVersionString
        return msg
    }
    
    private func getInputTypes() -> [[String: Any]] {
        return bridge_input_types() as? [[String: Any]] ?? []
    }

    private func getVideoInputs() -> [[String: Any]] {
        return bridge_video_inputs() as? [[String: Any]] ?? []
    }

    private func createMediaSource(_ arguments: [String: Any]?) -> Bool {
        guard let args = arguments,
            let source_uuid = args["source_uuid"] as! String?,
            let localFile = args["local_file"] as! String?
            else {
                return false
        }
        return bridge_create_media_source(source_uuid, localFile)
    }
    
    private func createVideoSource(_ arguments: [String: Any]?) -> Bool {
        guard let args = arguments,
            let source_uuid = args["source_uuid"] as! String?,
            let name = args["device_name"] as! String?,
            let uid = args["device_uid"] as! String?
            else {
                return false
        }
        return bridge_create_video_source(source_uuid, name, uid)
    }
    
    private func createVideoMix(_ arguments: [String: Any]?) -> Bool {
        guard let args = arguments,
            let tracking_uuid = args["tracking_uuid"] as! String?
            else {
                return false
        }
        return bridge_add_videomix(tracking_uuid)
    }

    private func mediaPlayPause(_ arguments: [String: Any]?) -> Bool {
        guard let args = arguments,
            let source_uuid = args["source_uuid"] as! String?,
            let pause = args["pause"] as! Bool?
            else {
                return false
        }
        return bridge_media_source_play_pause(source_uuid, pause);
    }
    
    private func mediaStop(_ arguments: [String: Any]?) -> Bool {
        guard let args = arguments,
            let source_uuid = args["source_uuid"] as! String?
            else {
                return false
        }
        return bridge_media_source_stop(source_uuid);
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

// public class ImageFrameProducer {
    
//     public func loadImage() {
//         let path = "/Users/larry/Downloads/Nicholas-Nationals-Play-Ball.jpg"
//         print(path)
//     }
// }
