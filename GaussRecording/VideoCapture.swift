import AVFoundation
import CoreVideo
import UIKit

public protocol VideoCaptureDelegate: class {
    func videoCapture(didCaptureVideoFrame: CMSampleBuffer)
}

public protocol PhotoCaptureDelegate: class {
    func rawPhotoCapture(rawPhoto: AVCapturePhoto)
    func qrCodeDetectedInLiveFeed(qrCodeString: String) // UG TEST
}

public class VideoCapture: NSObject, AVCapturePhotoCaptureDelegate {
    public var previewLayer: AVCaptureVideoPreviewLayer?
    public weak var delegate: VideoCaptureDelegate?
    public weak var photoDelegate: PhotoCaptureDelegate?
    
    let captureSession = AVCaptureSession()
    let videoOutput = AVCaptureVideoDataOutput()
    let queue = DispatchQueue(label: "net.machinethink.camera-queue")
    // UG TEST
    private var qrQueue = DispatchQueue(label: "Qr Detector", qos: .userInteractive)
    let captureMetadataOutput = AVCaptureMetadataOutput()
    // UG TEST
    var lastTimestamp = CMTime()
    
    var photoOutput = AVCapturePhotoOutput()
    
//    public func setUp(sessionPreset: AVCaptureSession.Preset = .photo,
//                      completion: @escaping (Bool) -> Void) {
//        queue.async {
//            let success = self.setUpCamera(sessionPreset: sessionPreset)
//            DispatchQueue.main.async {
//                completion(success)
//            }
//        }
//    }
    
    func setUpCamera(sessionPreset: AVCaptureSession.Preset, completion: @escaping (AVCaptureVideoPreviewLayer?) -> Void) {
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }
        
//        guard let captureDevice = AVCaptureDevice.default(for: AVMediaType.video) else {
//            print("Error: no video devices available")
//            completion(nil)
//        }
        
        if AVCaptureDevice.default(for: AVMediaType.video) == nil {
            completion(nil)
        }
        //let captureDevice = AVCaptureDevice.default(for: AVMediaType.video)!
        let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)!
        
        let exposureDuration = captureDevice.exposureDuration
        let whiteBalance = captureDevice.deviceWhiteBalanceGains
        let iso = captureDevice.iso
        try? captureDevice.lockForConfiguration()
        captureDevice.whiteBalanceMode = .locked
        captureDevice.setWhiteBalanceModeLocked(with: whiteBalance, completionHandler: nil)
        captureDevice.setExposureModeCustom(duration: exposureDuration, iso: iso, completionHandler: nil)
        captureDevice.unlockForConfiguration()
        
//        if(captureDevice.isFocusModeSupported(.continuousAutoFocus)) {
//            try! captureDevice.lockForConfiguration()
//            captureDevice.focusMode = .continuousAutoFocus
//            captureDevice.unlockForConfiguration()
//        }
//        
//        if(captureDevice.isWhiteBalanceModeSupported(.autoWhiteBalance)) {
//            try! captureDevice.lockForConfiguration()
//            captureDevice.whiteBalanceMode = .autoWhiteBalance
//            captureDevice.unlockForConfiguration()
//        }
//
//        try! captureDevice.lockForConfiguration()
//        captureDevice.exposureMode = .continuousAutoExposure
//        captureDevice.unlockForConfiguration()

        if let videoInput = try? AVCaptureDeviceInput(device: captureDevice) {
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            }
        }
        
        if captureSession.canSetSessionPreset(.hd4K3840x2160){
            captureSession.sessionPreset = sessionPreset
        }
        else{
            captureSession.sessionPreset = .hd1920x1080
        }
        configureQRDetectionFromLiveFeed()  // UG TEST
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        previewLayer.connection?.videoOrientation = .portrait
        self.previewLayer = previewLayer
        
        let settings: [String : Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32BGRA)
        ]
        
        videoOutput.videoSettings = settings
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: queue)
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
        
        if captureSession.canAddOutput(self.photoOutput) {
            captureSession.addOutput(self.photoOutput)
        }
        
        // We want the buffers to be in portrait orientation otherwise they are
        // rotated by 90 degrees. Need to set this _after_ addOutput()!
        videoOutput.connection(with: AVMediaType.video)?.videoOrientation = .portrait
        //start()
        //return true
        completion(self.previewLayer)
    }
    // UG TEST
    public func configureQRDetectionFromLiveFeed() {
            if self.captureSession.canAddOutput(captureMetadataOutput) {
                self.captureSession.addOutput(captureMetadataOutput)
            }
            
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: self.qrQueue)
            captureMetadataOutput.metadataObjectTypes = [.aztec, .code128, .code39, .code39Mod43, .code93, .dataMatrix, .ean13, .ean8, .itf14, .pdf417, .qr, .upce, .interleaved2of5]
    }
    
    public func removeQRDetectionFromLiveFeed() {
        self.captureSession.removeOutput(captureMetadataOutput)
    }
    // UG TEST
    public func start() {
        if !captureSession.isRunning {
            queue.async {
                self.captureSession.startRunning()
                //self.toggleTorch(on: true)
            }
        }
    }
    
    public func stop() {
        self.delegate = nil
        self.photoDelegate = nil
        if captureSession.isRunning {
            queue.async {
                self.captureSession.stopRunning()
                //self.toggleTorch(on: false)
            }
        }
    }
    
//    func toggleTorch(on: Bool) {
//        if appMode == .GlobalGood_Provider || appMode == .USC_Provider || appMode == .Cellex_Provider {
//            return
//
//        }
//        guard
//            let device = AVCaptureDevice.default(for: AVMediaType.video),
//            device.hasTorch
//        else { return }
//
//        do {
//            try device.lockForConfiguration()
//            try device.setTorchModeOn(level:1.0)
//            device.torchMode = on ? .on : .off
//            device.unlockForConfiguration()
//        } catch {
//            print("Torch could not be used")
//        }
//    }
    
//    public func capturePhoto(completion: @escaping ()->()) {
//        toggleTorch(on: false)
//            let pixelFormatType = kCVPixelFormatType_32BGRA
//            guard self.photoOutput.availablePhotoPixelFormatTypes.contains(pixelFormatType) else { return }
//            let photoSettings = AVCapturePhotoSettings(format:
//                [ kCVPixelBufferPixelFormatTypeKey as String : pixelFormatType ])
//        if appMode == .GlobalGood_Provider || appMode == .Cellex_Provider{
//            if self.photoOutput.supportedFlashModes.contains(.on){
//                photoSettings.flashMode = .on
//            }
//
//        }
//            // Shoot the photo, using a custom class to handle capture delegate callbacks.
//            self.photoOutput.capturePhoto(with: photoSettings, delegate: self)
//            completion()
//        //}
//    }
    
//    public func capturePhotoWith(flashOn:Bool, completion: @escaping ()->()) {
//        toggleTorch(on: false)
//        //DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
//            let pixelFormatType = kCVPixelFormatType_32BGRA
//            guard self.photoOutput.availablePhotoPixelFormatTypes.contains(pixelFormatType) else { return }
//            let photoSettings = AVCapturePhotoSettings(format:
//                [ kCVPixelBufferPixelFormatTypeKey as String : pixelFormatType ])
//        if appMode == .GlobalGood_Provider || appMode == .Cellex_Provider{
//            if self.photoOutput.supportedFlashModes.contains(.on){
//                photoSettings.flashMode = ((flashOn == true) ? .on : .off)
//            }
//
//        }
//            // Shoot the photo, using a custom class to handle capture delegate callbacks.
//            self.photoOutput.capturePhoto(with: photoSettings, delegate: self)
//            completion()
//        //}
//    }
        
    // Hold on to the separately delivered RAW file and compressed photo data until capture is finished.
//    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
//        // UNCOMPRESSED
//       // toggleTorch(on: true)
//        photoDelegate?.rawPhotoCapture(rawPhoto: photo)
//    }
}

extension VideoCapture: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        delegate?.videoCapture(didCaptureVideoFrame: sampleBuffer)
    }
    
    public func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        //print("dropped frame")
    }
}

extension VideoCapture: AVCaptureMetadataOutputObjectsDelegate{
    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metaDataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject{
            if let qrCodeString = metaDataObject.stringValue {
                photoDelegate?.qrCodeDetectedInLiveFeed(qrCodeString: qrCodeString)
            }
        }
    }
    

    
}
