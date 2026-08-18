# AstraPet

AstraPet 是一款原生 macOS 桌面宠物：一位原创的未来感 AI 机器人助手。它会悬浮在桌面、响应点击和拖动、切换动作，并按计划发送每日提醒。

![AstraPet robot](Sources/AstraPet/Resources/robot.png)

## 功能

- 透明、无边框、可拖动的桌面宠物窗口
- 待机、巡航、开心、休眠四种连续动画
- 眨眼、挥手欢呼、闭眼休眠等独立表情与姿态
- 光环、扫描环、庆祝粒子和睡眠符号动态效果
- 点击互动、气泡回应和右键动作菜单
- 量子蓝、星云紫、极光绿三套光效
- 尺寸、透明度、动作速度、置顶状态设置
- 每日重复的 macOS 本地通知提醒
- 菜单栏快速显示/隐藏、切换动作和打开设置
- 可选登录后自动启动
- 所有偏好和提醒只保存在本机

## 环境

- macOS 13 或更高版本
- Xcode 16+（仅运行可使用 Swift 6 命令行工具；测试需要 Xcode 提供的 XCTest）

## 开发运行

```bash
swift run AstraPet
```

也可以在 Xcode 中选择 `File > Open`，直接打开仓库目录下的 `Package.swift`。

## 测试

```bash
swift test
```

## 打包为 `.app`

```bash
chmod +x scripts/build-app.sh
./scripts/build-app.sh
open dist/AstraPet.app
```

脚本会执行 release 构建、组装应用包，并使用本机 ad-hoc 签名。若要公开分发，应使用 Apple Developer ID 签名并完成 notarization。

## 使用

1. 启动后，Astra 会出现在主屏幕右下角。
2. 拖动机器人可改变位置；点击会触发回应。
3. 右键机器人可切换动作。
4. 点击菜单栏的星光图标可打开设置和提醒管理。
5. 首次添加提醒时允许通知权限。

设置窗口的“动作预览”可以直接切换四种状态；在宠物上点击右键也可以切换。

## 视觉资产

机器人视觉为本项目原创 AI 生成资产，不复刻任何影视角色、商标或标志。代码使用 MIT License；视觉资产仅随本项目使用和再分发。
