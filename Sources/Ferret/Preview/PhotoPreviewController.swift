//
//  PhotoPreviewController.swift
//  Ferret
//

import UIKit
import SnapKit

/// 拍照后预览页代理
public protocol PhotoPreviewControllerDelegate: AnyObject {
    /// 点击重拍按钮
    /// - Parameter controller: 预览控制器
    func photoPreviewControllerDidRetake(_ controller: PhotoPreviewController)
    /// 点击使用照片按钮
    /// - Parameters:
    ///   - controller: 预览控制器
    ///   - image: 当前预览图片
    func photoPreviewController(_ controller: PhotoPreviewController, didUsePhoto image: UIImage)
}

/// 图片预览页，适用于相机拍照后确认使用或重拍。
open class PhotoPreviewController: UIViewController {

    /// 需要预览的照片
    public var previewImage: UIImage?
    /// 代理对象
    public weak var delegate: PhotoPreviewControllerDelegate?
    /// 重拍按钮文案，默认「重拍」
    open var retakeButtonTitle: String = "重拍"
    /// 使用照片按钮文案，默认「使用照片」
    open var usePhotoButtonTitle: String = "使用照片"

    private let imagePreviewView = UIImageView(frame: .zero)
    private let buttonContainer = UIView(frame: .zero)
    private let retakeButton = UIButton(type: .custom)
    private let usePhotoButton = UIButton(type: .custom)

    /// 页面加载后搭建预览图与底部操作栏
    open override func viewDidLoad() {
        super.viewDidLoad()
        setupBaseUI()
        setupPreviewView()
        setupButtons()
        setupLayout()
    }

    private func setupBaseUI() {
        view.backgroundColor = .black
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    private func setupPreviewView() {
        imagePreviewView.contentMode = .scaleAspectFit
        imagePreviewView.clipsToBounds = true
        imagePreviewView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imagePreviewView)
        imagePreviewView.image = previewImage
    }

    private func setupButtons() {
        buttonContainer.backgroundColor = UIColor.systemGray2
        view.addSubview(buttonContainer)

        retakeButton.setTitle(retakeButtonTitle, for: .normal)
        retakeButton.setTitleColor(.white, for: .normal)
        retakeButton.layer.masksToBounds = true
        retakeButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        retakeButton.addTarget(self, action: #selector(retakeButtonTapped), for: .touchUpInside)
        retakeButton.translatesAutoresizingMaskIntoConstraints = false
        buttonContainer.addSubview(retakeButton)

        usePhotoButton.setTitle(usePhotoButtonTitle, for: .normal)
        usePhotoButton.setTitleColor(.white, for: .normal)
        usePhotoButton.layer.masksToBounds = true
        usePhotoButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        usePhotoButton.addTarget(self, action: #selector(usePhotoButtonTapped), for: .touchUpInside)
        usePhotoButton.translatesAutoresizingMaskIntoConstraints = false
        buttonContainer.addSubview(usePhotoButton)
    }

    private func setupLayout() {
        NSLayoutConstraint.activate([
            imagePreviewView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            imagePreviewView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imagePreviewView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            retakeButton.heightAnchor.constraint(equalToConstant: 44),
            usePhotoButton.heightAnchor.constraint(equalToConstant: 44)
        ])

        buttonContainer.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(120)
            make.bottom.equalTo(view.snp.bottom).offset(0)
            make.top.equalTo(imagePreviewView.snp.bottom)
        }
        retakeButton.snp.makeConstraints { make in
            make.leading.equalTo(26)
            make.top.equalTo(14)
        }
        usePhotoButton.snp.makeConstraints { make in
            make.trailing.equalTo(-26)
            make.top.equalTo(retakeButton.snp.top)
        }
    }

    @objc private func retakeButtonTapped() {
        delegate?.photoPreviewControllerDidRetake(self)
    }

    @objc private func usePhotoButtonTapped() {
        guard let image = previewImage else { return }
        delegate?.photoPreviewController(self, didUsePhoto: image)
    }

    /// 离开页面时恢复导航栏
    /// - Parameter animated: 是否动画
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
}
