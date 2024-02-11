import Cocoa
import FlutterMacOS

@available(macOS 13.0, *)
public class DiveAVPlugin: NSObject, FlutterPlugin {
  struct Method {
    static let DisposeTexture = "disposeTexture"
    static let InitializeTexture = "initializeTexture"
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
    // case Method.AddSourceFrameCallback:
    //     result(addSourceFrameCallback(arguments))
    // case Method.RemoveSourceFrameCallback:
    //     result(removeSourceFrameCallback(arguments))
    // case Method.CreateVideoMix:
    //     result(createVideoMix(arguments))
    // case Method.RemoveVideoMix:
    //     result(removeVideoMix(arguments))
    // case Method.ChangeFrameRate:
    //     result(changeFrameRate(arguments))
    // case Method.ChangeResolution:
    //     result(changeResolution(arguments))
    // case Method.AddVolumeMeterCallback:
    //     result(addVolumeMeterCallback(arguments))
    // case Method.GetSceneItemInfo:
    //     result(getSceneItemInfo(arguments))
    // case Method.SetSceneItemInfo:
    //     result(setSceneItemInfo(arguments))
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func createVideoSource(_ arguments: [String: Any]?) -> String? {
    //    guard let args = arguments,
    //      let source_uuid = args["source_uuid"] as! String?,
    //      let name = args["device_name"] as! String?,
    //      let uid = args["device_uid"] as! String?
    //    else {
    //      return false
    //    }
      guard let args = arguments,
        let deviceUniqueID = args["device_uique_id"] as! String?
      else {
        return nil
      }

    // Razer Kiyo Pro: 0x1421100015320e05
    // FaceTime HD Camera (Built-in): 0x8020000005ac8514
    return controller.createVideoSource(deviceUniqueID: deviceUniqueID)
  }

  private func removeSource(_ arguments: [String: Any]?) -> Bool {
    guard let args = arguments,
      let source_id = args["source_id"] as! String?
    else {
      return false
    }
    return controller.removeSource(objectId: source_id)
  }

  private func disposeTexture(_ arguments: [String: Any]?) -> Bool {
    var rv = false
    if let args = arguments {
      if let texturedId = args["textureId"] as! Int64? {
        DiveAVPlugin.textureRegistry?.unregisterTexture(texturedId)
        rv = true
      }
    }
    return rv
  }

  private func initializeTexture(_ arguments: [String: Any]?) -> Int64 {
    guard let args = arguments, let trackingUUID = args["tracking_uuid"] as! String? else {
      return 0
    }

    // TODO: fix this to be immutable

    let provider = TextureProvider(uuid: trackingUUID, registry: DiveAVPlugin.textureRegistry)
    if let texturedId = DiveAVPlugin.textureRegistry?.register(provider) {
      provider.textureId = texturedId
      // source.trackingUUID = trackingUUID
      saveTextureProvider(provider)
      return texturedId
    }

    return 0
  }

  /// Map of all texture providers where the key is a source UUID and the value is a texture provider pointer
  private var textureProviders: [String: TextureProvider] = [:]

  private func saveTextureProvider(_ textureProvider: TextureProvider) {
    guard !textureProvider.trackingUUID.isEmpty else {
      print("saveTextureProvider: missing sourceUUID\n")
      return
    }

    //    let uuid_str = Int8(trackingUUID.utf8CString ?? 0)
    objc_sync_enter(textureProviders)
    defer { objc_sync_exit(textureProviders) }

    let provider = textureProviders[textureProvider.trackingUUID]
    if provider != nil {
      print("saveTextureProvider: duplicate texture provider: \(textureProvider.trackingUUID)")
      return
    }
    textureProviders[textureProvider.trackingUUID] = textureProvider
  }

  private func removeTextureProvider(_ textureProvider: TextureProvider) {
    guard !textureProvider.trackingUUID.isEmpty else {
      print("removeTextureProvider: missing sourceUUID\n")
      return
    }

    objc_sync_enter(textureProviders)
    defer { objc_sync_exit(textureProviders) }
    let provider = textureProviders[textureProvider.trackingUUID]
    if provider == nil {
      print("removeTextureProvider: unknown texture provider: \(textureProvider.trackingUUID)\n")
      return
    }

    textureProviders.removeValue(forKey: textureProvider.trackingUUID)
  }
}
