/*
import AVFoundation  // For AVCaptureSession and audio handling
import Accelerate  // For vDSP functions
import CoreMedia  // For CMSampleBuffer

class AudioProcessor: NSObject, AVCaptureAudioDataOutputSampleBufferDelegate {
  private var windowSize: Int = 10  // Size of moving average window
  private var previousSamples: [Float] = []

  func captureOutput(
    _ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer,
    from connection: AVCaptureConnection
  ) {
    // Get audio buffer list
    var audioBufferList = AudioBufferList()
    var blockBuffer: CMBlockBuffer?

    CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(
      sampleBuffer,
      bufferListSizeNeededOut: nil,
      bufferListOut: &audioBufferList,
      bufferListSize: MemoryLayout<AudioBufferList>.size,
      blockBufferAllocator: kCFAllocatorDefault,
      blockBufferMemoryAllocator: kCFAllocatorDefault,
      flags: kCMSampleBufferFlag_AudioBufferList_AssureMaximumSize,
      blockBufferOut: &blockBuffer)

    // Get the actual audio buffer
    let buffer = audioBufferList.mBuffers
    let samples = buffer.mData?.assumingMemoryBound(to: Float.self)
    let sampleCount = Int(buffer.mDataByteSize) / MemoryLayout<Float>.size

    // Create array from samples
    let currentSamples = Array(UnsafeBufferPointer(start: samples, count: sampleCount))

    // Combine with previous samples to have enough for the window
    previousSamples.append(contentsOf: currentSamples)

    // Keep only what we need for the window
    if previousSamples.count > windowSize {
      previousSamples.removeFirst(previousSamples.count - windowSize)
    }

    // Calculate moving average if we have enough samples
    if previousSamples.count == windowSize {
      var result = [Float](repeating: 0, count: sampleCount)
      let weights = [Float](repeating: 1.0 / Float(windowSize), count: windowSize)

      vDSP_vswsum(
        &previousSamples,  // Input signal
        1,  // Stride
        &result,  // Output signal
        1,  // Stride
        vDSP_Length(windowSize),  // Window size
        vDSP_Length(previousSamples.count - windowSize + 1))  // Number of frames

      // result now contains the moving average
      // You can do something with it here
      print("Moving average: \(result[0])")  // Example: print first value
    }
  }
}

// Setup code
let captureSession = AVCaptureSession()
let audioProcessor = AudioProcessor()

if let audioDevice = AVCaptureDevice.default(for: .audio) {
  do {
    let audioInput = try AVCaptureDeviceInput(device: audioDevice)
    let audioOutput = AVCaptureAudioDataOutput()

    if captureSession.canAddInput(audioInput) && captureSession.canAddOutput(audioOutput) {
      captureSession.addInput(audioInput)
      captureSession.addOutput(audioOutput)

      audioOutput.setSampleBufferDelegate(
        audioProcessor, queue: DispatchQueue(label: "audio.processing"))
      captureSession.startRunning()
    }
  } catch {
    print("Error setting up audio capture: \(error)")
  }
}
*/
