//
//  OpenGraph.swift
//  Pods
//
//  Created by Bruno Oliveira on 20/07/16.
//
//

import Foundation

public struct OpenGraph {

  public let description: String?
  public let title: String?
  public let imageURL: URL?

  // MARK: HTML
  init?(html: String) {
    guard let parser = HTMLParser(html: html) else { return nil }

    title = parser.contentFromMetatag("og:title")
    description = parser.contentFromMetatag("og:description")

    if let imageMeta = parser.contentFromMetatag("og:image") {
      imageURL = URL(string: imageMeta)
    } else {
      imageURL = nil
    }
  }
}

extension OpenGraph {
  static func fetchMetadata(_ url: URL, completion: @escaping (OpenGraph?) -> Void) {
    executeRequest(url: url) { html in
      guard let html = html else {
        completion(nil)
        return
      }
      completion(OpenGraph(html: html))
    }
  }

  fileprivate static func executeRequest(url: URL, completion: @escaping (String?) -> ()) {
    let session = URLSession.shared

    let request = MutableURLRequest(url: url, cachePolicy: .returnCacheDataElseLoad,
                                      timeoutInterval: 10)
    request.setValue("Facebot", forHTTPHeaderField: "User-Agent")
    let task = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) in
      guard let data = data , error == nil else {
      completion(nil)
      return
      }
      completion(String(data: data, encoding: String.Encoding.ascii))
      })
    task.resume()
  }
}
