import Cocoa
import FlutterMacOS

/// Registers a Flutter channel for invoking methods in response to callbacks
/// from native code.
public class AVCallbacks: NSObject {
  private static let channelNameCallback = "dive_av.io/plugin/callback"

  private var channelCallback: FlutterMethodChannel?

  public func register(_ registrar: FlutterPluginRegistrar) {
    // Setup a channel used for Swift callbacks to send messages to Dart from Swift.
    channelCallback = FlutterMethodChannel(
      name: AVCallbacks.channelNameCallback, binaryMessenger: registrar.messenger)
  }

  @objc public func volMeterCallback(
    sourceId: String, magnitude: [Float], peak: [Float], inputPeak: [Float]
  ) {
    guard let callbacks = channelCallback else {
      return
    }

    let arguments =
      [
        "source_id": sourceId,
        "magnitude": magnitude,
        "peak": peak,
        "inputPeak": inputPeak,
          //            "magnitude": [0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1], //magnitude,
          //            "peak": [0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1], // peak,
          //            "inputPeak": [0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1] //inputPeak
      ] as [String: Any]

    // To comply with channel's main thread requirement, you need to jump from a background thread to
    // the main thread to execute a channel method.
    DispatchQueue.main.async {
      let methodName = "volmeter"
      callbacks.invokeMethod(
        methodName, arguments: arguments,
        result: { (r: Any?) -> Void in
          // this will be called with r = "some string" (or FlutterMethodNotImplemented)
        })
    }
  }
}
