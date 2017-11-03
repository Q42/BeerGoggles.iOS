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
  case noResponse
  case response(HTTPURLResponse)
  case decoding(DecodingError)
  case unknown(Error)
}

class ApiService {
  static let shared = ApiService()

  private let session = URLSession(configuration: .default)
  private let root = URL(string: "https://beer-goggles.herokuapp.com")!

  private let loginTokenKey = "loginTokenKey"

  private func loginToken() -> String? {
    return UserDefaults.standard.string(forKey: loginTokenKey)
  }

  func isLoggedIn() -> Bool {
    return loginToken() != nil
  }

  func auth() -> Promise<AuthenticateJson, ApiError> {
    return session.codablePromise(type: AuthenticateJson.self, request: URLRequest(url: root.appendingPathComponent("/untappd/authenticate/")))
  }

  func loginToken(token: String) {
    UserDefaults.standard.set(token, forKey: loginTokenKey)
  }

}

extension URLSession {
  func codablePromise<ResultType: Decodable>(type: ResultType.Type, request: URLRequest) -> Promise<ResultType, ApiError> {
    let promiseSource = PromiseSource<ResultType, ApiError>()

    let task = dataTask(with: request) { (data, response, error) in
      guard let httpResponse = response as? HTTPURLResponse else {
        return promiseSource.reject(.noResponse)
      }

      guard httpResponse.statusCode == 200 else {
        return promiseSource.reject(.response(httpResponse))
      }

      guard let data = data else {
        promiseSource.reject(.noResponse)
        return
      }

      do {
        let decoder = JSONDecoder()
        let result = try decoder.decode(type, from: data)
        promiseSource.resolve(result)
      } catch let error as DecodingError {
        promiseSource.reject(.decoding(error))
      } catch {
        promiseSource.reject(.unknown(error))
      }
    }
    task.resume()

    return promiseSource.promise
  }
}
