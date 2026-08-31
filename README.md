# Ferret

iOS UIKit 通用组件库

最低系统：**iOS 16.0**。

## 包含组件

- `AMButton` / `AMGradientButton` / `AMGradientView` / `AMHoldToTalkButton` / `AMLoadingButton`
- `AMFormSubmitable` / `AMFormValidatable` / `AMFormTextField` / `AMSelector`
- `AMTagListView` / `AMTagView` / `AMFixedTagListView`
- `AMPopupView`
- `AMPopoverView` / `AMPopoverMenuView`
- `AMPassthroughView` / `AMUIStackPassthroughView`
- `AMPrivateImageView`
- `PhotoPreviewController` / `AMVideoPreviewController`
- `AMVolumeWaveformView`
- `AMCircularProgressView`
- `AMNavigationBar`
- `SandboxFilePreviewerController`（调试用沙盒文件浏览器）
- `AMMarkdownView`
- `AMTextView`
- `AMStarRatingView`
- `AMStyle1Tab`
- `AMHorizontalPageScrollView`
- `AMFrameLayout`（`view.am.make { }` Frame 布局）
- `AMAttributedStringBuilder`（分段拼接 `NSAttributedString`）
- `AMToast`（文案 / 成功 / 失败 Toast，含排队与深色模式）

内置图标（`Resources/Assets.xcassets`）：`warn_stroke`、`down_arrow`、`close_circle_stroke`、`close_stroke`、`navi_back`、`loading-white-style1`、`star_s`、`star_n`、`star_of_half`、`success`、`error-circle-filled`。组件通过 `UIImage.ferret(_:)` 从包内加载。

## 依赖

- [SnapKit](https://github.com/SnapKit/SnapKit) ≥ 5.7.0
- [swift-markdown](https://github.com/swiftlang/swift-markdown) ≥ 0.5.0

## 使用

```swift
import Ferret

AMStringSelector.Config.default = AMStringSelector.Config(
    searchPlaceholder: "Search by keyword"
)
AMFormTextField.Config.default = AMFormTextField.Config(
    requiredErrorMessage: "This field is required"
)

AMToast.show(with: "This is a toast message")
AMToast.showSuccess(with: "Operation successful!")
AMToast.showError(with: "Something went wrong")
```
