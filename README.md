# AstraPet

AstraPet 是一款原生 macOS 桌面宠物：一位温暖、安静的 AI 机器人伙伴。它会悬浮在桌面、用舒缓动作陪伴你、响应点击，并按计划发送每日提醒。

![AstraPet warm companion](Sources/AstraPet/Resources/robot-warm.png)

## 功能

- 透明、无边框、可拖动的桌面宠物窗口
- 待机、巡航、开心、休眠四种舒缓、长时连续动画
- 开心、平静、疲惫、烦躁、低落、专注六种打工人情绪
- 可选每 15、30 或 60 分钟自动轮换情绪
- 暖色实体光效底座，可调节亮度
- 光晕、气泡、轨道三种可开关防护罩
- 点击互动、气泡回应和右键动作菜单
- 琥珀、腮红、鼠尾草三套暖心光效
- 尺寸、透明度、动作速度、置顶状态设置
- 12 FPS 低功耗动画、图片缓存及精简尺寸素材，降低 CPU 和内存占用
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
