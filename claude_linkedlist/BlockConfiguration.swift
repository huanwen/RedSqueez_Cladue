//
//  BlockConfiguration.swift
//  LinkedListApp
//
//  模块配置系统 - 定义不同类型的积木块
//

import SwiftUI

// MARK: - 输入控件类型
enum InputType: Equatable {
    case dropdown(options: [String])
    case textField(placeholder: String)
    case both(options: [String], placeholder: String)
    case none
}

// MARK: - 模块配置
struct BlockConfig: Equatable {
    let name: String
    let inputType: InputType
    let color: Color
    
    // 实现 Equatable 协议 - 主要通过名称比较
    static func == (lhs: BlockConfig, rhs: BlockConfig) -> Bool {
        return lhs.name == rhs.name && lhs.inputType == rhs.inputType
    }
    
    static let availableBlocks: [BlockConfig] = [
        BlockConfig(name: "LED", inputType: .dropdown(options: ["ON", "OFF"]), color: .red),
        BlockConfig(name: "wait", inputType: .textField(placeholder: "1"), color: .orange),
        BlockConfig(name: "servo to", inputType: .both(options: ["0°", "90°", "180°"], placeholder: "90"), color: .blue),
        BlockConfig(name: "motor", inputType: .dropdown(options: ["▶", "◀", "⏹"]), color: .green),
        BlockConfig(name: "if sensor >", inputType: .textField(placeholder: "50"), color: .purple),
        BlockConfig(name: "display", inputType: .textField(placeholder: "Hello"), color: .cyan),
        BlockConfig(name: "play", inputType: .both(options: ["🎵", "🚨", "🔔"], placeholder: "440"), color: .yellow)
    ]
}

// MARK: - 模块数据
struct BlockData {
    var selectedDropdown: String?
    var textInput: String = ""
    
    func getDisplayText(for config: BlockConfig) -> String {
        switch config.inputType {
        case .dropdown(_):
            return selectedDropdown ?? "Select"
        case .textField(_):
            return textInput.isEmpty ? "___" : textInput
        case .both(_, _):
            let dropdownText = selectedDropdown ?? "Select"
            let textText = textInput.isEmpty ? "___" : textInput
            return "\(dropdownText) \(textText)"
        case .none:
            return ""
        }
    }
}

// MARK: - 模块选择器视图
struct BlockSelectorView: View {
    @Binding var selectedConfig: BlockConfig
    let onSelection: ((BlockConfig) -> Void)?
    @Environment(\.presentationMode) var presentationMode
    
    init(selectedConfig: Binding<BlockConfig>, onSelection: ((BlockConfig) -> Void)? = nil) {
        self._selectedConfig = selectedConfig
        self.onSelection = onSelection
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(BlockConfig.availableBlocks, id: \.name) { config in
                    Button(action: {
                        selectedConfig = config
                        onSelection?(config)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(config.color)
                                .frame(width: 40, height: 30)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(config.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text(getInputDescription(config.inputType))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("选择模块类型")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("取消") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func getInputDescription(_ inputType: InputType) -> String {
        switch inputType {
        case .dropdown(let options):
            return "选项: \(options.joined(separator: ", "))"
        case .textField(let placeholder):
            return "输入: \(placeholder)"
        case .both(let options, let placeholder):
            return "选项 + 输入: \(placeholder)"
        case .none:
            return "无参数"
        }
    }
}
