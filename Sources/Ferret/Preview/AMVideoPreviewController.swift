//
//  AMVideoPreviewController.swift
//  Ferret
//

import AVKit
import Photos
import SnapKit
import UIKit

/// 视频预览页，基于 `AVPlayerViewController`，支持保存到相册。
open class AMVideoPreviewController: AVPlayerViewController {
    private let saveButton = UIButton(type: .custom)

    /// 待播放的视频地址
    open var videoURL: URL?
    /// 保存按钮文案，默认「保存」
    /// - Note: 宿主 App 需在 Info.plist 配置 `NSPhotoLibraryAddUsageDescription`
    open var saveButtonTitle: String = "保存"
    /// 保存到相册完成回调（主线程）
    open var onSaveToAlbumCompleted: ((_ success: Bool, _ error: Error?) -> Void)?

    private var saveButtonHidden = false
    private var workItem: DispatchWorkItem?

    /// 开始播放并展示保存按钮
    open override func viewDidLoad() {
        super.viewDidLoad()
        if let videoURL {
            player = AVPlayer(url: videoURL)
        }

        saveButton.alpha = saveButtonHidden ? 0 : 1
        saveButton.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        saveButton.setTitle(saveButtonTitle, for: .normal)
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.layer.cornerRadius = 10
        saveButton.addTarget(self, action: #selector(saveVideoToAlbum), for: .touchUpInside)

        view.addSubview(saveButton)
        saveButton.snp.makeConstraints { make in
            make.right.equalTo(view.snp.right).offset(-20)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-100)
            make.size.equalTo(CGSize(width: 72, height: 36))
        }
        player?.play()

        PHPhotoLibrary.requestAuthorization(for: .addOnly) { _ in }

        workItem = DispatchWorkItem { [weak self] in
            self?.toggle(hidden: true)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: workItem!)
    }

    /// 将当前视频写入系统相册
    @objc open func saveVideoToAlbum() {
        guard let videoURL else { return }
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
        }) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.onSaveToAlbumCompleted?(success, error)
            }
        }
    }

    /// 点击画面时切换保存按钮显隐
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        workItem?.cancel()
        workItem = nil
        toggle()
    }

    /// 切换保存按钮显隐
    /// - Parameter hidden: 指定显隐；为 `nil` 时在当前状态间切换
    open func toggle(hidden: Bool? = nil) {
        saveButtonHidden = !saveButtonHidden
        if let hidden {
            saveButtonHidden = hidden
        }
        UIView.animate(withDuration: 0.3) {
            self.saveButton.alpha = self.saveButtonHidden ? 0 : 1
        }
    }
}
