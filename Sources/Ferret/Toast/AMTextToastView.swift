//
//  AMTextToastView.swift
//  Ferret
//

import UIKit

class AMTextToastView: AMToastView {
    private let messageLabel: UILabel

    init(message: String) {
        let label = UILabel(frame: .zero)
        label.text = message
        label.textColor = AMToastConfig.ToastViewStyle.textColor
        label.font = AMToastConfig.ToastViewStyle.textFont
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.textAlignment = .center
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.setContentHuggingPriority(.required, for: .vertical)

        messageLabel = label
        super.init(frame: .zero)
        customView = label
    }

    required init?(coder: NSCoder) {
        messageLabel = UILabel(frame: .zero)
        super.init(coder: coder)
    }
}
