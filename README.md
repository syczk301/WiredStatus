# 有线状态 / Wired Status

独立的 macOS 原生菜单栏工具，要求 macOS 13 以上，Universal（Apple silicon + Intel）。

- 网口内实心点：网线已连接并获得非链路本地 IP。
- 斜线：网线未连接或未检测到有线网卡。
- 感叹号：已接线，等待有效 IP。
- 点击菜单栏图标打开原生图形面板。卡片仅显示已接线并获得有效 IP 的以太网接口，提供 IP 复制按钮和可展开的 IPv6 地址；可打开网络设置及系统登录项。
- 使用系统网络变化通知，读取本机状态，不发送互联网探测请求。获得 IP 不等于互联网可达。

运行 Wired Status.app。退出可点击菜单中的“退出”。开机启动可在菜单中按需开启。
应用使用本地 ad-hoc 签名，未经 Apple 公证。Intel 为交叉编译。

从源码构建：`bash build.sh`，产物在 `build/Wired Status.app`。
