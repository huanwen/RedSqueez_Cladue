//
//  HelpView.swift
//  LinkedListApp
//
//  帮助视图 - 简单链条拖拽说明
//

import SwiftUI

// 帮助视图
struct HelpView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("垂直链条拖拽操作说明")
                        .font(.title)
                        .bold()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("🔗 基本操作")
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        Group {
                            Text("• 点击空白处：创建新的长方形节点")
                            Text("• 拖拽节点：移动节点位置")
                            Text("• 垂直靠近：节点上下长边靠近时自动连接")
                            Text("• 自动对齐：连接后节点会自动垂直对齐")
                        }
                        .font(.body)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("🎯 节点颜色说明")
                            .font(.headline)
                            .foregroundColor(.green)
                        
                        Group {
                            Text("• 灰色：独立节点（未连接）")
                            Text("• 蓝色：链条头部（可拖动整条链）")
                            Text("• 绿色：链条中的其他节点")
                            Text("• ↓箭头：表示连接到下一个节点")
                            Text("• ↑箭头：表示被上一个节点连接")
                            Text("• 粗黑边框：已连接的节点")
                        }
                        .font(.body)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("⚡ 链表断开和重组")
                            .font(.headline)
                            .foregroundColor(.orange)
                        
                        Group {
                            Text("• 拖拽蓝色头部：移动整条链表到新位置")
                            Text("• 拖拽绿色节点：从原链表断开，形成新的子链表")
                            Text("• 子链表包含：被拖拽节点及其后续所有节点")
                            Text("• 原链表自动重新排列和编号")
                            Text("• 新子链表自动成为独立链表")
                        }
                        .font(.body)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("🛠️ 工具栏功能")
                            .font(.headline)
                            .foregroundColor(.purple)
                        
                        Group {
                            Text("• 断开所有：保留所有节点但断开所有连接")
                            Text("• 清空：删除所有节点和连接")
                            Text("• 帮助：显示这个说明页面")
                        }
                        .font(.body)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("💡 使用技巧")
                            .font(.headline)
                            .foregroundColor(.red)
                        
                        Group {
                            Text("• 链表分割：拖拽任意绿色节点可将链表分成两部分")
                            Text("• 链表合并：将一个链表头部拖到另一个链表附近")
                            Text("• 节点插入：点击节点使用插入功能添加新节点")
                            Text("• 实时编号：节点位置[0][1][2]会实时更新")
                            Text("• UUID追踪：每个节点都有唯一的ID标识")
                        }
                        .font(.body)
                    }
                }
                .padding()
            }
            .navigationTitle("使用说明")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
