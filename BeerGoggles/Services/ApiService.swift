//
//  ApiService.swift
//  BeerGoggles
//
//  Created by Tomas Harkema on 03-11-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import Foundation
import Promissum
import CancellationToken

class ApiService: NSObject {

  private let root = URL(string: "https://api.uncheckd.com")!

  struct PendingUpload {
    let task: URLSessionUploadTask
    let promiseSource: PromiseSource<UploadJson, ApiError>
    let progressHandler: ProgressHandler?
  }

  typealias ProgressHandler = (Float) -> Void
  
  private var pendingUpload: PendingUpload?

  private let session = URLSession(configuration: .default)
  private lazy var backgroundSession: URLSession = {
    let configuration = URLSessionConfiguration.background(withIdentifier: "io.harkema.BeerGoggles.background")
    configuration.timeoutIntervalForRequest = 60 * 2
    configuration.timeoutIntervalForResource = 60 * 2
    return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
  }()

  private var backgroundCompletionHandler: (() -> Void)?

  func auth() -> Promise<AuthenticateJson, ApiError> {
    return session.codablePromise(type: AuthenticateJson.self,
                                  request: URLRequest(url: root.appendingPathComponent("/untappd/authenticate/")),
                                  cancellationToken: nil)
  }
  
  func upload(imageReference: SavedImageReference,
              cancellationToken: CancellationToken?,
              progressHandler: ProgressHandler?)
    -> (_ token: AuthenticationToken)
    -> Promise<UploadJson, ApiError> {

    return { [root, backgroundSession] token in
      
      guard let path = imageReference.fileUrl() else {
        return Promise(error: .imageReferenceUrlNotPresent)
      }
      
      let url = root.appendingPathComponent("/magic")
      var request = URLRequest(url: url)
      request.httpMethod = "POST"
      request.addValue(token.rawValue, forHTTPHeaderField: "X-Access-Token")
      print(request.curlRequest ?? "")

      let promiseSource = PromiseSource<UploadJson, ApiError>()
      let uploadTask = backgroundSession.uploadTask(with: request, fromFile: path)
      uploadTask.resume()

      cancellationToken?.register {
        uploadTask.cancel()
      }

      self.pendingUpload = PendingUpload(task: uploadTask,
                                         promiseSource: promiseSource,
                                         progressHandler: progressHandler)

      return promiseSource.promise
    }
  }

  func magic(matches: [String], cancellationToken: CancellationToken?)
    -> (_ token: AuthenticationToken)
    -> Promise<[MatchesJson], ApiError> {

    return { [root, session] token in
      do {
        let url = root.appendingPathComponent("/magic/check")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try JSONEncoder().encode(matches)
        request.addValue(token.rawValue, forHTTPHeaderField: "X-Access-Token")
  
        print(request.curlRequest ?? "")
  
        return session.codablePromise(type: [MatchesJson].self,
                                      request: request,
                                      cancellationToken: cancellationToken)
  
      } catch let error as EncodingError {
        return Promise(error: .encoding(error))
      } catch {
        return Promise(error: .unknown(error))
      }
    }
  }

}

extension ApiService: URLSessionDelegate, URLSessionDataDelegate {

  func handleFinishBackground(completionHandler: @escaping () -> Void) {
    backgroundCompletionHandler = completionHandler
  }

  func urlSession(_ session: URLSession,
                  task: URLSessionTask,
                  didSendBodyData bytesSent: Int64,
                  totalBytesSent: Int64,
                  totalBytesExpectedToSend: Int64) {
    pendingUpload?.progressHandler?(Float(totalBytesSent) / Float(totalBytesExpectedToSend))
  }
  
  func urlSession(_ session: URLSession,
                  task: URLSessionTask,
                  didCompleteWithError error: Error?) {
    guard let error = error else {
      return
    }

    if let httpError = error as? URLError,
      httpError.code == URLError.cancelled {
      
      pendingUpload?.promiseSource.reject(.cancelled)
      return
    }

    switch backgroundSession.decodeInput(type: UploadJson.self,
                                         data: nil,
                                         response: task.response,
                                         error: error) {
    case .value(let value):
      pendingUpload?.promiseSource.resolve(value)
    case .error(let error):
      pendingUpload?.promiseSource.reject(error)
    }
    
    pendingUpload = nil
  }
  
  func urlSession(_ session: URLSession,
                  dataTask: URLSessionDataTask,
                  didReceive data: Data) {
    switch backgroundSession.decodeInput(type: UploadJson.self,
                                         data: data,
                                         response: dataTask.response,
                                         error: nil) {
    case .value(let value):
      pendingUpload?.promiseSource.resolve(value)
    case .error(let error):
      pendingUpload?.promiseSource.reject(error)
    }
    
    pendingUpload = nil
  }

  func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
    DispatchQueue.main.async {
      self.backgroundCompletionHandler?()
    }
  }
}

fileprivate extension String {

  fileprivate func escapingQuotes() -> String {
    return replacingOccurrences(of: "\"", with: "\\\"")
  }

}

extension URLRequest {

  var curlRequest: String? {

    guard
      let httpMethod = self.httpMethod,
      let urlString = self.url?.absoluteString
      else {
        return nil
    }

    // Basic curl command with HTTP method
    var components = ["curl -k -X \(httpMethod) --dump-header -"]

    // Add request headers
    if let headers = allHTTPHeaderFields {
      components += headers.map { key, value in
        let escapedKey = key.escapingQuotes()
        let escapedValue = value.escapingQuotes()
        return "-H \"\(escapedKey): \(escapedValue)\""
      }
    }

    // Add request body
    if
      let data = httpBody,
      let body = String(data: data, encoding: .utf8)
    {
      if body.characters.count > 0 {
        let escapedBody = body.escapingQuotes()
        components.append("-d \"\(escapedBody)\"")
      }
    }

    // Add URL
    components.append("\"\(urlString)\"")

    return components.joined(separator: " ")
  }

}

extension URLSession {

  fileprivate func decodeInput<ResultType: Decodable>(type: ResultType.Type,
                                                      data: Data?,
                                                      response: URLResponse?,
                                                      error: Error?)
    -> ValueOrError<ResultType, ApiError> {

    guard let httpResponse = response as? HTTPURLResponse else {
      return .error(.noResponse)
    }

    guard httpResponse.statusCode == 200 else {
      return .error(.response(httpResponse))
    }

    guard let data = data else {
      return .error(.noResponse)
    }

    #if DEBUG
      print(String(data: data, encoding: .utf8))
    #endif
      
    do {
      let decoder = JSONDecoder()
      let result = try decoder.decode(type, from: data)
      return .value(result)
    } catch let error as DecodingError {
      return .error(.decoding(error))
    } catch {
      return .error(.unknown(error))
    }
  }

  func codablePromise<ResultType: Decodable>(type: ResultType.Type,
                                             request: URLRequest,
                                             cancellationToken: CancellationToken?)
    -> Promise<ResultType, ApiError> {
    let promiseSource = PromiseSource<ResultType, ApiError>()

    let task = dataTask(with: request) { (data, response, error) in
      switch self.decodeInput(type: type, data: data, response: response, error: error) {
      case .value(let value):
        promiseSource.resolve(value)
      case .error(let error):
        promiseSource.reject(error)
      }
    }
    task.resume()
    cancellationToken?.register {
      task.cancel()
    }
    return promiseSource.promise
  }

  func codableUploadPromise<ResultType: Decodable>(type: ResultType.Type,
                                                   request: URLRequest,
                                                   fromFile: URL,
                                                   cancellationToken: CancellationToken?)
    -> Promise<ResultType, ApiError> {

      let promiseSource = PromiseSource<ResultType, ApiError>()

    let task = uploadTask(with: request, fromFile: fromFile) { (data, response, error) in
      switch self.decodeInput(type: type, data: data, response: response, error: error) {
      case .value(let value):
        promiseSource.resolve(value)
      case .error(let error):
        promiseSource.reject(error)
      }
    }
    task.resume()

    cancellationToken?.register {
      task.cancel()
    }

    return promiseSource.promise
  }
}

enum ValueOrError<ValueType, ErrorType: Error> {
  case value(ValueType)
  case error(ErrorType)
}

enum ApiError: Error, LocalizedError {
  case notLoggedIn
  case noResponse
  case response(HTTPURLResponse)
  case decoding(DecodingError)
  case encoding(EncodingError)
  case unknown(Error)
  case cancelled
  case imageReferenceUrlNotPresent
  
  var errorDescription: String {
    switch self {
    case .notLoggedIn:
      return "Not Logged In"
    case .noResponse:
      return "We didn't *burp* understand the menu you scanned."
    case .response(let response):
      return "We didn't *burp* understand the menu you scanned. (\(HTTPURLResponse.localizedString(forStatusCode: response.statusCode)))"
    case .decoding(let error):
      return "We didn't *burp* understand the menu you scanned. (\(error.localizedDescription))"
    case .encoding(let error):
      return "We didn't *burp* understand the menu you scanned. (\(error.localizedDescription))"
    case .unknown(let error):
      return "We didn't *burp* understand the menu you scanned. (\(error.localizedDescription))"
    case .cancelled:
      return "Operation Cancelled"
    case .imageReferenceUrlNotPresent:
      return "derp"
    }
  }
}
