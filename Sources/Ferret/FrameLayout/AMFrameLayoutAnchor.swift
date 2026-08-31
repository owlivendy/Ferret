//
//  AMFrameLayoutAnchor.swift
//  Ferret
//

import UIKit

/// Frame 布局锚点，负责把相对关系写回 `UIView.frame`
public class AMFrameLayoutAnchor: NSObject, AMLayoutRelation {
    /// 锚点类型
    public enum AMFrameLayoutAnchorType {
        case left
        case right
        case top
        case bottom
        case centerX
        case centerY
        case leading
        case trailing
        case size
    }
    /// 当前锚点类型
    public let type: AMFrameLayoutAnchorType
    /// 当前锚点所属视图
    public let view: UIView
    private var _offset: CGFloat = 0
    private var _size: CGSize = .zero
    private var sameLevelViewAnchor: AMFrameLayoutAnchor?
    private var superViewAnchor: AMFrameLayoutAnchor?
    
    /// 创建锚点
    /// - Parameters:
    ///   - view: 所属视图
    ///   - type: 锚点类型
    public init(view: UIView, type: AMFrameLayoutAnchorType) {
        self.view = view
        self.type = type
    }
    
    
    /// 对齐到父视图锚点
    /// - Parameter superview: 父视图锚点
    /// - Returns: 当前锚点
    @discardableResult
    public func equalToSuper(view superview: AMFrameLayoutAnchor) -> AMFrameLayoutAnchor {
        self.superViewAnchor = superview
        apply()
        return self
    }
    
    
    /// 对齐到同级视图锚点
    /// - Parameter sameLevelView: 同级视图锚点
    /// - Returns: 当前锚点
    @discardableResult
    public func equalTo(sameLevelView: AMFrameLayoutAnchor) -> AMFrameLayoutAnchor {
        self.sameLevelViewAnchor = sameLevelView
        apply()
        return self
    }
    
    /// 设置尺寸（仅 `size` 锚点有效）
    /// - Parameter size: 目标尺寸
    /// - Returns: 当前锚点
    @discardableResult
    public func equalToSize(size: CGSize) -> AMFrameLayoutAnchor {
        self._size = size
        apply()
        return self
    }
    
    /// 设置偏移
    /// - Parameter value: 偏移量
    /// - Returns: 当前锚点
    @discardableResult
    public func offset(_ value: CGFloat) -> AMFrameLayoutAnchor {
        self._offset = value
        apply()
        return self
    }
    
    func translateAnchorType(type: AMFrameLayoutAnchorType, isRTL: Bool) -> AMFrameLayoutAnchorType {
        guard type == .leading || type == .trailing else {
            return type
        }
        
        if isRTL {
            if type == .leading {
                return .right
            } else if type == .trailing {
                return .left
            }
        } else {
            if type == .leading {
                return .left
            } else if type == .trailing {
                return .right
            }
        }
        return type
        
    }
    
    /// 立刻把当前关系写回 `view.frame`
    public func apply() {
        let isRTL = UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft
        var viewAnchorType = self.type
        var toffset = _offset
        if (viewAnchorType == .leading || viewAnchorType == .trailing) && isRTL {
            toffset = -_offset
        }
        
        viewAnchorType = translateAnchorType(type: viewAnchorType, isRTL: isRTL)
        
        if self.type == .size {
            view.frame.size = _size
        } else if let superViewAnchor = superViewAnchor {
            let superViewSize = superViewAnchor.view.bounds.size
            var superViewAnchorType = superViewAnchor.type
            superViewAnchorType = translateAnchorType(type: superViewAnchorType, isRTL: isRTL)
            
            if viewAnchorType == .left {
                if superViewAnchorType == .left {
                    view.frame = CGRect(x: toffset, y: view.frame.minY, width: view.frame.width, height: view.frame.height)
                } else if superViewAnchorType == .right {
                    view.frame = CGRect(x: superViewSize.width + view.frame.width + toffset, y: view.frame.minY, width: view.frame.width, height: view.frame.height)
                } else if superViewAnchorType == .centerX {
                    view.frame = CGRect(x: superViewSize.width / 2 + toffset, y: view.frame.minY, width: view.frame.width, height: view.frame.height)
                }
            } else if viewAnchorType == .right {
                if superViewAnchorType == .left {
                    view.frame = CGRect(x: -view.frame.width + toffset, y: view.frame.minY, width: view.frame.width, height: view.frame.height)
                } else if superViewAnchorType == .right {
                    view.frame = CGRect(x: superViewSize.width - view.frame.width + toffset, y: view.frame.minY, width: view.frame.width, height: view.frame.height)
                } else if superViewAnchorType == .centerX {
                    view.frame = CGRect(x: superViewSize.width / 2 - view.frame.width + toffset, y: view.frame.minY, width: view.frame.width, height: view.frame.height)
                }
            } else if viewAnchorType == .centerX {
                if superViewAnchorType == .left {
                    view.frame = CGRect(x: -view.frame.width / 2 + toffset, y: view.frame.minY, width: view.frame.width, height: view.frame.height)
                } else if superViewAnchorType == .right {
                    view.frame = CGRect(x: superViewSize.width + view.frame.width / 2 + toffset, y: view.frame.minY, width: view.frame.width, height: view.frame.height)
                } else if superViewAnchorType == .centerX {
                    view.frame = CGRect(x: superViewSize.width / 2 - view.frame.width / 2 + toffset, y: view.frame.minY, width: view.frame.width, height: view.frame.height)
                }
            } else if viewAnchorType == .top {
                if superViewAnchorType == .top {
                    view.frame = CGRect(x: view.frame.minX, y: toffset, width: view.frame.width, height: view.frame.height)
                } else if superViewAnchorType == .bottom {
                    view.frame = CGRect(x: view.frame.minX, y: superViewSize.height + view.frame.height + toffset, width: view.frame.width, height: view.frame.height)
                } else if superViewAnchorType == .centerY {
                    view.frame = CGRect(x: view.frame.minX, y: superViewSize.height / 2 + toffset, width: view.frame.width, height: view.frame.height)
                }
            } else if viewAnchorType == .bottom {
                if superViewAnchorType == .top {
                    view.frame = CGRect(x: view.frame.minX, y: -view.frame.height + toffset, width: view.frame.width, height: view.frame.height)
                } else if superViewAnchorType == .bottom {
                    view.frame = CGRect(x: view.frame.minX, y: superViewSize.height - view.frame.height + toffset, width: view.frame.width, height: view.frame.height)
                } else if superViewAnchorType == .centerY {
                    view.frame = CGRect(x: view.frame.minX, y: superViewSize.height / 2 - view.frame.height + toffset, width: view.frame.width, height: view.frame.height)
                }
            } else if viewAnchorType == .centerY {
                if superViewAnchorType == .top {
                    view.frame = CGRect(x: view.frame.minX, y: -view.frame.height / 2 + toffset, width: view.frame.width, height: view.frame.height)
                } else if superViewAnchorType == .bottom {
                    view.frame = CGRect(x: view.frame.minX, y: superViewSize.height - view.frame.height / 2 + toffset, width: view.frame.width, height: view.frame.height)
                } else if superViewAnchorType == .centerY {
                    view.frame = CGRect(x: view.frame.minX, y: superViewSize.height / 2 - view.frame.height / 2 + toffset, width: view.frame.width, height: view.frame.height)
                }
            }
        } else if let sameLevelViewAnchor = sameLevelViewAnchor {
            let sameLevelViewframe = sameLevelViewAnchor.view.frame
            var sameLevelViewAnchorType = sameLevelViewAnchor.type
            sameLevelViewAnchorType = translateAnchorType(type: sameLevelViewAnchorType, isRTL: isRTL)
            
            if viewAnchorType == .left {
                if sameLevelViewAnchorType == .left {
                    view.frame = CGRect(x: sameLevelViewframe.minX + toffset, y: view.frame.minY, width: view.frame.width, height: view.frame.height)
                } else if sameLevelViewAnchorType == .right {
                    view.frame = CGRect(x: sameLevelViewframe.maxX + toffset, y: view.frame.minY, width: view.frame.width, height: view.frame.height)
                } else if sameLevelViewAnchorType == .centerX {
                    view.frame = CGRect(x: sameLevelViewframe.midX + toffset, y: view.frame.minY, width: view.frame.width, height: view.frame.height)
                }
            } else if viewAnchorType == .right {
                if sameLevelViewAnchorType == .left {
                    view.frame = CGRect(x: sameLevelViewframe.minX - view.frame.width + toffset, y: view.frame.minY, width: view.frame.width, height: view.frame.height)
                } else if sameLevelViewAnchorType == .right {
                    view.frame = CGRect(x: sameLevelViewframe.maxX - view.frame.width + toffset, y: view.frame.minY, width: view.frame.width, height: view.frame.height)
                } else if sameLevelViewAnchorType == .centerX {
                    view.frame = CGRect(x: sameLevelViewframe.midX - view.frame.width / 2 + toffset, y: view.frame.minY, width: view.frame.width, height: view.frame.height)
                }
            } else if viewAnchorType == .centerX {
                if sameLevelViewAnchorType == .left {
                    view.frame = CGRect(x: sameLevelViewframe.minX - view.frame.width / 2 + toffset, y: view.frame.minY, width: view.frame.width, height: view.frame.height)
                } else if sameLevelViewAnchorType == .right {
                    view.frame = CGRect(x: sameLevelViewframe.maxX - view.frame.width / 2 + toffset, y: view.frame.minY, width: view.frame.width, height: view.frame.height)
                } else if sameLevelViewAnchorType == .centerX {
                    view.centerX = sameLevelViewframe.midX + toffset
                }
            } else if viewAnchorType == .top {
                if sameLevelViewAnchorType == .top {
                    view.frame = CGRect(x: view.frame.minX, y: sameLevelViewframe.minY + toffset, width: view.frame.width, height: view.frame.height)
                } else if sameLevelViewAnchorType == .bottom {
                    view.frame = CGRect(x: view.frame.minX, y: sameLevelViewframe.maxY + toffset, width: view.frame.width, height: view.frame.height)
                } else if sameLevelViewAnchorType == .centerY {
                    view.frame = CGRect(x: view.frame.minX, y: sameLevelViewframe.midY + toffset, width: view.frame.width, height: view.frame.height)
                }
            } else if viewAnchorType == .bottom {
                if sameLevelViewAnchorType == .top {
                    view.frame = CGRect(x: view.frame.minX, y: sameLevelViewframe.minY - view.frame.height + toffset, width: view.frame.width, height: view.frame.height)
                } else if sameLevelViewAnchorType == .bottom {
                    view.frame = CGRect(x: view.frame.minX, y: sameLevelViewframe.maxY - view.frame.height + toffset, width: view.frame.width, height: view.frame.height)
                } else if sameLevelViewAnchorType == .centerY {
                    view.frame = CGRect(x: view.frame.minX, y: sameLevelViewframe.midY - view.frame.height + toffset, width: view.frame.width, height: view.frame.height)
                }
            } else if viewAnchorType == .centerY {
                if sameLevelViewAnchorType == .top {
                    view.frame = CGRect(x: view.frame.minX, y: sameLevelViewframe.minY - view.frame.height / 2 + toffset, width: view.frame.width, height: view.frame.height)
                } else if sameLevelViewAnchorType == .bottom {
                    view.frame = CGRect(x: view.frame.minX, y: sameLevelViewframe.maxY - view.frame.height / 2 + toffset, width: view.frame.width, height: view.frame.height)
                } else if sameLevelViewAnchorType == .centerY {
                    view.centerY = sameLevelViewframe.midY + toffset
                }
            }
        }
    }
    
}
