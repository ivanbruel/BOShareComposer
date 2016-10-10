//
//  UIImage+Download.swift
//  Pods
//
//  Created by Bruno Oliveira on 20/07/16.
//
//

import UIKit

extension UIImageView {

  func setImage(withUrl url: URL) {
    let session = URLSession.shared
    let request = MutableURLRequest(url: url, cachePolicy: .returnCacheDataElseLoad,
                                      timeoutInterval: 10)
    let task = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) in
      DispatchQueue.main.async {
        guard let data = data , error == nil else {
          self.image = nil
          return
        }
        self.fadeSetImage(UIImage(data: data))
      }
    })

    task.resume()
  }

  func fadeSetImage(_ image:UIImage?) {
    UIView.transition(with: self,
                      duration: 0.3,
                      options: .transitionCrossDissolve,
                      animations: {
                        self.image = image
      }, completion: nil)
  }
}
