//
//  AMErrorToastView.swift
//  Ferret
//

import UIKit

class AMErrorToastView: AMToastView {
    private let errorImage: UIImageView
    private let messageLabel: UILabel

    init(message: String) {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false

        let imageView = UIImageView()
        imageView.image = UIImage.ferret("error-circle-filled")
        imageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(imageView)
        errorImage = imageView

        let label = UILabel(frame: .zero)
        label.text = message
        label.textColor = AMToastConfig.ToastViewStyle.textColor
        label.font = AMToastConfig.ToastViewStyle.textFont
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.setContentHuggingPriority(.required, for: .vertical)
        label.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(label)
        messageLabel = label

        super.init(frame: .zero)

        NSLayoutConstraint.activate([
            errorImage.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            errorImage.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            errorImage.topAnchor.constraint(greaterThanOrEqualTo: containerView.topAnchor),
            errorImage.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor),

            messageLabel.leadingAnchor.constraint(equalTo: errorImage.trailingAnchor, constant: 5),
            messageLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            messageLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            messageLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        customView = containerView
    }

    required init?(coder: NSCoder) {
        errorImage = UIImageView()
        messageLabel = UILabel(frame: .zero)
        super.init(coder: coder)
    }
}
