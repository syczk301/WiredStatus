import AppKit
import SwiftUI

final class PanelModel: ObservableObject {
    @Published var state: WiredState = .absent
    @Published var interfaces: [WiredInterface] = []
}

private struct InterfaceCard: View {
    let interface: WiredInterface
    @State private var copied: String?
    private var ipv4: [String] { interface.addresses.filter { !$0.contains(":") } }
    private var ipv6: [String] { interface.addresses.filter { $0.contains(":") } }

    private func address(_ ip: String, prominent: Bool = false) -> some View {
        HStack(spacing: 10) {
            Text(ip)
                .font(.system(size: prominent ? 20 : 11, weight: prominent ? .medium : .regular, design: .monospaced))
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(ip, forType: .string)
                copied = ip
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { if copied == ip { copied = nil } }
            } label: {
                Image(systemName: copied == ip ? "checkmark" : "doc.on.doc")
                    .foregroundStyle(copied == ip ? Color.green : Color.secondary)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .help(copied == ip ? "已复制" : "复制 IP 地址")
            .accessibilityLabel(copied == ip ? "已复制 IP 地址" : "复制 IP 地址 \(ip)")
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "cable.connector")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Color.teal)
                    .frame(width: 32, height: 32)
                    .background(Color.teal.opacity(0.10), in: RoundedRectangle(cornerRadius: 9))
                VStack(alignment: .leading, spacing: 4) {
                    Text(interface.displayName).font(.system(size: 13, weight: .semibold))
                    Text("以太网 · \(interface.name)").font(.system(size: 11)).foregroundStyle(.secondary)
                }.padding(.top, 3)
                Spacer(minLength: 0)
                Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.green).padding(.top, 3)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(ipv4.isEmpty ? "IPv6 地址" : "本机 IP 地址")
                    .font(.system(size: 10, weight: .medium)).foregroundStyle(.secondary)
                if ipv4.isEmpty {
                    ForEach(ipv6, id: \.self) { address($0) }
                } else {
                    ForEach(ipv4, id: \.self) { address($0, prominent: true) }
                }
            }
            if !ipv4.isEmpty && !ipv6.isEmpty {
                Divider()
                DisclosureGroup {
                    VStack(spacing: 5) { ForEach(ipv6, id: \.self) { address($0) } }.padding(.top, 5)
                } label: {
                    Text("IPv6 地址").font(.system(size: 11)).foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.primary.opacity(0.06), lineWidth: 1))
    }
}

struct StatusPanel: View {
    @ObservedObject var model: PanelModel
    let panelHeight: CGFloat
    let networkSettings: () -> Void
    let loginSettings: () -> Void
    let quit: () -> Void

    private var connected: Bool { model.state == .connected }
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("有线状态").font(.system(size: 18, weight: .semibold))
                    Text(connected ? "已连接的有线网卡" : "等待有线网络连接")
                        .font(.system(size: 11)).foregroundStyle(.secondary)
                }
                Spacer()
                HStack(spacing: 5) {
                    Circle().fill(connected ? Color.green : Color.orange).frame(width: 6, height: 6)
                    Text(connected ? "已连接" : "未就绪").font(.system(size: 11, weight: .medium))
                }
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background((connected ? Color.green : Color.orange).opacity(0.10), in: Capsule())
            }

            if model.interfaces.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "cable.connector").font(.system(size: 35, weight: .light)).foregroundStyle(.secondary)
                    Text(model.state.title).font(.system(size: 14, weight: .medium))
                    Text("接入网线并获取 IP 后，网卡将显示在这里。")
                        .font(.system(size: 11)).foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity).padding(.vertical, 12)
            } else {
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(model.interfaces, id: \.name) { InterfaceCard(interface: $0) }
                    }.padding(1)
                }
                .scrollIndicators(.automatic)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            HStack(spacing: 8) {
                Button(action: networkSettings) {
                    Label("网络设置", systemImage: "network").frame(maxWidth: .infinity)
                }.help("打开网络设置")
                Button(action: loginSettings) {
                    Label("开机启动", systemImage: "power").frame(maxWidth: .infinity)
                }.help("在系统登录项中管理开机自动启动")
                    .accessibilityLabel("开机自动启动，在系统登录项中管理")
            }
            .font(.system(size: 11))
            .buttonStyle(.bordered)
            .controlSize(.small)

            Divider()
            HStack {
                Text("Wired Status 1.2.0").font(.system(size: 10)).foregroundStyle(.tertiary)
                Spacer()
                Button("检查更新") { AppUpdater.shared.checkForUpdates() }.buttonStyle(.plain)
                Button(action: quit) {
                    Label("退出", systemImage: "power").font(.system(size: 11)).foregroundStyle(.secondary)
                }.buttonStyle(.plain).help("退出有线状态")
            }
        }
        .padding(14)
        .frame(width: 320, height: panelHeight)
    }
}
