//
//  ScratchShapes.swift
//  LinkedListApp
//
//  Scratch风格拼图块形状组件 - 梯形凹凸槽设计
//

import SwiftUI

// MARK: - 共享槽位参数
struct SharedSlot {
    static let tabWidth: CGFloat = 24
    static let tabHeight: CGFloat = 6
    static let slotStartRatio: CGFloat = 0.5  // 居中位置
    static let tabInset: CGFloat = 4  // 梯形的斜边距离
}

// MARK: - Scratch风格拼图块形状
struct ScratchBlockShape: View {
    let hasTopSlot: Bool
    let hasBottomTab: Bool
    let topSlotHighlight: Bool
    let bottomTabHighlight: Bool
    let color: Color
    let strokeColor: Color
    let strokeWidth: CGFloat
    
    var body: some View {
        ZStack {
            // 主体形状
            ScratchPath(hasTopSlot: hasTopSlot, hasBottomTab: hasBottomTab)
                .fill(color)
                .overlay(
                    ScratchPath(hasTopSlot: hasTopSlot, hasBottomTab: hasBottomTab)
                        .stroke(strokeColor, lineWidth: strokeWidth)
                )
            
            // 顶部凹槽高亮
            if topSlotHighlight {
                TopSlotHighlight()
                    .fill(Color.yellow.opacity(0.6))
                    .animation(.easeInOut(duration: 0.3), value: topSlotHighlight)
            }
            
            // 底部凸起高亮
            if bottomTabHighlight {
                BottomTabHighlight()
                    .fill(Color.yellow.opacity(0.6))
                    .animation(.easeInOut(duration: 0.3), value: bottomTabHighlight)
            }
        }
    }
}

// MARK: - Scratch拼图块路径 - 梯形设计
struct ScratchPath: Shape {
    let hasTopSlot: Bool
    let hasBottomTab: Bool
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        let cornerRadius: CGFloat = 8
        let tabWidth = SharedSlot.tabWidth
        let tabHeight = SharedSlot.tabHeight
        let tabInset = SharedSlot.tabInset
        
        // 计算凹凸槽的起始位置（居中）
        let slotStartX = (width - tabWidth) / 2
        
        // 开始绘制路径 - 从左上角开始
        path.move(to: CGPoint(x: cornerRadius, y: 0))
        
        // 顶部边缘
        if hasTopSlot {
            // 绘制顶部梯形凹槽
            path.addLine(to: CGPoint(x: slotStartX, y: 0))
            path.addLine(to: CGPoint(x: slotStartX + tabInset, y: tabHeight))
            path.addLine(to: CGPoint(x: slotStartX + tabWidth - tabInset, y: tabHeight))
            path.addLine(to: CGPoint(x: slotStartX + tabWidth, y: 0))
        }
        
        // 顶部右角
        path.addLine(to: CGPoint(x: width - cornerRadius, y: 0))
        path.addArc(center: CGPoint(x: width - cornerRadius, y: cornerRadius),
                   radius: cornerRadius,
                   startAngle: .degrees(-90),
                   endAngle: .degrees(0),
                   clockwise: false)
        
        // 右边缘
        if hasBottomTab {
            path.addLine(to: CGPoint(x: width, y: height - tabHeight - cornerRadius))
        } else {
            path.addLine(to: CGPoint(x: width, y: height - cornerRadius))
        }
        
        // 底部右角
        if hasBottomTab {
            path.addLine(to: CGPoint(x: width, y: height - tabHeight - cornerRadius))
            path.addArc(center: CGPoint(x: width - cornerRadius, y: height - tabHeight - cornerRadius),
                       radius: cornerRadius,
                       startAngle: .degrees(0),
                       endAngle: .degrees(90),
                       clockwise: false)
        } else {
            path.addArc(center: CGPoint(x: width - cornerRadius, y: height - cornerRadius),
                       radius: cornerRadius,
                       startAngle: .degrees(0),
                       endAngle: .degrees(90),
                       clockwise: false)
        }
        
        // 底部边缘
        if hasBottomTab {
            // 绘制底部梯形凸起
            path.addLine(to: CGPoint(x: slotStartX + tabWidth, y: height - tabHeight))
            path.addLine(to: CGPoint(x: slotStartX + tabWidth - tabInset, y: height))
            path.addLine(to: CGPoint(x: slotStartX + tabInset, y: height))
            path.addLine(to: CGPoint(x: slotStartX, y: height - tabHeight))
        }
        
        // 底部左角
        if hasBottomTab {
            path.addLine(to: CGPoint(x: cornerRadius, y: height - tabHeight))
            path.addArc(center: CGPoint(x: cornerRadius, y: height - tabHeight - cornerRadius),
                       radius: cornerRadius,
                       startAngle: .degrees(90),
                       endAngle: .degrees(180),
                       clockwise: false)
        } else {
            path.addLine(to: CGPoint(x: cornerRadius, y: height))
            path.addArc(center: CGPoint(x: cornerRadius, y: height - cornerRadius),
                       radius: cornerRadius,
                       startAngle: .degrees(90),
                       endAngle: .degrees(180),
                       clockwise: false)
        }
        
        // 左边缘
        if hasBottomTab {
            path.addLine(to: CGPoint(x: 0, y: tabHeight + cornerRadius))
        } else {
            path.addLine(to: CGPoint(x: 0, y: cornerRadius))
        }
        
        // 顶部左角
        path.addArc(center: CGPoint(x: cornerRadius, y: cornerRadius),
                   radius: cornerRadius,
                   startAngle: .degrees(180),
                   endAngle: .degrees(270),
                   clockwise: false)
        
        path.closeSubpath()
        return path
    }
}

// MARK: - 顶部凹槽高亮形状 - 梯形
struct TopSlotHighlight: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let tabWidth = SharedSlot.tabWidth
        let tabHeight = SharedSlot.tabHeight
        let tabInset = SharedSlot.tabInset
        let slotStartX = (width - tabWidth) / 2
        
        // 绘制梯形凹槽高亮区域
        path.move(to: CGPoint(x: slotStartX, y: 0))
        path.addLine(to: CGPoint(x: slotStartX + tabInset, y: tabHeight))
        path.addLine(to: CGPoint(x: slotStartX + tabWidth - tabInset, y: tabHeight))
        path.addLine(to: CGPoint(x: slotStartX + tabWidth, y: 0))
        path.closeSubpath()
        
        return path
    }
}

// MARK: - 底部凸起高亮形状 - 梯形
struct BottomTabHighlight: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let tabWidth = SharedSlot.tabWidth
        let tabHeight = SharedSlot.tabHeight
        let tabInset = SharedSlot.tabInset
        let slotStartX = (width - tabWidth) / 2
        
        // 绘制梯形凸起高亮区域
        path.move(to: CGPoint(x: slotStartX, y: height - tabHeight))
        path.addLine(to: CGPoint(x: slotStartX + tabInset, y: height))
        path.addLine(to: CGPoint(x: slotStartX + tabWidth - tabInset, y: height))
        path.addLine(to: CGPoint(x: slotStartX + tabWidth, y: height - tabHeight))
        path.closeSubpath()
        
        return path
    }
}
