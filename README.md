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
