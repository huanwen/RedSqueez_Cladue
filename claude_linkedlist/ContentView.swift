//
//  ContentView.swift
//  LinkedListApp
//
//  主视图 - 模块化链条拖拽应用
//

import SwiftUI

// 主视图
struct ContentView: View {
    @StateObject private var manager = ChainManager()
    @State private var showingHelp = false
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    // 背景
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                    .onTapGesture { location in
                        // 点击空白处不再创建模块，只是取消选择
                        // 模块创建改为直接点击底部工具栏
                    }
                    
                    // 绘制链条节点
                    ForEach(manager.nodes) { node in
                        ChainNodeView(node: node, manager: manager)
                    }
                    
                    // 说明文字
                    if manager.nodes.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "rectangle.on.rectangle.angled")
                                .font(.system(size: 80))
                                .foregroundColor(.gray.opacity(0.6))
                            
                            VStack(spacing: 8) {
                                Text("智能模块链")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.gray)
                                
                                Text("点击下方模块直接创建")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                
                                VStack(spacing: 4) {
                                    Text("操作说明:")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .bold()
                                    
                                    Text("• 点击模块内控件 = 编辑参数")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    
                                    Text("• 长按模块 = 显示删除按钮")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    
                                    Text("• 拖拽模块 = 移动和连接")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2 - 50)
                    }
                    
                    // 显示节点统计
                    if !manager.nodes.isEmpty {
                        VStack {
                            HStack {
                                Text("模块数: \(manager.nodes.count)")
                                    .font(.caption)
                                    .foregroundColor(.black)
                                    .padding(8)
                                    .background(Color.white.opacity(0.8))
                                    .cornerRadius(8)
                                Spacer()
                            }
                            Spacer()
                        }
                        .padding()
                    }
                    
                    // 底部模块选择工具栏
                    VStack {
                        Spacer()
                        BottomModuleToolbar(manager: manager)
                    }
                }
            }
            .navigationTitle("模块链编程")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button("帮助") {
                        showingHelp = true
                    }
                    
                    Button("断开所有") {
                        withAnimation {
                            manager.clearAllConnections()
                        }
                    }
                    
                    Button("清空") {
                        withAnimation {
                            manager.clearAll()
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingHelp) {
            HelpView()
        }
    }
}

// MARK: - 底部模块选择工具栏
struct BottomModuleToolbar: View {
    @ObservedObject var manager: ChainManager
    
    var body: some View {
        VStack(spacing: 0) {
            // 工具栏指示器
            HStack {
                Text("点击模块直接创建:")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text("总计 \(manager.nodes.count) 个模块")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .bold()
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            
            // 可滚动的模块选择栏
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(BlockConfig.availableBlocks, id: \.name) { config in
                        ModuleToolbarItem(
                            config: config,
                            onTap: {
                                // 直接创建模块，放在屏幕中央附近的随机位置
                                createModuleAtRandomPosition(config: config)
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color.white.opacity(0.95))
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.gray.opacity(0.3)),
                alignment: .top
            )
        }
        .background(Color.white.opacity(0.95))
    }
    
    private func createModuleAtRandomPosition(config: BlockConfig) {
        // 在屏幕中央区域生成随机位置
        let centerX = UIScreen.main.bounds.width / 2
        let centerY = UIScreen.main.bounds.height / 2 - 100 // 减去底部工具栏高度
        
        // 添加一些随机偏移，避免模块重叠
        let randomOffsetX = CGFloat.random(in: -50...50)
        let randomOffsetY = CGFloat.random(in: -100...100)
        
        let position = CGPoint(
            x: centerX + randomOffsetX,
            y: centerY + randomOffsetY
        )
        
        manager.addNode(at: position, config: config)
    }
}

// MARK: - 模块工具栏项
struct ModuleToolbarItem: View {
    let config: BlockConfig
    let onTap: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            onTap()
            
            // 短暂的按压反馈
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
            }
        }) {
            VStack(spacing: 4) {
                // 模块预览
                RoundedRectangle(cornerRadius: 8)
                    .fill(config.color)
                    .frame(width: 50, height: 32)
                    .overlay(
                        Text(config.name)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    )
                    .scaleEffect(isPressed ? 0.95 : 1.0)
                    .shadow(color: config.color.opacity(0.3), radius: isPressed ? 2 : 4)
                
                // 模块名称
                Text(config.name)
                    .font(.caption2)
                    .foregroundColor(.primary)
                    .bold()
                
                // 参数类型指示
                Text(getParameterHint(config.inputType))
                    .font(.system(size: 8))
                    .foregroundColor(.gray)
                    .opacity(0.8)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.easeInOut(duration: 0.1), value: isPressed)
    }
    
    private func getParameterHint(_ inputType: InputType) -> String {
        switch inputType {
        case .dropdown(_):
            return "选项"
        case .textField(_):
            return "输入"
        case .both(_, _):
            return "选项+输入"
        case .none:
            return "无参数"
        }
    }
}

#Preview {
    ContentView()
}
