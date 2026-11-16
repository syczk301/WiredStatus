import Foundation

func iface(_ linked: Bool, _ ips: [String]) -> WiredInterface {
    WiredInterface(name: "en5", displayName: "USB Ethernet", linked: linked, addresses: ips)
}
let checks: [(String, [WiredInterface], WiredState)] = [
    ("无网卡", [], .absent),
    ("拔线且有残留 IP", [iface(false, ["192.168.1.8"])], .disconnected),
    ("DHCP 等待", [iface(true, [])], .waiting),
    ("自分配地址", [iface(true, ["169.254.2.5"])], .waiting),
    ("仅 IPv6 链路本地", [iface(true, ["fe80::123"])], .waiting),
    ("IPv6 网络", [iface(true, ["2001:db8::5"])], .connected),
    ("IPv4 网络", [iface(true, ["192.168.1.8"])], .connected),
    ("多网卡存在可用接口", [iface(false, []), iface(true, ["10.0.0.2"])], .connected),
    ("多网卡只有等待接口", [iface(false, []), iface(true, ["169.254.1.2"])], .waiting)
]
for (name, interfaces, expected) in checks {
    precondition(WiredState.resolve(interfaces) == expected, name)
    print("PASS: \(name)")
}
