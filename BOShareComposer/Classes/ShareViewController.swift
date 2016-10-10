//
//  ShareViewController.swift
//  BOShareComposer
//
//  Created by Bruno Oliveira on 19/07/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit
import SnapKit
import WebKit

public extension ShareViewController {
  public static func presentShareViewController(from viewController: UIViewController,
                                                     shareContent: ShareContent,
                                                     options: ShareOptions = ShareOptions(),
                                                     completion: @escaping ((Bool, ShareContent?) -> ())) {


    let shareViewController = ShareViewController()
    shareViewController.completion = completion
    shareViewController.options = options
    shareViewController.shareContent = shareContent
    shareViewController.modalPresentationStyle = .overCurrentContext
    viewController.present(shareViewController, animated: false, completion: nil)
  }
}

open class ShareViewController: UIViewController {

  fileprivate var metadataImageViewSize = CGSize(width: 70, height: 70)

  fileprivate var shareContent: ShareContent? {
    willSet(value) {
      if let currentValue = shareContent, let newValue = value
        , newValue.link == currentValue.link {
        return
      }
      guard let newValue = value else {
        return
      }
      loadMetadata(newValue)
    }
    didSet {
      guard let shareContent = shareContent else {
        return
      }
      popupBody.text = shareContent.text

      if shareContent.link == nil {
        showMetadata = false
      }
    }
  }

  fileprivate var options: ShareOptions? {
    didSet {
      guard let options = options else {
        return
      }
      dismissButton.tintColor = options.tintColor
      dismissButton.setTitle(options.dismissText, for: UIControlState())
      dismissButton.setTitleColor(options.tintColor, for: UIControlState())

      confirmButton.titleLabel?.textColor = options.tintColor
      confirmButton.setTitle(options.confirmText, for: UIControlState())
      confirmButton.setTitleColor(options.tintColor, for: UIControlState())

      popupTitle.text = options.title
      popupBody.resignFirstResponder()
      popupBody.keyboardAppearance = options.keyboardAppearance
      popupBody.becomeFirstResponder()
      showMetadata = options.showMetadata
    }
  }

  fileprivate var showMetadata = true {
    didSet {
      guard !metadataImageView.constraints.isEmpty else {
        return
      }
      let size = showMetadata ? metadataImageViewSize : CGSize.zero
      metadataImageView.snp_updateConstraints { make in
        make.height.equalTo(size.height)
        make.width.equalTo(size.width)
      }
      UIView.animate(withDuration: 0.5, animations: {
        self.metadataImageView.layoutIfNeeded()
      }) 
    }
  }

  fileprivate var completion: ((Bool, ShareContent?) -> ())?

  lazy var dismissButton: UIButton = {
    let button = UIButton(type: .custom)
    button.addTarget(self, action: #selector(cancelAction), for: .touchUpInside)
    button.titleLabel?.font = UIFont.systemFont(ofSize: 15)
    button.titleLabel?.textAlignment = .right
    return button
  }()

  lazy var confirmButton: UIButton = {
    let button = UIButton(type: .custom)
    button.addTarget(self, action: #selector(sendAction), for: .touchUpInside)
    button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17)
    button.titleLabel?.textAlignment = .left
    return button
  }()

  lazy var popupTitle: UILabel = {
    let label = UILabel()
    label.font = UIFont.systemFont(ofSize: 17)
    label.minimumScaleFactor = 0.5
    label.adjustsFontSizeToFitWidth = true
    label.textAlignment = .center
    return label
  }()

  lazy var titleDivider: UIView = {
    let view = UIView()
    view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
    return view
  }()

  lazy var popupBody: UITextView = {
    let textField = UITextView()
    textField.isEditable = true
    textField.backgroundColor = UIColor.clear
    textField.isScrollEnabled = true
    textField.font = UIFont.systemFont(ofSize: 17)
    textField.becomeFirstResponder()
    return textField
  }()

  lazy var metadataImageView: UIImageView = {
    let imageView = UIImageView()
    imageView.contentMode = .scaleAspectFill
    imageView.clipsToBounds = true
    imageView.backgroundColor = UIColor.white
    imageView.layer.borderWidth = 1
    imageView.layer.borderColor = UIColor.black.withAlphaComponent(0.3).cgColor
    return imageView
  }()

  lazy var backgroundView: UIView = {
    let view = UIView()
    view.backgroundColor = UIColor.black.withAlphaComponent(0.6)
    return view
  }()

  lazy var containerView: UIVisualEffectView = {
    let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .extraLight))
    visualEffectView.layer.cornerRadius = 8
    visualEffectView.clipsToBounds = true
    visualEffectView.alpha = 0
    return visualEffectView
  }()

  var metadataWebView = WKWebView()

  override open func viewDidLoad() {
    super.viewDidLoad()
    setupViews()
  }

  open override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    showView()
  }

  open override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    hideView()
  }

  open override var preferredStatusBarStyle : UIStatusBarStyle {
    return .lightContent
  }

  func cancelAction() {
    shareContent?.text = popupBody.text
    completion?(false, shareContent)
    hideView { _ in
      self.dismiss(animated: false, completion: nil)
    }
  }

  func sendAction() {
    shareContent?.text = popupBody.text
    completion?(true, shareContent)
    hideView { _ in
      self.dismiss(animated: false, completion: nil)
    }
  }
}

extension ShareViewController: WKNavigationDelegate {
  public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!,
                      withError error: Error) {
    print("failed navigation")
  }

  public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    let dispatchTime: DispatchTime =
      DispatchTime.now() + Double(Int64(1 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)

    DispatchQueue.main.asyncAfter(deadline: dispatchTime, execute: {
      self.snapWebView(webView)
    })
  }
}

extension ShareViewController {

  fileprivate func loadMetadata(_ shareContent: ShareContent) {
    guard let link = shareContent.link , self.showMetadata else {
      print("No link found / metadata disabled")
      return
    }

    OpenGraph.fetchMetadata(link, completion: { [weak self] (response) in
      guard let response = response, let imageURL = response.imageURL else {
        self?.loadWebView(link)
        return
      }
      self?.metadataImageView.setImage(withUrl: imageURL)
      })
  }

  fileprivate func loadWebView(_ url: URL) {
    metadataWebView.navigationDelegate = self
    metadataWebView.load(URLRequest(url: url))
  }

  fileprivate func snapWebView(_ webView: WKWebView) {
    metadataImageView.fadeSetImage(webView.screenshot)
  }

  fileprivate func showView() {
    UIView.animate(withDuration: 0.7, animations: {
      self.containerView.alpha = 1
    }) 
  }

  fileprivate func hideView(_ completion: ((Bool)->())? = nil) {
    popupBody.resignFirstResponder()
    UIView.animate(withDuration: 0.5, animations: {
      self.backgroundView.alpha = 0
    }) 

    UIView.animate(withDuration: 0.5,
                               animations: {
                                self.containerView.alpha = 0
      },
                               completion: completion)
  }

  fileprivate func setupViews() {
    view.backgroundColor = UIColor.white.withAlphaComponent(0.1)
    view.addSubview(backgroundView)
    backgroundView.snp_makeConstraints { make in
      make.edges.equalTo(self.view)
    }

    view.addSubview(containerView)

    containerView.snp_makeConstraints { make in
      make.top.equalTo(backgroundView).inset(70)
      make.left.equalTo(backgroundView).inset(16)
      make.right.equalTo(backgroundView).inset(16)
    }

    let contentView = containerView.contentView
    contentView.addSubview(dismissButton)
    dismissButton.snp_makeConstraints { make in
      make.top.equalTo(contentView)
      make.left.equalTo(contentView).inset(8)
      make.height.equalTo(40)
    }
    dismissButton.setContentCompressionResistancePriority(UILayoutPriority.init(1000), for: UILayoutConstraintAxis.horizontal)


    contentView.addSubview(confirmButton)
    confirmButton.snp_makeConstraints { make in
      make.top.equalTo(contentView)
      make.right.equalTo(contentView).inset(8)
      make.height.equalTo(40)
    }
    confirmButton.setContentCompressionResistancePriority(UILayoutPriority.init(1000),
                                                          for: .horizontal)

    contentView.addSubview(titleDivider)
    titleDivider.snp_makeConstraints { make in
      make.top.equalTo(dismissButton.snp_bottom)
      make.left.equalTo(contentView)
      make.right.equalTo(contentView)
      make.height.equalTo(1)
    }

    contentView.addSubview(popupTitle)
    popupTitle.snp_makeConstraints { make in
      make.top.equalTo(contentView).priorityMedium()
      make.bottom.equalTo(titleDivider.snp_top).priorityMedium()
      make.centerX.equalTo(contentView)
      make.centerY.equalTo(dismissButton).priorityHigh()
      make.left.equalTo(dismissButton.snp_right).offset(2)
      make.right.equalTo(confirmButton.snp_left).offset(-4)
    }
    popupTitle.setContentHuggingPriority(UILayoutPriority.init(1),
                                         for: .horizontal)

    let dummyContentView = UIView()
    contentView.addSubview(dummyContentView)
    dummyContentView.snp_makeConstraints { make in
      make.top.equalTo(titleDivider.snp_bottom)
      make.left.equalTo(contentView).inset(8)
      make.right.equalTo(contentView).inset(8)
      make.bottom.equalTo(contentView).inset(8)
      make.height.equalTo(160)
    }

    dummyContentView.addSubview(metadataImageView)
    metadataImageView.snp_makeConstraints { make in
      make.right.equalTo(dummyContentView)
      make.height.equalTo(showMetadata ? metadataImageViewSize.height : 0)
      make.width.equalTo(showMetadata ? metadataImageViewSize.width : 0)
      make.top.equalTo(dummyContentView).inset(8)
    }

    dummyContentView.addSubview(popupBody)
    popupBody.snp_makeConstraints { make in
      make.top.equalTo(dummyContentView)
      make.left.equalTo(dummyContentView)
      make.right.equalTo(metadataImageView.snp_left).offset(-4)
      make.bottom.equalTo(dummyContentView)
    }

    view.addSubview(metadataWebView)
    metadataWebView.snp_makeConstraints { make in
      make.top.equalTo(view.snp_bottom)
      make.left.equalTo(view.snp_right)
      make.height.equalTo(view.snp_width)
      make.width.equalTo(view.snp_width)
    }
  }
}
