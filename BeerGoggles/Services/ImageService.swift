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

class ImageService {

  private let apiService: ApiService
  private let databaseService: DatabaseService
  private let authenticationService: AuthenticationService
  
  init(apiService: ApiService, databaseService: DatabaseService, authenticationService: AuthenticationService) {
    self.apiService = apiService
    self.databaseService = databaseService
    self.authenticationService = authenticationService
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

  private func save(data: Data, fileName: String) -> Promise<URL, Error> {
    return promisify({
      let fileOptional = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        .first
        .flatMap { URL(string: $0) }?
        .appendingPathComponent("\(fileName).jpg")

      guard let file = fileOptional else {
        // TODO: better error
        throw NSError(domain: "", code: 0, userInfo: nil)
      }

      FileManager.default.createFile(atPath: file.absoluteString, contents: data, attributes: nil)

      return URL(string: "file://\(file.absoluteString)")!
    })
  }

  func upload(photo: AVCapturePhoto, progressHandler: ApiService.ProgressHandler?) -> Promise<(UploadJson, UUID), Error> {
    let guid = UUID()
    return conform(photo: photo)
      .flatMap { self.save(data: $0, fileName: guid.uuidString) }
      .flatMap { self.upload(file: $0, guid: guid, progressHandler: progressHandler) }
  }

  func upload(file: URL, guid: UUID, progressHandler: ApiService.ProgressHandler?) -> Promise<(UploadJson, UUID), Error> {
    return promisify({ try Data(contentsOf: file) })
      .flatMap {
        self.save(data: $0, fileName: guid.uuidString)
      }
      .flatMap { [authenticationService, apiService] (url: URL) -> Promise<UploadJson, Error> in
        authenticationService.wrapAuthenticate(apiService.upload(photo: url, progressHandler: progressHandler)).mapError()
      }
      .flatMap { [databaseService] (result: UploadJson) -> Promise<(UploadJson, UUID), Error> in
        databaseService.save(beers: result.matches.map({ $0.beer }), image: guid)
          .map { _ in (result, guid) }
      }
  }

  //TODO: find a better place for this
  func magic(strings: [String], matches: [MatchesJson], guid: UUID) -> Promise<([MatchesJson], UUID), Error> {
    return authenticationService.wrapAuthenticate(apiService.magic(matches: strings))
      .mapError()
      .flatMap { [databaseService] (result: [MatchesJson]) -> Promise<([MatchesJson], UUID), Error> in
        databaseService.add(beers: result.map({ $0.beer }), id: guid)
          .map { (result, guid) }
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
