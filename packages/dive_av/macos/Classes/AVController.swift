// Copyright (c) 2024 Larry Aasen. All rights reserved.

import AVFoundation

@available(macOS 13.0, *)
class AVController {

  private var avObjects: [String: AVObject] = [:]

  // TODO: maybe rename objectId to sourceId???

  public func createVideoSource(deviceUniqueID: String) -> String {
    let captureInfo = AVCapture.AVCaptureInfo(uniqueID: deviceUniqueID)
    let avCapture = AVCapture(captureInfo: captureInfo)
    avObjects[avCapture.objectId] = avCapture

    //    if avCapture.createSession() {
    //      if avCapture.switchCaptureDevice("0x1421100015320e05") {
    //        if avCapture.startCaptureSession() {
    //
    //        }
    //      }
    //    }
    return avCapture.objectId
    //    return bridge_create_video_source(source_uuid, name, uid)
  }

  public func removeSource(objectId: String) -> Bool {
    if let avObject = avObjects.removeValue(forKey: objectId) {
      if let avObject = avObject as? AVCapture {
        avObject.stopCaptureSession()
      }
      return true
    }
    return false
  }

}
