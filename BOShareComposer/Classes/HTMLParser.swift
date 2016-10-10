//
//  HTMLParser.swift
//  Pods
//
//  Created by Bruno Oliveira on 20/07/16.
//
//

import Foundation
import Kanna

class HTMLParser {

  fileprivate let document: HTMLDocument

  init?(html: String) {
    guard let document = Kanna.HTML(html: html, encoding: String.Encoding.utf8) else { return nil }

    self.document = document
  }

  func contentFromMetatag(_ metatag: String) -> String? {
    return document.head?.xpath(xpathForMetatag(metatag)).first?["content"]
  }

  fileprivate func xpathForMetatag(_ metatag: String) -> String {
    return "//meta[@property='\(metatag)'] | //meta[@name='\(metatag)']"
  }
}
