//
//  ImageService.swift
//  BeerGoggles
//
//  Created by Tomas Harkema on 09-11-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import Foundation
import Promissum
import AVKit
import CancellationToken

class ImageService {

  private let apiService: ApiService
  private let databaseService: DatabaseService
  private let authenticationService: AuthenticationService
  private let pendingHandleKey = "pendingHandleKey"
  
  init(apiService: ApiService,
       databaseService: DatabaseService,
       authenticationService: AuthenticationService) {
    self.apiService = apiService
    self.databaseService = databaseService
    self.authenticationService = authenticationService
  }

  var pendingGUID: SessionIdentifier? {
    set {
      UserDefaults.standard.set(pendingGUID?.rawValue.uuidString, forKey: pendingHandleKey)
    }
    get {
      return UserDefaults.standard.string(forKey: pendingHandleKey)
        .flatMap { UUID(uuidString: $0) }
        .map { SessionIdentifier(rawValue: $0) }
    }
  }
  
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

  func save(data: Data, identifier: SessionIdentifier) -> Promise<URL, Error> {
    return promisify({
      let dir = NSTemporaryDirectory()
      guard let url = URL(string: "file://\(dir)\(identifier.rawValue).jpg") else {
        throw NSError(domain: "", code: 0, userInfo: nil)
      }
      
      FileManager.default.createFile(atPath: url.absoluteString.replacingOccurrences(of: "file://", with: ""), contents: data, attributes: nil)
      
      return url
    })
  }
  
  @available(iOS 11.0, *)
  private func conform(photo: AVCapturePhoto, fileSize: Int = 8 * 1024) -> Promise<Data, Error> {
    return promisify({
      guard let photoData = photo.fileDataRepresentation(),
        let image = UIImage(data: photoData)
        else {
          // TODO: fix error
          throw NSError(domain: "", code: 0, userInfo: nil)
        }

      let finalImageData: Data
      if photoData.count > fileSize {
        finalImageData = self.compress(image: image, maxFileSize: fileSize)
      } else {
        finalImageData = photoData
      }

      return finalImageData
    })
  }

  // Provide backwards compatibility for iOS 10
  private func conform(buffer: CMSampleBuffer, fileSize: Int = 8 * 1024) -> Promise<Data, Error> {
    return promisify({
      guard let photoData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer),
        let image = UIImage(data: photoData)
        else {
          // TODO: fix error
          throw NSError(domain: "", code: 0, userInfo: nil)
        }
      
      let finalImageData: Data
      if photoData.count > fileSize {
        finalImageData = self.compress(image: image, maxFileSize: fileSize)
      } else {
        finalImageData = photoData
      }
      
      return finalImageData
    })
  }

  @available(iOS 11.0, *)
  func upload(photo: AVCapturePhoto, identifier: SessionIdentifier, cancellationToken: CancellationToken?, progressHandler: ApiService.ProgressHandler?) -> Promise<(UploadJson, SessionIdentifier), Error> {
    return conform(photo: photo)
      .flatMap { self.upload(imageData: $0, identifier: identifier, cancellationToken: cancellationToken, progressHandler: progressHandler) }
  }

  // Provide backwards compatibility for iOS 10
  func upload(buffer: CMSampleBuffer, identifier: SessionIdentifier, cancellationToken: CancellationToken?, progressHandler: ApiService.ProgressHandler?) -> Promise<(UploadJson, SessionIdentifier), Error> {
    return conform(buffer: buffer)
      .flatMap { self.upload(imageData: $0, identifier: identifier, cancellationToken: cancellationToken, progressHandler: progressHandler) }
  }
  
  func upload(originalUrl: URL, identifier: SessionIdentifier, cancellationToken: CancellationToken?, progressHandler: ApiService.ProgressHandler?) -> Promise<(UploadJson, SessionIdentifier), Error> {
    return promisify({ try Data(contentsOf: originalUrl) })
      .flatMap { self.upload(imageData: $0, identifier: identifier, cancellationToken: cancellationToken, progressHandler: progressHandler) }
  }

  private func upload(imageData: Data, identifier: SessionIdentifier, cancellationToken: CancellationToken?, progressHandler: ApiService.ProgressHandler?) -> Promise<(UploadJson, SessionIdentifier), Error> {
    pendingGUID = identifier
    return databaseService.initial(identifier: identifier, imageData: imageData)
      .flatMap { [authenticationService, apiService] in
        return self.save(data: imageData, identifier: identifier)
          .flatMap { [authenticationService, apiService] url in
            authenticationService.wrapAuthenticate(apiService.upload(imageURL: url, cancellationToken: cancellationToken, progressHandler: progressHandler)).mapError()
          }
      }
      .flatMap { [databaseService] (result: UploadJson) in
        databaseService.save(beers: result.matches, identifier: identifier, imageData: imageData)
          .map { _ in (result, identifier) }
      }
      .finally {
        self.pendingGUID = nil
      }
  }

  //TODO: find a better place for this
  func magic(strings: [String], matches: [BeerJson], identifier: SessionIdentifier) -> Promise<([BeerJson], SessionIdentifier), Error> {
    return authenticationService.wrapAuthenticate(apiService.magic(matches: strings, cancellationToken: nil))
      .mapError()
      .flatMap { [databaseService] result in
        databaseService.add(beers: result, identifier: identifier)
          .map { (result, identifier) }
      }
  }
  
  func retry(session: Session, cancellationToken: CancellationToken?, progressHandler: ApiService.ProgressHandler?) -> Promise<(UploadJson, SessionIdentifier), Error> {
    
    guard let imageData = session.imageData else {
      return Promise(error: NSError(domain: "", code: 0, userInfo: nil))
    }
    
    return save(data: imageData, identifier: session.identifier)
      .flatMap { [authenticationService, apiService] url in
        authenticationService.wrapAuthenticate(apiService.upload(imageURL: url, cancellationToken: cancellationToken, progressHandler: progressHandler))
          .mapError()
      }
      .flatMap { [databaseService] (result: UploadJson) in
        databaseService.save(beers: result.matches, identifier: session.identifier)
          .map { (result, session.identifier) }
      }
  }
  
  func retryAll(cancellationToken: CancellationToken?) -> Promise<Void, Error> {
    return databaseService.sessions()
      .flatMap { sessions in
        whenAllFinalized(sessions.map { session in
          self.retry(session: session, cancellationToken: cancellationToken, progressHandler: nil)
        }).mapError()
      }
      .mapVoid()
  }
}

func promisify<ValueType>(_ hander: @escaping () throws -> ValueType, queue: DispatchQueue = DispatchQueue.global()) -> Promise<ValueType, Swift.Error> {
  let promiseSource = PromiseSource<ValueType, Swift.Error>()

  queue.async {
    do {
      promiseSource.resolve(try hander())
    } catch {
      promiseSource.reject(error)
    }
  }

  return promiseSource.promise
}
