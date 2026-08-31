//
//  AMFormValidatable.swift
//  aitrade
//

import Foundation

/// 表单校验失败错误，携带错误文案
public struct AMFormValidationError: Error, Equatable, LocalizedError {
    /// 错误文案
    public let message: String

    /// 创建校验失败错误
    /// - Parameter message: 错误文案
    public init(_ message: String) {
        self.message = message
    }

    public var errorDescription: String? { message }
}

/// 表单校验结果回调：`success(true)` 表示通过；`failure` 携带错误文案
public typealias AMFormValidatorCallback = (Result<Bool, AMFormValidationError>) -> Void

/// 表单校验闭包：`text` 为待校验内容，通过 `validator` 回传结果（支持异步）
public typealias AMFormValidateHandler = (_ text: String, _ validator: @escaping AMFormValidatorCallback) -> Void

/// 可校验表单控件协议
/// - Note: 属性命名为 `validateHandler`，避免与 `UIResponder.validate(_:)` 冲突
public protocol AMFormValidatable: AnyObject {
    /// 是否必填；默认 `false`。为 `true` 且内容为空时，校验失败
    var required: Bool { get set }

    /// 校验逻辑；为 `nil` 时仅按 `required` 规则校验
    /// - Note: 可在闭包内异步完成后调用 `validator`；`success(true)` 表示通过，`failure` 携带错误文案
    var validateHandler: AMFormValidateHandler? { get set }

    /// 执行校验并将结果回传；必填为空时失败，无 `validateHandler` 时按 `required` 判断后回传
    /// - Parameter completion: 是否通过
    func runFormValidation(completion: @escaping (Bool) -> Void)
}
