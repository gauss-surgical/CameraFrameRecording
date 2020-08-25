//
//  ViewController.swift
//  GaussRecording
//
//  Created by Utsha Guha on 8/25/20.
//  Copyright © 2020 Gauss. All rights reserved.
//

import UIKit
import AVFoundation
class ViewController: UIViewController, VideoCaptureDelegate,PhotoCaptureDelegate {
    func rawPhotoCapture(rawPhoto: AVCapturePhoto) {
        print(rawPhoto)
    }
    
    func videoCapture(didCaptureVideoFrame: CMSampleBuffer) {
        latestPhoto = convertCurrentSampleBufferToUIImage(currentSampleBuffer: didCaptureVideoFrame)
    }
    var imagesWithQRCode:[UIImage] = []
    var latestPhoto = UIImage()
    var videoCapture: VideoCapture!
    @IBOutlet var scannerView: UIView!
    @IBOutlet var stopButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setupCamera()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        videoCapture.start()
        self.videoCapture.delegate = self
        self.videoCapture.photoDelegate = self
        self.stopButton.isEnabled = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        imagesWithQRCode.removeAll()
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    func setupCamera() {
        videoCapture = VideoCapture()
        videoCapture.setUpCamera(sessionPreset: .hd4K3840x2160, completion: {
            preview in
            preview?.frame = self.scannerView.frame
            self.scannerView.layer.addSublayer(preview!)
            self.scannerView.bringSubviewToFront(self.stopButton)
        })
    }
    
    func convertCurrentSampleBufferToUIImage(currentSampleBuffer: CMSampleBuffer) -> UIImage {
        let imageBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(currentSampleBuffer)!
        let ciimage: CIImage = CIImage(cvPixelBuffer: imageBuffer)
        let context: CIContext = CIContext.init(options: nil)
        let cgImage: CGImage = context.createCGImage(ciimage, from: ciimage.extent)!
        let image: UIImage = UIImage.init(cgImage: cgImage)
        return image
    }
    
    func qrCodeDetectedInLiveFeed(qrCodeString: String) {
        imagesWithQRCode.append(latestPhoto)
        DispatchQueue.main.async {
            self.stopButton.isEnabled = true
        }
    }
    
    @IBAction func stopRecording(_ sender: Any) {
        videoCapture.stop()
        performSegue(withIdentifier: "ShowImages", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowImages" {
            if let imagesViewController = segue.destination as? ImagesViewController {
                imagesViewController.shortlistedImages.removeAll()
                imagesViewController.shortlistedImages = imagesWithQRCode
            }
        }
    }
    


}

