# 开发指南

[中文](DEVELOPMENT.zh-CN.md) | [English](DEVELOPMENT.en.md)

## 技术栈

- Swift 5.9
- SwiftUI
- Swift Package Manager
- macOS 14+
- SwiftTerm

## 本地运行

```bash
swift build
.build/debug/HermesManager
```

安全预览模式不会执行安装、迁移、清除或启动命令，适合调试界面：

```bash
HERMES_MANAGER_SAFE_PREVIEW=1 .build/debug/HermesManager
```

## 自测

```bash
HERMES_MANAGER_SELF_TEST=version-compare .build/debug/HermesManager
```

## 打包 DMG

```bash
scripts/build_dmg.sh
```

输出文件：

```text
dist/HermesManager-macOS.dmg
```

## 目录说明

- `Sources/`：Swift 源码。
- `Sources/Resources/`：SwiftPM 打包资源。
- `HermesManager/`：App Info.plist、图标资源和辅助资源。
- `docs/`：公开文档和截图资产。
- `scripts/`：打包脚本。
- `version-manifest.example.json`：公开远程版本清单示例。

## 不要提交的内容

- `.build/`
- `dist/`
- `HermesManager.app/`
- 本地版本控制台与本地密钥文件
- GitHub token、API Key、Web UI token
- `~/.hermes`、`~/.openhuman`、`~/.openclaw` 或任何用户记忆数据

## 贡献方向

- 安装器稳定性。
- OpenHuman memory bridge 验证。
- 更多系统状态诊断。
- 更完善的 Web UI / Gateway 进程管理。
- 更好的内置 CLI 体验。
- 后续 Agent 阶段的模型管理与模型健康检查。

## 设计原则

- Hermes 是主控大脑。
- OpenHuman 是长期记忆后端。
- Hermes Web UI 是控制平台。
- 长期记忆必须统一进入 OpenHuman。
- 公开版不能泄漏个人 token、模型配置、记忆正文或本机路径。
