//
//  CameraController.swift
//  BeerGoggles
//
//  Created by Tomas Harkema on 03-11-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import UIKit
import AVKit
import Promissum
import CancellationToken

class CameraController: ViewController {

  private var session: AVCaptureSession?
  private var stillImageOutput: AVCapturePhotoOutput?
  private var videoPreviewLayer: AVCaptureVideoPreviewLayer?

  private var cancellationTokenSource: CancellationTokenSource!
  
  @IBOutlet weak private var captureButton: UIButton!
  @IBOutlet weak private var captureView: UIView!

  init() {
    super.init(nibName: R.nib.cameraView.name, bundle: R.nib.cameraView.bundle)
    title = "NEW SCAN"
    tabBarItem = UITabBarItem(title: "NEW SCAN", image: R.image.newScan(), tag: 0)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    navigationItem.titleView = UIView(frame: .zero)

    #if !((arch(i386) || arch(x86_64)) && os(iOS))
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
    #endif
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    session?.startRunning()
    captureButton.isHidden = false
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    session?.stopRunning()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    videoPreviewLayer?.frame = captureView.bounds
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }

  @IBAction private func didPressCapture(_ sender: Any) {
    #if (arch(i386) || arch(x86_64)) && os(iOS)
      simulateImage()
    #else
      captureButton.isHidden = true
      let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey : AVVideoCodecJPEG])
      settings.flashMode = .on
      settings.isAutoStillImageStabilizationEnabled = true
      settings.isHighResolutionPhotoEnabled = true
      stillImageOutput?.capturePhoto(with: settings, delegate: self)
      captureButton.isHidden = true
    #endif
  }

  private func simulateImage(sessionIdentifier: SessionIdentifier = SessionIdentifier()) {
    cancellationTokenSource = CancellationTokenSource()
    
    let promise = App.imageService.upload(originalUrl: R.file.beerMenuJpg()!, identifier: sessionIdentifier, cancellationToken: cancellationTokenSource.token, progressHandler: { print($0) })
    
    handle(promise: promise, retry: { [weak self] in
      self?.simulateImage(sessionIdentifier: sessionIdentifier)
    })
  }

  @available(iOS 11.0, *)
  private func upload(photo: AVCapturePhoto, sessionIdentifier: SessionIdentifier = SessionIdentifier()) {
    cancellationTokenSource = CancellationTokenSource()
    handle(promise: App.imageService.upload(photo: photo, identifier: sessionIdentifier, cancellationToken: cancellationTokenSource.token, progressHandler: { print($0) }), retry: { [weak self] in
      self?.upload(photo: photo, sessionIdentifier: sessionIdentifier)
    })
  }

  // Enable backwards compatibility for iOS 10
  private func upload(sampleBuffer: CMSampleBuffer, sessionIdentifier: SessionIdentifier = SessionIdentifier()) {
    cancellationTokenSource = CancellationTokenSource()

    let promise = App.imageService.upload(buffer: sampleBuffer, identifier: sessionIdentifier, cancellationToken: cancellationTokenSource.token, progressHandler: nil)
    handle(promise: promise) { [weak self] in
      self?.upload(sampleBuffer: sampleBuffer, sessionIdentifier: sessionIdentifier)
    }
  }
  
  private func handle(promise: Promise<(UploadJson, SessionIdentifier), Error>, retry: @escaping () -> Void) {
    promise.presentLoader(for: self, cancellationTokenSource: cancellationTokenSource, message: .scanning, handler: { (result, identifier) in
      BeerResultCoordinator.controller(for: result, identifier: identifier)
    }).attachError(for: self, handler: { [navigationController] (controller) in
      print("ERROR HANDLED")
      navigationController?.popViewController(animated: true)
      retry()
    })
  }

}

extension CameraController: AVCapturePhotoCaptureDelegate {
  
  func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
    guard let buffer = photoSampleBuffer else {
      return
    }
    
    upload(sampleBuffer: buffer)
  }
  
  @available(iOS 11.0, *)
  func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
    upload(photo: photo)
    captureButton.isHidden = false
  }
}
