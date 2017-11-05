//
//  ApiService.swift
//  BeerGoggles
//
//  Created by Tomas Harkema on 03-11-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import Foundation
import Promissum

enum ApiError: Error {
  case notLoggedIn
  case noResponse
  case response(HTTPURLResponse)
  case decoding(DecodingError)
  case encoding(EncodingError)
  case unknown(Error)
  
  var localizedDescription: String {
    switch self {
    case .notLoggedIn:
      return "Not Logged In"
    case .noResponse:
      return "We didn't *burp* understand the menu you scanned."
    case .response(let response):
      return "We didn't *burp* understand the menu you scanned. (\(response.statusCode))"
    case .decoding(let error):
      return "We didn't *burp* understand the menu you scanned. (\(error.localizedDescription))"
    case .encoding(let error):
      return "We didn't *burp* understand the menu you scanned. (\(error.localizedDescription))"
    case .unknown(let error):
      return "We didn't *burp* understand the menu you scanned. (\(error.localizedDescription))"
    }
  }
}

class ApiService: NSObject {
  static let shared = ApiService()

  private var pendingUpload: (URLSessionUploadTask, PromiseSource<UploadJson, ApiError>)?
  private let session = URLSession(configuration: .default)
  private lazy var backgroundSession: URLSession = {
    return URLSession(configuration: .background(withIdentifier: "io.harkema.BeerGoggles.background"), delegate: self, delegateQueue: nil)
  }()

  private let root = URL(string: "https://beer-goggles.herokuapp.com")!

  private let loginTokenKey = "loginTokenKey"

  private func loginToken() -> String? {
    return UserDefaults.standard.string(forKey: loginTokenKey)
  }

  func isLoggedIn() -> Bool {
    return loginToken() != nil
  }

  func login(with token: String) {
    UserDefaults.standard.set(token, forKey: loginTokenKey)
  }

  func logout() {
    UserDefaults.standard.removeObject(forKey: loginTokenKey)
  }

  func auth() -> Promise<AuthenticateJson, ApiError> {
    return session.codablePromise(type: AuthenticateJson.self, request: URLRequest(url: root.appendingPathComponent("/untappd/authenticate/")))
  }

  func upload(photo: URL) -> Promise<UploadJson, ApiError> {
    guard let loginToken = loginToken() else {
      return Promise(error: .notLoggedIn)
    }

    let url = root.appendingPathComponent("/magic")
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue(loginToken, forHTTPHeaderField: "X-Access-Token")
    print(request.curlRequest ?? "")

    let promiseSource = PromiseSource<UploadJson, ApiError>()
    let uploadTask = backgroundSession.uploadTask(with: request, fromFile: photo)
    uploadTask.resume()
    pendingUpload = (uploadTask, promiseSource)

    return promiseSource.promise
  }

  func magic(matches: [String]) -> Promise<[MatchesJson], ApiError> {
    guard let loginToken = loginToken() else {
      return Promise(error: .notLoggedIn)
    }

    do {
      let url = root.appendingPathComponent("/magic/check")
      var request = URLRequest(url: url)
      request.httpMethod = "POST"
      request.httpBody = try JSONEncoder().encode(matches)
      request.addValue(loginToken, forHTTPHeaderField: "X-Access-Token")
      print(request.curlRequest ?? "")
      return session.codablePromise(type: [MatchesJson].self, request: request)

    } catch let error as EncodingError {
      return Promise(error: .encoding(error))
    } catch {
      return Promise(error: .unknown(error))
    }
  }

}

extension ApiService: URLSessionDelegate, URLSessionTaskDelegate, URLSessionDataDelegate {
  func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    guard let error = error else {
      return
    }
    
    switch backgroundSession.decodeInput(type: UploadJson.self, data: nil, response: task.response, error: error) {
    case .value(let value):
      pendingUpload?.1.resolve(value)
    case .error(let error):
      pendingUpload?.1.reject(error)
    }
  }
  
  func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
  switch backgroundSession.decodeInput(type: UploadJson.self, data: data, response: dataTask.response, error: nil) {
    case .value(let value):
      pendingUpload?.1.resolve(value)
    case .error(let error):
      pendingUpload?.1.reject(error)
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

enum ValueOrError<ValueType, ErrorType: Error> {
  case value(ValueType)
  case error(ErrorType)
}

extension URLSession {

  fileprivate func decodeInput<ResultType: Decodable>(type: ResultType.Type, data: Data?, response: URLResponse?, error: Error?) -> ValueOrError<ResultType, ApiError> {

    guard let httpResponse = response as? HTTPURLResponse else {
      return .error(.noResponse)
    }

    guard httpResponse.statusCode == 200 else {
      return .error(.response(httpResponse))
    }

    guard let data = data else {
      return .error(.noResponse)
    }

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

  func codablePromise<ResultType: Decodable>(type: ResultType.Type, request: URLRequest) -> Promise<ResultType, ApiError> {
    let promiseSource = PromiseSource<ResultType, ApiError>()

    let task = dataTask(with: request) { (data, response, error) in
      print(try? data.flatMap({ try JSONSerialization.jsonObject(with: $0, options: []) }))
      switch self.decodeInput(type: type, data: data, response: response, error: error) {
      case .value(let value):
        promiseSource.resolve(value)
      case .error(let error):
        promiseSource.reject(error)
      }
    }
    task.resume()

    return promiseSource.promise
  }

  func codableUploadPromise<ResultType: Decodable>(type: ResultType.Type, request: URLRequest, fromFile: URL) -> Promise<ResultType, ApiError> {
    let promiseSource = PromiseSource<ResultType, ApiError>()

    let task = uploadTask(with: request, fromFile: fromFile) { (data, response, error) in
      print(try? data.flatMap({ try JSONSerialization.jsonObject(with: $0, options: []) }))
      switch self.decodeInput(type: type, data: data, response: response, error: error) {
      case .value(let value):
        promiseSource.resolve(value)
      case .error(let error):
        promiseSource.reject(error)
      }
    }
    task.resume()

    return promiseSource.promise
  }
}
