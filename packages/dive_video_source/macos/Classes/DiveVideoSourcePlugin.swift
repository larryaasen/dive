import Cocoa
import FlutterMacOS

public class DiveVideoSourcePlugin: NSObject, FlutterPlugin {
   static let _channelName = "divekit.dev/dive_video_source"

   struct Method {
       static let createVideoSource = "createVideoSource"
       static let getInputsFromType = "getInputsFromType"
   }

    let registrar: FlutterPluginRegistrar
    let _videoSources = DiveVideoSources()
    let _foundation = DiveVideoFoundation()
    
    public init(registrar: FlutterPluginRegistrar) {
        self.registrar = registrar
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: _channelName, binaryMessenger: registrar.messenger)
        let instance = DiveVideoSourcePlugin(registrar: registrar)
        registrar.addMethodCallDelegate(instance, channel: channel)
        print("DiveVideoSourcePlugin registered.")
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
      let arguments = call.arguments != nil ? call.arguments as? [String: Any] : nil
      switch call.method {
      case Method.createVideoSource:
        result(createVideoSource(arguments))
      case Method.getInputsFromType:
        result(getInputsFromType(arguments))
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    private func createVideoSource(_ arguments: [String: Any]?) -> Bool {
        guard let args = arguments,
              let inputId = args["input_id"] as! String?,
              let channelName = args["callback_channel_name"] as! String?
            else { return false }
        if let device = _foundation.createCaptureDevice(uniqueID: inputId),
           device.setupSession(),
           device.start() {
            device.channelCallback = Callbacks.register(registrar, channelName: channelName)
            return true
        }
        return false
    }

    private func getInputsFromType(_ arguments: [String: Any]?) -> [[String: Any]] {
      guard let args = arguments,
          let type_id = args["type_id"] as! String?
          else {
              return []
      }
      return _videoSources.inputsFromType(typeId: type_id)
    }
}

public class DiveVideoSources: NSObject {
    let _foundation = DiveVideoFoundation()

    public func inputsFromType(typeId: String) -> [[String: String]] {
        return _foundation.cameraInputs()
    }
}
