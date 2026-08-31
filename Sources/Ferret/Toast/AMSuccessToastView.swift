//
//  AMSuccessToastView.swift
//  Ferret
//

import UIKit

class AMSuccessToastView: AMToastView {
    private let successImage: UIImageView
    private let messageLabel: UILabel

    init(message: String) {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false

        let imageView = UIImageView()
        imageView.image = UIImage.ferret("success")
        imageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(imageView)
        successImage = imageView

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
            successImage.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            successImage.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            successImage.topAnchor.constraint(greaterThanOrEqualTo: containerView.topAnchor),
            successImage.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor),

            messageLabel.leadingAnchor.constraint(equalTo: successImage.trailingAnchor, constant: 5),
            messageLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            messageLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            messageLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        customView = containerView
    }

    required init?(coder: NSCoder) {
        successImage = UIImageView()
        messageLabel = UILabel(frame: .zero)
        super.init(coder: coder)
    }
}
