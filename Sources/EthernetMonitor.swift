import Foundation
import SystemConfiguration

struct WiredInterface: Equatable {
    let name: String
    let displayName: String
    let linked: Bool
    let addresses: [String]
    var usableAddress: Bool {
        addresses.contains { address in
            let a = address.lowercased()
            return !a.hasPrefix("169.254.") && !a.hasPrefix("fe80:") && a != "0.0.0.0" && a != "::"
        }
    }
    var status: String {
        !linked ? "网线未连接" : usableAddress ? "已连接" : "已接线，等待有效 IP"
    }
}

enum WiredState: String {
    case connected, waiting, disconnected, absent
    static func resolve(_ interfaces: [WiredInterface]) -> WiredState {
        if interfaces.contains(where: { $0.linked && $0.usableAddress }) { return .connected }
        if interfaces.contains(where: { $0.linked }) { return .waiting }
        return interfaces.isEmpty ? .absent : .disconnected
    }
    var title: String {
        switch self {
        case .connected: return "有线网络已连接"
        case .waiting: return "已接线，等待有效 IP"
        case .disconnected: return "网线未连接"
        case .absent: return "未检测到有线网卡"
        }
    }
}

final class EthernetMonitor {
    private var store: SCDynamicStore?
    private var source: CFRunLoopSource?
    private var debounce: DispatchWorkItem?
    var interfaces: [WiredInterface] = []
    var onChange: (() -> Void)?
    var state: WiredState { WiredState.resolve(interfaces) }
    var connectedInterfaces: [WiredInterface] { interfaces.filter { $0.linked && $0.usableAddress } }

    init() {
        var context = SCDynamicStoreContext(version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(), retain: nil, release: nil, copyDescription: nil)
        store = SCDynamicStoreCreate(nil, "WiredStatus" as CFString, { _, _, info in
            guard let info else { return }
            Unmanaged<EthernetMonitor>.fromOpaque(info).takeUnretainedValue().scheduleRefresh()
        }, &context)
        refresh()
    }

    func start() {
        guard let store else { return }
        let patterns = ["State:/Network/Interface/.*", "Setup:/Network/Service/.*", "State:/Network/Global/.*"]
        SCDynamicStoreSetNotificationKeys(store, nil, patterns as CFArray)
        source = SCDynamicStoreCreateRunLoopSource(nil, store, 0)
        if let source { CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes) }
    }

    func stop() {
        debounce?.cancel()
        if let source { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
        source = nil
    }

    private func scheduleRefresh() {
        debounce?.cancel()
        let task = DispatchWorkItem { [weak self] in self?.refresh() }
        debounce = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: task)
    }

    func refresh() {
        let all = SCNetworkInterfaceCopyAll() as? [SCNetworkInterface] ?? []
        interfaces = all.compactMap { interface in
            guard SCNetworkInterfaceGetInterfaceType(interface) == kSCNetworkInterfaceTypeEthernet,
                  let bsd = SCNetworkInterfaceGetBSDName(interface) as String? else { return nil }
            let label = (SCNetworkInterfaceGetLocalizedDisplayName(interface) as String?) ?? bsd
            func entity(_ name: String) -> [String: Any] {
                guard let store else { return [:] }
                return SCDynamicStoreCopyValue(store, "State:/Network/Interface/\(bsd)/\(name)" as CFString) as? [String: Any] ?? [:]
            }
            let addresses = (entity("IPv4")["Addresses"] as? [String] ?? []) +
                (entity("IPv6")["Addresses"] as? [String] ?? [])
            return WiredInterface(name: bsd, displayName: label,
                linked: entity("Link")["Active"] as? Bool ?? false, addresses: addresses)
        }.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        onChange?()
    }
}
