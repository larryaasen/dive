import AVFoundation
import Cocoa
import FlutterMacOS

// let _imageProducer = ImageFrameProducer()

public class DiveObsLibPlugin: NSObject, FlutterPlugin {
    struct Method {
        static let GetPlatformVersion = "getPlatformVersion"
        static let DisposeTexture = "disposeTexture"
        static let InitializeTexture = "initializeTexture"
        static let AddSource = "addSource"
        static let CreateSource = "createSource"
        static let CreateImageSource = "createImageSource"
        static let CreateMediaSource = "createMediaSource"
        static let CreateVideoSource = "createVideoSource"
        static let CreateVideoMix = "createVideoMix"
        static let CreateScene = "createScene"

        static let MediaPlayPause = "mediaPlayPause"
        static let MediaRestart = "mediaRestart"
        static let MediaStop = "mediaStop"
        static let MediaGetDuration = "mediaGetDuration"
        static let MediaGetTime = "mediaGetTime"
        static let MediaSetTime = "mediaSetTime"        
        static let MediaGetState = "mediaGetState"

        static let GetSceneItemInfo = "getSceneItemInfo"
        static let SetSceneItemInfo = "setSceneItemInfo"

        static let StartStopStream = "startStopStream"
        static let OutputGetState = "outputGetState"

        static let GetInputTypes = "getInputTypes"
        static let GetInputsFromType = "getInputsFromType"
        static let GetAudioInputs = "getAudioInputs"
        static let GetVideoInputs = "getVideoInputs"
    }
    
    static let _channelName = "dive_obslib.io/plugin"
    static var textureRegistry: FlutterTextureRegistry?
    static let obsFFI = true;
    static let obsPlugin = !obsFFI;
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        textureRegistry = registrar.textures
        
        let channel = FlutterMethodChannel(name: _channelName, binaryMessenger: registrar.messenger)
        let instance = DiveObsLibPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        print("DiveObsLibPlugin registered.")
        
        // This function must be called on the main thread because of some 
        // functions used by OBS that need to be called on the main thread.
        // The other functions can be called on FFI worker threads.
        let rv = create_obs()

        // This is old code use for the plugin technique.
       if obsPlugin && rv {
           load_obs()
       }
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        print("DiveObsLibPlugin.handle method: \(call.method)")
        let arguments = call.arguments != nil ? call.arguments as? [String: Any] : nil
        
        let ffi = DiveObsLibPlugin.obsFFI

        switch call.method {
        case Method.InitializeTexture:
            result(initializeTexture(arguments))
        case Method.GetPlatformVersion:
            result(getPlatformVersion())
        case Method.AddSource:
            ffi ? nil : result(addSource(arguments))
        case Method.CreateSource:
            ffi ? nil : result(createSource(arguments))
        case Method.CreateImageSource:
            ffi ? nil : result(createImageSource(arguments))
        case Method.CreateMediaSource:
            ffi ? nil : result(createMediaSource(arguments))
        case Method.CreateVideoSource:
            ffi ? nil : result(createVideoSource(arguments))
        case Method.CreateVideoMix:
            ffi ? nil : result(createVideoMix(arguments))
        case Method.CreateScene:
            ffi ? nil : result(createScene(arguments))

        case Method.MediaPlayPause:
            ffi ? nil : result(mediaPlayPause(arguments))
        case Method.MediaRestart:
            ffi ? nil : result(mediaRestart(arguments))
        case Method.MediaStop:
            ffi ? nil : result(mediaStop(arguments))
        case Method.MediaGetDuration:
            ffi ? nil : result(mediaGetDuration(arguments))
        case Method.MediaGetTime:
            ffi ? nil : result(mediaGetTime(arguments))
        case Method.MediaSetTime:
            ffi ? nil : result(mediaSetTime(arguments))
        case Method.MediaGetState:
            ffi ? nil : result(mediaGetState(arguments))

        case Method.GetSceneItemInfo:
            ffi ? nil : result(getSceneItemInfo(arguments))
        case Method.SetSceneItemInfo:
            ffi ? nil : result(setSceneItemInfo(arguments))
        case Method.StartStopStream:
            ffi ? nil : result(startStopStream(arguments))
        case Method.OutputGetState:
            ffi ? nil : result(outputGetState())
        case Method.GetInputTypes:
            ffi ? nil : result(getInputTypes())
        case Method.GetInputsFromType:
            ffi ? nil : result(getInputsFromType(arguments))
        case Method.GetAudioInputs:
            ffi ? nil : result(getAudioInputs())
        case Method.GetVideoInputs:
            ffi ? nil : result(getVideoInputs())
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func disposeTexture(_ arguments: [String: Any]?) -> Bool {
        var rv = false
        if let args = arguments {
            if let texturedId = args["textureId"] as! Int64? {
                DiveObsLibPlugin.textureRegistry?.unregisterTexture(texturedId)
                rv = true
            }
        }
        return rv
    }

    private func initializeTexture(_ arguments: [String: Any]?) -> Int64 {
        guard let args = arguments, let trackingUUID = args["tracking_uuid"] as! String? else {
            return 0
        }
        if let source = TextureSource(uuid: trackingUUID, registry: DiveObsLibPlugin.textureRegistry) {
            if let texturedId = DiveObsLibPlugin.textureRegistry?.register(source) {
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
    
    private func createSource(_ arguments: [String: Any]?) -> Bool {
        guard let args = arguments,
            let source_uuid = args["source_uuid"] as! String?,
            let source_id = args["source_id"] as! String?,
            let name = args["name"] as! String?,
            let frame_source = args["frame_source"] as! Bool?
            else {
                return false
        }
        return bridge_create_source(source_uuid, source_id, name, frame_source)
    }
    
    private func addSource(_ arguments: [String: Any]?) -> Int64 {
        guard let args = arguments,
            let scene_uuid = args["scene_uuid"] as! String?,
            let source_uuid = args["source_uuid"] as! String?
            else {
                return 0
        }
        return bridge_add_source(scene_uuid, source_uuid);
    }

    private func createImageSource(_ arguments: [String: Any]?) -> Bool {
        guard let args = arguments,
            let source_uuid = args["source_uuid"] as! String?,
            let localFile = args["file"] as! String?
            else {
                return false
        }
        return bridge_create_image_source(source_uuid, localFile)
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

    private func createScene(_ arguments: [String: Any]?) -> Bool {
        guard let args = arguments,
            let tracking_uuid = args["tracking_uuid"] as! String?,
            let name = args["name"] as! String?
            else {
                return false
        }
        return bridge_create_scene(tracking_uuid, name);
    }
    
    private func startStopStream(_ arguments: [String: Any]?) -> Bool {
        guard let args = arguments,
            let start = args["start"] as! Bool?
            else {
                return false
        }
        return start ? bridge_stream_output_start() : bridge_stream_output_stop()
    }

    private func outputGetState() -> Int {
        return Int(bridge_output_get_state());
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
    
    private func mediaRestart(_ arguments: [String: Any]?) -> Bool {
        guard let args = arguments,
            let source_uuid = args["source_uuid"] as! String?
            else {
                return false
        }
        return bridge_media_source_restart(source_uuid);
    }

    private func mediaStop(_ arguments: [String: Any]?) -> Bool {
        guard let args = arguments,
            let source_uuid = args["source_uuid"] as! String?
            else {
                return false
        }
        return bridge_media_source_stop(source_uuid);
    }
    
    private func mediaGetDuration(_ arguments: [String: Any]?) -> Int64 {
        guard let args = arguments,
            let source_uuid = args["source_uuid"] as! String?
            else {
                return 0
        }
        return bridge_media_source_get_duration(source_uuid);
    }
    
    private func mediaGetTime(_ arguments: [String: Any]?) -> Int64 {
        guard let args = arguments,
            let source_uuid = args["source_uuid"] as! String?
            else {
                return 0
        }
        return bridge_media_source_get_time(source_uuid);
    }
    
    private func mediaSetTime(_ arguments: [String: Any]?) -> Bool {
        guard let args = arguments,
            let source_uuid = args["source_uuid"] as! String?,
            let ms = args["ms"] as! Int64?
            else {
                return false
        }
        return bridge_media_source_set_time(source_uuid, ms);
    }

    private func mediaGetState(_ arguments: [String: Any]?) -> Int {
        guard let args = arguments,
            let source_uuid = args["source_uuid"] as! String?
            else {
                return 0
        }
        return Int(bridge_media_source_get_state(source_uuid));
    }

    private func getSceneItemInfo(_ arguments: [String: Any]?) -> [String: Any] {
        guard let args = arguments,
            let scene_uuid = args["scene_uuid"] as! String?,
            let item_id = args["item_id"] as! Int64?
            else {
                return [:]
        }
        return bridge_sceneitem_get_info(scene_uuid, item_id) as? [String: Any] ?? [:]
    }
    
    private func setSceneItemInfo(_ arguments: [String: Any]?) -> Bool {
        guard let args = arguments,
            let scene_uuid = args["scene_uuid"] as! String?,
            let item_id = args["item_id"] as! Int64?,
            let info = args["info"] as! [String: Any]?
            else {
                return false
        }
        return bridge_sceneitem_set_info(scene_uuid, item_id, info)
    }
    
    private func getInputTypes() -> [[String: Any]] {
        return bridge_input_types() as? [[String: Any]] ?? []
    }
    
    private func getInputsFromType(_ arguments: [String: Any]?) -> [[String: Any]] {
        guard let args = arguments,
            let type_id = args["type_id"] as! String?
            else {
                return []
        }
        return bridge_inputs_from_type(type_id) as? [[String: Any]] ?? []
    }

    private func getAudioInputs() -> [[String: Any]] {
        return bridge_audio_inputs() as? [[String: Any]] ?? []
    }

    private func getVideoInputs() -> [[String: Any]] {
        return bridge_video_inputs() as? [[String: Any]] ?? []
    }
}
