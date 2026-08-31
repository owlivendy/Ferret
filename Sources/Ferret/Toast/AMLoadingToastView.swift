//
//  AMLoadingToastView.swift
//  Ferret
//

import UIKit

class AMLoadingToastView: AMToastView {
    private let activityIndicator: UIActivityIndicatorView

    override init(frame: CGRect) {
        activityIndicator = UIActivityIndicatorView(style: .large)
        super.init(frame: frame)
        activityIndicator.startAnimating()
        customView = activityIndicator
    }

    required init?(coder: NSCoder) {
        activityIndicator = UIActivityIndicatorView(style: .large)
        super.init(coder: coder)
        activityIndicator.startAnimating()
        customView = activityIndicator
    }

    deinit {
        activityIndicator.stopAnimating()
    }
}
