//
//  ScratchShapes.swift
//  LinkedListApp
//
//  Scratch风格拼图块形状组件
//

import SwiftUI

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

// MARK: - Scratch拼图块路径
struct ScratchPath: Shape {
    let hasTopSlot: Bool
    let hasBottomTab: Bool
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        let cornerRadius: CGFloat = 8
        let slotWidth: CGFloat = 20
        let slotHeight: CGFloat = 6
        let tabWidth: CGFloat = 20
        let tabHeight: CGFloat = 6
        
        // 开始绘制路径
        path.move(to: CGPoint(x: cornerRadius, y: 0))
        
        // 顶部边缘
        if hasTopSlot {
            // 绘制顶部凹槽
            let slotStart = (width - slotWidth) / 2
            let slotEnd = slotStart + slotWidth
            
            path.addLine(to: CGPoint(x: slotStart, y: 0))
            path.addLine(to: CGPoint(x: slotStart, y: slotHeight))
            path.addArc(center: CGPoint(x: slotStart + slotWidth/2, y: slotHeight),
                       radius: slotWidth/2,
                       startAngle: .degrees(180),
                       endAngle: .degrees(0),
                       clockwise: true)
            path.addLine(to: CGPoint(x: slotEnd, y: 0))
        }
        
        // 顶部右角
        path.addLine(to: CGPoint(x: width - cornerRadius, y: 0))
        path.addArc(center: CGPoint(x: width - cornerRadius, y: cornerRadius),
                   radius: cornerRadius,
                   startAngle: .degrees(-90),
                   endAngle: .degrees(0),
                   clockwise: false)
        
        // 右边缘
        path.addLine(to: CGPoint(x: width, y: height - cornerRadius))
        
        // 底部右角
        path.addArc(center: CGPoint(x: width - cornerRadius, y: height - cornerRadius),
                   radius: cornerRadius,
                   startAngle: .degrees(0),
                   endAngle: .degrees(90),
                   clockwise: false)
        
        // 底部边缘
        if hasBottomTab {
            // 绘制底部凸起
            let tabStart = (width - tabWidth) / 2
            let tabEnd = tabStart + tabWidth
            
            path.addLine(to: CGPoint(x: tabEnd, y: height))
            path.addLine(to: CGPoint(x: tabEnd, y: height + tabHeight))
            path.addArc(center: CGPoint(x: tabEnd - tabWidth/2, y: height + tabHeight),
                       radius: tabWidth/2,
                       startAngle: .degrees(0),
                       endAngle: .degrees(180),
                       clockwise: true)
            path.addLine(to: CGPoint(x: tabStart, y: height))
        }
        
        // 底部左角
        path.addLine(to: CGPoint(x: cornerRadius, y: height))
        path.addArc(center: CGPoint(x: cornerRadius, y: height - cornerRadius),
                   radius: cornerRadius,
                   startAngle: .degrees(90),
                   endAngle: .degrees(180),
                   clockwise: false)
        
        // 左边缘
        path.addLine(to: CGPoint(x: 0, y: cornerRadius))
        
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

// MARK: - 顶部凹槽高亮形状
struct TopSlotHighlight: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let slotWidth: CGFloat = 20
        let slotHeight: CGFloat = 6
        let slotStart = (width - slotWidth) / 2
        
        // 绘制凹槽高亮区域
        path.move(to: CGPoint(x: slotStart, y: 0))
        path.addLine(to: CGPoint(x: slotStart, y: slotHeight))
        path.addArc(center: CGPoint(x: slotStart + slotWidth/2, y: slotHeight),
                   radius: slotWidth/2,
                   startAngle: .degrees(180),
                   endAngle: .degrees(0),
                   clockwise: true)
        path.addLine(to: CGPoint(x: slotStart + slotWidth, y: 0))
        path.closeSubpath()
        
        return path
    }
}

// MARK: - 底部凸起高亮形状
struct BottomTabHighlight: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let tabWidth: CGFloat = 20
        let tabHeight: CGFloat = 6
        let tabStart = (width - tabWidth) / 2
        
        // 绘制凸起高亮区域
        path.move(to: CGPoint(x: tabStart, y: height))
        path.addLine(to: CGPoint(x: tabStart, y: height + tabHeight))
        path.addArc(center: CGPoint(x: tabStart + tabWidth/2, y: height + tabHeight),
                   radius: tabWidth/2,
                   startAngle: .degrees(180),
                   endAngle: .degrees(0),
                   clockwise: false)
        path.addLine(to: CGPoint(x: tabStart + tabWidth, y: height))
        path.closeSubpath()
        
        return path
    }
}
