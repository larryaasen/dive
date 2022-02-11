import FlutterMacOS
import Foundation

/// Registers a Flutter channel for invoking methods in response to callbacks from native code.
public class Callbacks {
    public static func register(_ registrar: FlutterPluginRegistrar, channelName: String) -> FlutterMethodChannel {
        // Setup a channel used for Swift callbacks to send messages to Dart from Swift.
        return FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger)
    }

    public static func frameCallback(channelCallback: FlutterMethodChannel, frame: DiveFrame) {
        let data = Data(bytesNoCopy: frame.planes[0].data, count: frame.planes[0].length, deallocator: .none)
        let arguments = [
            "data": FlutterStandardTypedData(bytes: data as Data),
            "width": frame.width,
            "height": frame.height,
            "linesize": frame.planes[0].lineSize,
        ] as [String : Any]
        channelCallback.invokeMethod("frame", arguments: arguments, result: {(r:Any?) -> () in
          // this will be called with r = "some string" (or FlutterMethodNotImplemented)
        })
    }

//    @objc public func volMeterCallback(pointer: Int, magnitude: [Float], peak: [Float], inputPeak: [Float], arraySize: Int) {
//        guard let callbacks = channelCallback else {
//            return
//        }
//
//        let volmeter_pointer = pointer
//        let arguments = [
//            "volmeter_pointer": volmeter_pointer,
//            "magnitude": magnitude,
//            "peak": peak,
//            "inputPeak": inputPeak
//        ] as [String : Any]
//        callbacks.invokeMethod("volmeter", arguments: arguments, result: {(r:Any?) -> () in
//          // this will be called with r = "some string" (or FlutterMethodNotImplemented)
//        })
//    }
}
