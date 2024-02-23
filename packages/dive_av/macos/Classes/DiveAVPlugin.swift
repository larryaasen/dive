import Cocoa
import FlutterMacOS

@available(macOS 13.0, *)
public class DiveAVPlugin: NSObject, FlutterPlugin {
  struct Method {
    static let DisposeTexture = "disposeTexture"
    static let InitializeTexture = "initializeTexture"
    static let InputsFromType = "inputsFromType"
    // static let AddSourceFrameCallback = "addSourceFrameCallback"
    // static let RemoveSourceFrameCallback = "removeSourceFrameCallback"

    // static let AddSource = "addSource"
    // static let CreateImageSource = "createImageSource"
    static let CreateVideoSource = "createVideoSource"
    static let RemoveSource = "removeSource"
    // static let CreateVideoMix = "createVideoMix"
    // static let RemoveVideoMix = "removeVideoMix"
    // static let ChangeFrameRate = "changeFrameRate"
    // static let ChangeResolution = "changeResolution"
    // static let CreateScene = "createScene"

    // static let MediaPlayPause = "mediaPlayPause"
    // static let MediaRestart = "mediaRestart"
    // static let MediaStop = "mediaStop"
    // static let MediaGetDuration = "mediaGetDuration"
    // static let MediaGetTime = "mediaGetTime"
    // static let MediaSetTime = "mediaSetTime"
    // static let MediaGetState = "mediaGetState"

    // static let GetSceneItemInfo = "getSceneItemInfo"
    // static let SetSceneItemInfo = "setSceneItemInfo"

    // static let AddVolumeMeterCallback = "addVolumeMeterCallback"
  }

  static let _channelName = "dive_av.io/plugin"

  let controller = AVController()

  static var textureRegistry: FlutterTextureRegistry?

  /// The entry point from Flutter to instantiate the plugin.
  public static func register(with registrar: FlutterPluginRegistrar) {
    textureRegistry = registrar.textures

    let channel = FlutterMethodChannel(name: _channelName, binaryMessenger: registrar.messenger)
    let instance = DiveAVPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    print("DiveAVPlugin registered.")
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let arguments = call.arguments != nil ? call.arguments as? [String: Any] : nil

    switch call.method {
    case Method.InitializeTexture:
      result(initializeTexture(arguments))
    case Method.DisposeTexture:
      result(disposeTexture(arguments))
    case Method.CreateVideoSource:
      result(createVideoSource(arguments))
    case Method.RemoveSource:
      result(removeSource(arguments))
    case Method.InputsFromType:
      result(inputsFromType(arguments))
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func createVideoSource(_ arguments: [String: Any]?) -> String? {
    guard let args = arguments,
      let deviceUniqueID = args["device_uique_id"] as! String?
    else {
      return nil
    }
    let textureId = args["texture_id"] as? Int64

    return controller.createVideoSource(deviceUniqueID: deviceUniqueID, textureId: textureId)
  }

  private func removeSource(_ arguments: [String: Any]?) -> Bool {
    guard let args = arguments,
      let source_id = args["source_id"] as! String?
    else {
      return false
    }
    return controller.removeSource(objectId: source_id)
  }

  /// Registers a `FlutterTexture` for usage in Flutter and returns an id that can be used to reference
  /// that texture when calling into Flutter with channels. Textures must be registered on the
  /// platform thread. On success returns the pointer to the registered texture, else returns 0.
  private func initializeTexture(_ arguments: [String: Any]?) -> Int64 {
    guard DiveAVPlugin.textureRegistry != nil else {
      return 0
    }
    return controller.initializeTexture(textureRegistry: DiveAVPlugin.textureRegistry!)
  }

  private func inputsFromType(_ arguments: [String: Any]?) -> [[String: String]] {
    return controller.inputsFromType()
  }

  private func disposeTexture(_ arguments: [String: Any]?) -> Bool {
    if let args = arguments {
      if let textureId = args["textureId"] as? Int64 {
        return controller.disposeTexture(
          textureRegistry: DiveAVPlugin.textureRegistry!, textureId: textureId)
      }
    }
    return false
  }
}
