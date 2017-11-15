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

  var pendingGUID: SavedImageReference? {
    set {
      UserDefaults.standard.set(pendingGUID?.rawValue.rawValue.uuidString, forKey: pendingHandleKey)
    }
    get {
      return UserDefaults.standard.string(forKey: pendingHandleKey)
        .flatMap { UUID(uuidString: $0) }
        .map { SavedImageReference(rawValue: ImageReference(rawValue: $0)) }
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

  private func save(data: Data, imageReference: ImageReference) -> Promise<SavedImageReference, Error> {
    return promisify({
      guard let file = imageReference.url() else {
        // TODO: better error
        throw NSError(domain: "", code: 0, userInfo: nil)
      }

      FileManager.default.createFile(atPath: file.absoluteString, contents: data, attributes: nil)

      return SavedImageReference(rawValue: imageReference)//URL(string: "file://\(file.absoluteString)")!
    })
  }

  func upload(photo: AVCapturePhoto, imageReference: ImageReference, cancellationToken: CancellationToken?, progressHandler: ApiService.ProgressHandler?) -> Promise<(UploadJson, SavedImageReference), Error> {
    return conform(photo: photo)
      .flatMap { self.save(data: $0, imageReference: imageReference) }
      .flatMap { savedImageReference in self.upload(imageReference: savedImageReference, cancellationToken: cancellationToken, progressHandler: progressHandler) }
  }
  
  func upload(originalUrl: URL, imageReference: ImageReference, cancellationToken: CancellationToken?, progressHandler: ApiService.ProgressHandler?) -> Promise<(UploadJson, SavedImageReference), Error> {
    return promisify({ try Data(contentsOf: originalUrl) })
      .flatMap { self.save(data: $0, imageReference: imageReference) }
      .flatMap { self.upload(imageReference: $0, cancellationToken: cancellationToken, progressHandler: progressHandler) }
  }

  private func upload(imageReference: SavedImageReference, cancellationToken: CancellationToken?, progressHandler: ApiService.ProgressHandler?) -> Promise<(UploadJson, SavedImageReference), Error> {
    pendingGUID = imageReference
    return databaseService.initial(imageReference: imageReference)
      .flatMap { [authenticationService, apiService] in
        authenticationService.wrapAuthenticate(apiService.upload(imageReference: imageReference, cancellationToken: cancellationToken, progressHandler: progressHandler)).mapError()
      }
      .flatMap { [databaseService] (result: UploadJson) in
        databaseService.save(beers: result.matches, imageReference: imageReference)
          .map { _ in (result, imageReference) }
      }
      .finally {
        self.pendingGUID = nil
      }
  }

  //TODO: find a better place for this
  func magic(strings: [String], matches: [MatchesJson], imageReference: SavedImageReference) -> Promise<([MatchesJson], SavedImageReference), Error> {
    return authenticationService.wrapAuthenticate(apiService.magic(matches: strings, cancellationToken: nil))
      .mapError()
      .flatMap { [databaseService] result in
        databaseService.add(beers: result.map({ $0.beer }), imageReference: imageReference)
          .map { (result, imageReference) }
      }
  }
  
  func retry(session: Session, cancellationToken: CancellationToken?) -> Promise<(UploadJson, SavedImageReference), Error> {
    return authenticationService.wrapAuthenticate(apiService.upload(imageReference: session.imageReference, cancellationToken: cancellationToken, progressHandler: nil))
      .mapError()
      .flatMap { [databaseService] (result: UploadJson) in
        databaseService.save(beers: result.matches.map({ $0.beer }), imageReference: session.imageReference)
          .map { (result, session.imageReference) }
      }
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
