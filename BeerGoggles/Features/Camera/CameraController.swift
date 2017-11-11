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

class CameraController: UIViewController {

  private var session: AVCaptureSession?
  private var stillImageOutput: AVCapturePhotoOutput?
  private var videoPreviewLayer: AVCaptureVideoPreviewLayer?

  private var cancellationTokenSource: CancellationTokenSource!
  
  @IBOutlet weak private var captureButton: UIButton!
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
    #if (arch(i386) || arch(x86_64)) && os(iOS)
      
    #else
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
    navigationController?.setNavigationBarHidden(true, animated: animated)
    captureButton.isHidden = false
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    session?.stopRunning()
    navigationController?.setNavigationBarHidden(false, animated: animated)
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }

  @IBAction private func didPressCapture(_ sender: Any) {
    #if (arch(i386) || arch(x86_64)) && os(iOS)
      simulateImage()
    #else
      captureButton.isHidden = true
      let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey : AVVideoCodecType.jpeg])
      settings.flashMode = .on
      settings.isAutoStillImageStabilizationEnabled = true
      settings.isHighResolutionPhotoEnabled = true
      stillImageOutput?.capturePhoto(with: settings, delegate: self)
      captureButton.isHidden = true
    #endif
  }

  private func simulateImage() {
    cancellationTokenSource = CancellationTokenSource()
    handle(promise: App.imageService.upload(file: R.file.beerMenuJpg()!, guid: UUID(), cancellationToken: cancellationTokenSource.token, progressHandler: { print($0) }), retry: { [weak self] in
      self?.simulateImage()
    })
  }

  private func upload(photo: AVCapturePhoto) {
    cancellationTokenSource = CancellationTokenSource()
    handle(promise: App.imageService.upload(photo: photo, cancellationToken: cancellationTokenSource.token, progressHandler: { print($0) }), retry: { [weak self] in
      self?.upload(photo: photo)
    })
  }

  private func handle(promise: Promise<(UploadJson, UUID), Error>, retry: @escaping () -> Void) {
    promise.presentLoader(for: self, cancellationTokenSource: cancellationTokenSource, handler: { (result, guid) in
      BeerResultCoordinator.controller(for: result, guid: guid)
    }).attachError(for: self, handler: { [weak self, navigationController] (controller) in
      print("ERROR HANDLED")
      navigationController?.popViewController(animated: true)
      retry()
    })
  }

}

extension CameraController: AVCapturePhotoCaptureDelegate {
  func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
    upload(photo: photo)
    captureButton.isHidden = false
  }
}
