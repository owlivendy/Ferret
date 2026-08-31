# AMPopupView

`AMPopupView` 是 `CHPopupView` 的 Swift 实现，支持底部弹窗（Bottom Sheet）与 Alert 弹窗（居中 / 顶部固定），提供导航栏样式、多种 Modal 高度、键盘避让、遮罩关闭等能力。

## 功能特性

- 两种展示样式：`.fromBottom`（底部弹出）、`.alert`（Alert 弹出）
- Alert 垂直对齐：`.center`（默认居中）、`.top`（顶部固定，高度变化时向下伸展）
- 导航栏样式：关闭（`.x`）、返回（`.back`）、取消/确定（`.cancelAndSure`）
- 支持自定义导航栏左侧视图 `navigationLeftItemView`
- Modal 高度：自适应、3/4 屏、全屏、全屏（不含顶部安全区）、全屏（不含导航栏+安全区）
- 键盘弹起时自动上移，避免遮挡输入框
- 点击遮罩关闭（仅底部弹窗，`hiddenWhenTappedMask`）
- 悬浮关闭按钮 `showsFloatingCloseButton`（底部弹窗与 Alert 均支持）
- 关闭回调 `onDismiss`

## 初始化

```swift
import Ferret

// 底部弹窗（带标题栏）
let popup = AMPopupView(title: "标题", customView: contentView)

// Alert 弹窗（无标题栏，内容自定）
let alert = AMPopupView(alertCustomView: contentView)

// 或使用统一初始化方法
let popup2 = AMPopupView(title: "标题", customView: contentView, presentationStyle: .fromBottom)
```

## 用法示例

### 底部弹窗 — 关闭按钮

```swift
let contentView = makeContentView(height: 200)

let popup = AMPopupView(title: "弹窗标题", customView: contentView)
popup.navigationBarStyle = .x          // 默认，右侧关闭
popup.modalType = .threeOverFourScreen // 3/4 屏高度
popup.hiddenWhenTappedMask = true      // 点击遮罩关闭
popup.onDismiss = { _ in print("已关闭") }
popup.show()
```

### 底部弹窗 — 返回按钮

```swift
let popup = AMPopupView(title: "详情", customView: contentView)
popup.navigationBarStyle = .back
popup.modalType = .fullScreenWithoutSafeAreaTop
popup.show()
```

### 底部弹窗 — 取消 / 确定

```swift
let popup = AMPopupView(title: "编辑", customView: contentView)
popup.navigationBarStyle = .cancelAndSure
popup.shouldExecRightButtonTaped = { pop in
    // 校验通过后返回 true 关闭弹窗
    saveAndValidate()
    return true
}
popup.show()
```

### 右侧按钮完全自定义

```swift
popup.navigationBarStyle = .x
popup.rightButtonPressed = { pop in
    // 自行处理逻辑与关闭
    pop.hide()
}
```

### Alert 弹窗（含键盘避让）

```swift
let loginView = makeLoginForm() // 内含 UITextField

let popup = AMPopupView(alertCustomView: loginView)
popup.enableKeyboardAdjustment = true
popup.minGapBetweenKeyboardAndTextField = 20
popup.show()
```

### Alert 弹窗 — 悬浮关闭按钮

```swift
let popup = AMPopupView(alertCustomView: contentView)
popup.showsFloatingCloseButton = true // 遮罩上、弹窗右上角外侧
popup.show()
```

### Alert 顶部固定（多页高度不同时避免跳动）

```swift
let popup = AMPopupView(alertCustomView: contentView)
popup.alertVerticalAlignment = .top
popup.alertTopInset = 24
popup.alertHorizontalInset = 16
popup.alertMaxWidth = 440
popup.showWithCompletion {
    popup.lockAlertTopNearCenterIfNeeded()
}
```

`lockAlertTopNearCenterIfNeeded()` 会按当前高度把 top 锁到接近垂直居中，之后换页不再改 top。

### 隐藏导航栏

```swift
popup.hiddenNavigationBar = true // 内容区顶到安全区顶部
```

## Modal 类型（`modalType`）

| 值 | 说明 |
|---|---|
| `.none` | 高度由 `contentView` 约束决定 |
| `.threeOverFourScreen` | 屏幕高度 75% |
| `.fullScreen` | 全屏，无圆角 |
| `.fullScreenWithoutSafeAreaTop` | 全屏，保留底部安全区 |
| `.fullScreenWithoutNavigationBar` | 全屏减去顶部安全区与导航栏高度 |

仅 `presentationStyle == .fromBottom` 时生效。

## 常用属性

| 属性 | 说明 |
|---|---|
| `contentView` | 自定义内容视图（只读） |
| `titleLabel` | 标题 Label，Alert 时为 `nil` |
| `titleAlignment` | 标题对齐（`.left` / `.center`，默认居中；仅 `navigationBarStyle == .x` 时生效） |
| `bgView` | 弹窗背景视图，需在 `show` 前设置 |
| `presentationStyle` | 展示样式（只读） |
| `navigationBarStyle` | 导航栏按钮样式 |
| `navigationLeftItemView` | 导航栏左侧自定义视图 |
| `hiddenNavigationBar` | 是否隐藏导航栏 |
| `hiddenWhenTappedMask` | 点击遮罩是否关闭（仅底部弹窗） |
| `showsFloatingCloseButton` | 遮罩上、弹窗右上角外侧的悬浮关闭按钮（`.fromBottom` / `.alert` 均支持） |
| `enableKeyboardAdjustment` | 是否启用键盘避让 |
| `minGapBetweenKeyboardAndTextField` | 键盘与输入框最小间距 |
| `alertVerticalAlignment` | Alert 垂直对齐（`.center` / `.top`） |
| `alertTopInset` | 顶部对齐时相对安全区顶部的间距 |
| `alertHorizontalInset` | 顶部对齐时的左右边距 |
| `alertMaxWidth` | 顶部对齐时的最大宽度 |
| `lockAlertTopNearCenterIfNeeded()` | 按当前高度把 top 锁到接近居中（只执行一次） |
| `adjustForCurrentKeyboard()` | 按当前已显示的键盘立刻避让（键盘已升起时不会再收到 willShow） |
| `onDismiss` | 关闭回调 |
| `rightButtonPressed` | 右侧按钮回调（设置后需自行关闭） |
| `shouldExecLeftButtonTaped` | 左侧按钮拦截，返回 `false` 不关闭 |
| `shouldExecRightButtonTaped` | 右侧按钮拦截，返回 `false` 不关闭 |

## 显示 / 隐藏

```swift
popup.show()
popup.showWithCompletion { print("展示完成") }
popup.showInView(someView)
popup.showInView(someView) { print("展示完成") }
popup.hide()
```

## 与 CHPopupView 的对应关系

| CHPopupView | AMPopupView |
|---|---|
| `initPresentFromBottomWithTitle:customView:` | `init(title:customView:)` |
| `initAlertWithCustomView:` | `init(alertCustomView:)` |
| `navigationbarStyle` | `navigationBarStyle` |
| `hiddenWhenTappedMask` | `hiddenWhenTappedMask` |
| `closeButtonStyle`（已废弃） | 使用 `navigationBarStyle` 替代 |
