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
    title = "Camera"
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
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    session?.stopRunning()
  }

  @IBAction func didPressCapture(_ sender: Any) {
    let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey : AVVideoCodecJPEG])
    settings.flashMode = .on
    settings.isAutoStillImageStabilizationEnabled = true
    settings.isHighResolutionPhotoEnabled = true
    stillImageOutput?.capturePhoto(with: settings, delegate: self)
  }
}

extension CameraController: AVCapturePhotoCaptureDelegate {
  func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
    let guid = UUID()
    
    let fileOptional = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
      .first
      .flatMap { URL(string: $0) }?
      .appendingPathComponent("\(guid).jpg")

    guard let file = fileOptional, let photoData = photo.fileDataRepresentation() else {
      return
    }

    FileManager.default.createFile(atPath: file.absoluteString, contents: photoData, attributes: nil)
    navigationController?.pushViewController(PhotoUploadController(file: file), animated: true)
  }

}
