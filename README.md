# agents

Talon Pilot 本地 `tp-agent` 公开发布仓。

安装:

```bash
curl -fsSL https://raw.githubusercontent.com/stcn52/talon-pilot-client/main/install.sh | sh
```

Windows:

```powershell
irm https://raw.githubusercontent.com/stcn52/talon-pilot-client/main/install.ps1 | iex
```

Release 资产由 GitHub Actions 构建并保存在本仓 `/releases`。

## 发布

向本仓推送 `vX.Y.Z` tag 会触发 GitHub Actions，从
`.talon-pilot-source` 锁定的 `st52/talon-pilot` 源码提交构建
Linux x64、macOS arm64/x64 和 Windows x64。流水线会拒绝 tag 版本与主仓
workspace 版本不一致的发布，且四个资产
未全部生成时不会创建 Release。

仓库 Actions 需要 `XGIT_TOKEN` secret，其账号至少对
`st52/talon-pilot` 有只读权限。构建依赖从
`stcn52/talon-bin` 和 `stcn52/talon-sandbox-sdk-rust` 读取。

## macOS ARM64 快速测试版

在 Actions 中手动运行 `release-tp-agent-macos-arm64`，填写要测试的
`st52/talon-pilot` branch、tag 或 commit SHA。该流程只构建 Apple Silicon，
完成后自动创建 `macos-arm64-v<版本>.<run number>` Pre-release，并附带
`tp-agent-macos-arm64.tar.gz` 与 SHA256 文件；它不会改变稳定版 `vX.Y.Z`
或线上升级指针。

也可以用 GitHub CLI 触发：

```bash
gh workflow run release-macos-arm64.yml \
  --repo stcn52/talon-pilot-client \
  -f source_ref=<branch-tag-or-sha>
```
