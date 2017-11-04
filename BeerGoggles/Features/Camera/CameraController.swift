//
//  CameraController.swift
//  BeerGoggles
//
//  Created by Tomas Harkema on 03-11-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import UIKit
import AVKit

class CameraController: UIViewController {

  private var session: AVCaptureSession?
  private var stillImageOutput: AVCapturePhotoOutput?
  private var videoPreviewLayer: AVCaptureVideoPreviewLayer?

  @IBOutlet weak private var captureView: UIView!

  init() {
    super.init(nibName: "CameraView", bundle: nil)
    
    title = "START"
    tabBarItem = UITabBarItem(title: "START", image: R.image.home(), tag: 0)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    videoPreviewLayer?.frame = captureView.bounds
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    do {
      session = AVCaptureSession()
      session?.sessionPreset = .photo
      stillImageOutput = AVCapturePhotoOutput()
      stillImageOutput?.isHighResolutionCaptureEnabled = true

      guard let device = AVCaptureDevice.default(for: .video), let stillImageOutput = stillImageOutput, let session = session else {
        return
      }

      let input = try AVCaptureDeviceInput(device: device)

      if session.canAddInput(input) {
        session.addInput(input)
      }

      if session.canAddOutput(stillImageOutput) {
        session.addOutput(stillImageOutput)
      }

      videoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)

      guard let videoPreviewLayer = videoPreviewLayer else {
        return
      }

      videoPreviewLayer.frame = captureView.bounds
      videoPreviewLayer.videoGravity = .resizeAspectFill
      videoPreviewLayer.connection?.videoOrientation = .portrait
      captureView?.layer.addSublayer(videoPreviewLayer)
    } catch {
      print(error)
    }
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    session?.startRunning()
    navigationController?.setNavigationBarHidden(true, animated: animated)
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    session?.stopRunning()
    navigationController?.setNavigationBarHidden(false, animated: animated)
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }

  @IBAction func didPressCapture(_ sender: Any) {
    let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey : AVVideoCodecType.jpeg])
    settings.flashMode = .on
    settings.isAutoStillImageStabilizationEnabled = true
    settings.isHighResolutionPhotoEnabled = true
    stillImageOutput?.capturePhoto(with: settings, delegate: self)
  }
}

extension CameraController: AVCapturePhotoCaptureDelegate {

  private func compress(image: UIImage, maxFileSize: Int) -> Data {
    var compression = 1.0
    let maxCompression = 0.1
    var imageData = UIImageJPEGRepresentation(image, 0.9)!

    while (imageData.count > maxFileSize && compression > maxCompression) {
      compression -= 0.1;
      imageData = UIImageJPEGRepresentation(image, CGFloat(compression))!
    }

    return imageData
  }

  func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
    let guid = UUID()
    
    let fileOptional = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
      .first
      .flatMap { URL(string: $0) }?
      .appendingPathComponent("\(guid).jpg")

    guard let file = fileOptional,
      let photoData = photo.fileDataRepresentation(),
      let image = UIImage(data: photoData)
      else {
        return
      }

    let maxSize = 8 * 1024

    let finalImageData: Data
    if photoData.count > maxSize {
      finalImageData = compress(image: image, maxFileSize: maxSize)
    } else {
      finalImageData = photoData
    }

    FileManager.default.createFile(atPath: file.absoluteString, contents: finalImageData, attributes: nil)
    navigationController?.pushViewController(LoadingController(request: .photo(file: file, guid: guid)), animated: true)
  }

}
