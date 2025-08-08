//
//  ContentView.swift
//  LinkedListApp
//
//  主视图 - 简单链条拖拽应用
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
                        // 点击空白处添加新节点
                        manager.addNode(at: location)
                    }
                    
                    // 绘制链条节点
                    ForEach(manager.nodes) { node in
                        ChainNodeView(node: node, manager: manager)
                    }
                    
                    // 说明文字
                    if manager.nodes.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "rectangle.on.rectangle")
                                .font(.system(size: 80))
                                .foregroundColor(.gray.opacity(0.6))
                            
                            VStack(spacing: 8) {
                                Text("智能链条")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.gray)
                                
                                Text("点击创建节点")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                
                                Text("蓝色=链条头部，绿色=已连接")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                                
                                Text("拖动蓝色节点移动整条链")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    }
                    
                    // 显示节点统计
                    if !manager.nodes.isEmpty {
                        VStack {
                            HStack {
                                Text("节点: \(manager.nodes.count)")
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
                }
            }
            .navigationTitle("链条拖拽")
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

#Preview {
    ContentView()
}
