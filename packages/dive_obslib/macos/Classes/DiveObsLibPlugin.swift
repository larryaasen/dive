// Copyright (c) 2021 Larry Aasen.

import AVFoundation
import Cocoa
import FlutterMacOS

public class DiveObsLibPlugin: NSObject, FlutterPlugin {
    struct Method {
        static let ObsStartup = "obsStartup"

        static let DisposeTexture = "disposeTexture"
        static let InitializeTexture = "initializeTexture"
        static let AddSourceFrameCallback = "addSourceFrameCallback"
        static let RemoveSourceFrameCallback = "removeSourceFrameCallback"

        static let AddSource = "addSource"
        static let CreateImageSource = "createImageSource"
        // static let CreateMediaSource = "createMediaSource"
        static let CreateVideoSource = "createVideoSource"
        static let CreateVideoMix = "createVideoMix"
        static let RemoveVideoMix = "removeVideoMix"
        static let ChangeFrameRate = "changeFrameRate"
        static let ChangeResolution = "changeResolution"
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

        static let GetInputTypes = "getInputTypes"
        static let GetInputsFromType = "getInputsFromType"
        static let GetAudioInputs = "getAudioInputs"
        static let GetVideoInputs = "getVideoInputs"

        static let AddVolumeMeterCallback = "addVolumeMeterCallback"
    }
    
    static let _channelName = "dive_obslib.io/plugin"

    static var textureRegistry: FlutterTextureRegistry?
        
    public static func register(with registrar: FlutterPluginRegistrar) {
        textureRegistry = registrar.textures
        
        let channel = FlutterMethodChannel(name: _channelName, binaryMessenger: registrar.messenger)
        let instance = DiveObsLibPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        print("DiveObsLibPlugin registered.")

        Callbacks.shared.register(registrar)

        // It would be best if this Swift file could call obslib C functions directly, instead
        // of having to call them from the obs_setup.mm file. This example of Swift code below
        // does not compile because `obs_startup` is not found:
//           let rv1 = obs_startup("en", nil, nil)
        // Maybe someday in the future, this could be made to work. In the meantime,
        // all functions in obslib are called from Objective-C files.
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let arguments = call.arguments != nil ? call.arguments as? [String: Any] : nil
        
        switch call.method {
        case Method.ObsStartup:
            result(obsStartup())
        case Method.InitializeTexture:
            result(initializeTexture(arguments))
        case Method.DisposeTexture:
            result(disposeTexture(arguments))
        case Method.AddSourceFrameCallback:
            result(addSourceFrameCallback(arguments))
        case Method.RemoveSourceFrameCallback:
            result(removeSourceFrameCallback(arguments))
        case Method.CreateVideoMix:
            result(createVideoMix(arguments))
        case Method.RemoveVideoMix:
            result(removeVideoMix(arguments))
        case Method.ChangeFrameRate:
            result(changeFrameRate(arguments))
        case Method.ChangeResolution:
            result(changeResolution(arguments))
        case Method.AddVolumeMeterCallback:
            result(addVolumeMeterCallback(arguments))
        case Method.GetSceneItemInfo:
            result(getSceneItemInfo(arguments))
        case Method.SetSceneItemInfo:
            result(setSceneItemInfo(arguments))

//        case Method.AddSource:
//            ffi ? nil : result(addSource(arguments))
//        case Method.CreateImageSource:
//            ffi ? nil : result(createImageSource(arguments))
//        // case Method.CreateMediaSource:
//            // ffi ? nil : result(createMediaSource(arguments))
//        case Method.CreateVideoSource:
//            ffi ? nil : result(createVideoSource(arguments))
//        // case Method.CreateScene:
//            // ffi ? nil : result(createScene(arguments))
//
//        case Method.MediaPlayPause:
//            ffi ? nil : result(mediaPlayPause(arguments))
//        case Method.MediaRestart:
//            ffi ? nil : result(mediaRestart(arguments))
//        case Method.MediaStop:
//            ffi ? nil : result(mediaStop(arguments))
//        case Method.MediaGetDuration:
//            ffi ? nil : result(mediaGetDuration(arguments))
//        case Method.MediaGetTime:
//            ffi ? nil : result(mediaGetTime(arguments))
//        case Method.MediaSetTime:
//            ffi ? nil : result(mediaSetTime(arguments))
//        case Method.MediaGetState:
//            ffi ? nil : result(mediaGetState(arguments))
//
//        case Method.GetInputTypes:
//            ffi ? nil : result(getInputTypes())
//        case Method.GetInputsFromType:
//            ffi ? nil : result(getInputsFromType(arguments))
//        case Method.GetAudioInputs:
//            ffi ? nil : result(getAudioInputs())
//        case Method.GetVideoInputs:
//            ffi ? nil : result(getVideoInputs())
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func obsStartup() -> Bool {
        // This function must be called on the main thread because of some
        // functions used by OBS that need to be called on the main thread.
        // The other functions can be called on FFI worker threads.
        return bridge_obs_startup()
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

    private func addSourceFrameCallback(_ arguments: [String: Any]?) -> Bool {
        guard let args = arguments,
            let source_uuid = args["source_uuid"] as! String?,
            let source_ptr = args["source_ptr"] as! Int64?
            else {
                return false
        }
        
        return bridge_source_add_frame_callback(source_uuid, source_ptr)
    }

    private func removeSourceFrameCallback(_ arguments: [String: Any]?) -> Bool {
        guard let args = arguments,
            let source_uuid = args["source_uuid"] as! String?,
            let source_ptr = args["source_ptr"] as! Int64?
            else {
                return false
        }
        
        return bridge_source_remove_frame_callback(source_uuid, source_ptr)
    }

    func bridge<T : AnyObject>(_ obj : T) -> UnsafeRawPointer {
        return UnsafeRawPointer(Unmanaged.passUnretained(obj).toOpaque())
    }

    func bridge<T : AnyObject>(ptr : UnsafeRawPointer) -> T {
        return Unmanaged<T>.fromOpaque(ptr).takeUnretainedValue()
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

    // private func createMediaSource(_ arguments: [String: Any]?) -> Bool {
    //     guard let args = arguments,
    //         let source_uuid = args["source_uuid"] as! String?,
    //         let localFile = args["local_file"] as! String?
    //         else {
    //             return false
    //     }
    //     return bridge_create_media_source(source_uuid, localFile)
    // }

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

    private func removeVideoMix(_ arguments: [String: Any]?) -> Bool {
        guard let args = arguments,
            let tracking_uuid = args["tracking_uuid"] as! String?
            else {
                return false
        }
        return bridge_remove_videomix(tracking_uuid)
    }

    /// Change the video frame rate.
    /// When video output is active, like with a video mix, it must be removed temporarily during
    /// the call to `obs_reset_video()`.
    private func changeFrameRate(_ arguments: [String: Any]?) -> Bool {
        guard let args = arguments,
            let numerator = args["numerator"] as! Int32?,
            let denominator = args["denominator"] as! Int32?
            else {
                return false
        }
        return bridge_change_video_framerate(numerator, denominator)
    }

    /// Change the base and output video resolution.
    /// When video output is active, like with a video mix, it must be removed temporarily during
    /// the call to `obs_reset_video()`.
    private func changeResolution(_ arguments: [String: Any]?) -> Bool {
        guard let args = arguments,
            let base_width = args["base_width"] as! Int32?,
            let base_height = args["base_height"] as! Int32?,
            let output_width = args["output_width"] as! Int32?,
            let output_height = args["output_height"] as! Int32?
            else {
                return false
        }
        return bridge_change_video_resolution(base_width, base_height, output_width, output_height)
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
            let sceneitem_pointer = args["sceneitem_pointer"] as! Int64?
            else {
                return [:]
        }
        return bridge_sceneitem_get_info(sceneitem_pointer) as? [String: Any] ?? [:]
    }
    
    private func setSceneItemInfo(_ arguments: [String: Any]?) -> Bool {
        guard let args = arguments,
            let sceneitem_pointer = args["sceneitem_pointer"] as! Int64?,
            let info = args["info"] as! [String: Any]?
            else {
                return false
        }
        return bridge_sceneitem_set_info(sceneitem_pointer, info)
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
    
    // MARK: volumeMeter

    /// Adds a callback to a volume meter.
    /// - Returns: Number of channels which are configured for this source, or -1 when the arguments are invalid.
    private func addVolumeMeterCallback(_ arguments: [String: Any]?) -> Int64 {
        guard let args = arguments,
            let volmeter_pointer = args["volmeter_pointer"] as! Int64?
            else {
                return -1
        }
        return bridge_volmeter_add_callback(volmeter_pointer)
    }
}

/// Registers a Flutter channel for invoking methods in response to callbacks
/// from native code.
public class Callbacks: NSObject {
    @objc static public let shared = Callbacks()

    private static let channelNameCallback = "dive_obslib.io/plugin/callback"

    private var channelCallback: FlutterMethodChannel?
    
    private override init() {}

    public func register(_ registrar: FlutterPluginRegistrar) {
        // Setup a channel used for Swift callbacks to send messages to Dart from Swift.
        channelCallback = FlutterMethodChannel(name: Callbacks.channelNameCallback, binaryMessenger: registrar.messenger)
    }
    
    @objc public func volMeterCallback(pointer: Int, magnitude: [Float], peak: [Float], inputPeak: [Float], arraySize: Int) {
        guard let callbacks = channelCallback else {
            return
        }

        let volmeter_pointer = pointer
        let arguments = [
            "volmeter_pointer": volmeter_pointer,
            "magnitude": magnitude,
            "peak": peak,
            "inputPeak": inputPeak
//            "magnitude": [0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1], //magnitude,
//            "peak": [0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1], // peak,
//            "inputPeak": [0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1] //inputPeak
        ] as [String : Any]
        callbacks.invokeMethod("volmeter", arguments: arguments, result: {(r:Any?) -> () in
          // this will be called with r = "some string" (or FlutterMethodNotImplemented)
        })
    }
}
