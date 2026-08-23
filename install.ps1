# Talon Pilot · tp-agent 一键安装(Windows / PowerShell)。
#   irm https://raw.githubusercontent.com/stcn52/talon-pilot-client/main/install.ps1 | iex
#
# 从公开仓 https://github.com/stcn52/talon-pilot-client 的 Release 下 tp-agent + tp,
# 装进用户目录并加入 PATH,随后准备默认 Open Interpreter runtime,
# 最后在可交互终端里登录到本站。
$ErrorActionPreference = "Stop"

$releaseBase = if ([string]::IsNullOrWhiteSpace($env:TP_AGENT_RELEASE_BASE)) { "https://github.com/stcn52/talon-pilot-client" } else { $env:TP_AGENT_RELEASE_BASE }
$releaseApi = if ([string]::IsNullOrWhiteSpace($env:TP_AGENT_RELEASE_API)) { "https://api.github.com/repos/stcn52/talon-pilot-client" } else { $env:TP_AGENT_RELEASE_API }
$apiBase = if ([string]::IsNullOrWhiteSpace($env:TP_API_BASE)) { "https://ai.xgit.pro" } else { $env:TP_API_BASE }
$webBase = if ([string]::IsNullOrWhiteSpace($env:TP_WEB_BASE)) { $apiBase } else { $env:TP_WEB_BASE }
$asset = "tp-agent-windows-x64.zip"
if (-not [string]::IsNullOrWhiteSpace($env:TP_AGENT_ASSET_URL)) {
  $url = $env:TP_AGENT_ASSET_URL
} elseif (-not [string]::IsNullOrWhiteSpace($env:TP_AGENT_VERSION)) {
  $url = "$releaseBase/releases/download/$($env:TP_AGENT_VERSION)/$asset"
} else {
  $rel = Invoke-RestMethod -Uri "$releaseApi/releases/latest"
  $match = @($rel.assets | Where-Object { $_.name -eq $asset })
  if ($match.Count -lt 1 -or [string]::IsNullOrWhiteSpace($match[0].browser_download_url)) {
    throw "无法解析最新 Release,请检查 $releaseBase"
  }
  $url = $match[0].browser_download_url
}

$tmp = Join-Path $env:TEMP ("tp-agent-" + [guid]::NewGuid())
New-Item -ItemType Directory -Force -Path $tmp | Out-Null
try {
  Write-Host "↓ " -ForegroundColor Blue -NoNewline
  Write-Host "下载 tp-agent " -NoNewline
  Write-Host "($asset)…" -ForegroundColor DarkGray
  Invoke-WebRequest -Uri $url -OutFile "$tmp\$asset"
  Expand-Archive -Path "$tmp\$asset" -DestinationPath $tmp -Force
  if (-not (Test-Path "$tmp\tp-agent.exe" -PathType Leaf)) {
    throw "安装包缺少 tp-agent.exe，拒绝安装"
  }
  if (-not (Test-Path "$tmp\tp.exe" -PathType Leaf)) {
    throw "安装包缺少配套控制面命令 tp.exe，拒绝安装"
  }

  $dest = if ([string]::IsNullOrWhiteSpace($env:TP_AGENT_INSTALL_DIR)) {
    Join-Path $env:LOCALAPPDATA "Programs\tp-agent"
  } else {
    $env:TP_AGENT_INSTALL_DIR
  }
  New-Item -ItemType Directory -Force -Path $dest | Out-Null
  Move-Item -Force "$tmp\tp.exe" "$dest\tp.exe"
  Move-Item -Force "$tmp\tp-agent.exe" "$dest\tp-agent.exe"

  $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
  if ($userPath -notlike "*$dest*") {
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$dest", "User")
    Write-Host "✓ " -ForegroundColor Green -NoNewline
    Write-Host "已把 $dest 加入用户 PATH" -NoNewline
    Write-Host " (新开终端生效)" -ForegroundColor DarkGray
  }
  $bin = Join-Path $dest "tp-agent.exe"
  $tpBin = Join-Path $dest "tp.exe"
  Write-Host "✓ " -ForegroundColor Green -NoNewline
  Write-Host "已安装: $bin"
  Write-Host "✓ " -ForegroundColor Green -NoNewline
  Write-Host "已安装: $tpBin"

  Write-Host ""
  Write-Host "→ " -ForegroundColor Blue -NoNewline
  Write-Host "准备默认 runtime: Open Interpreter…"
  & $bin runtime ensure
  if ($LASTEXITCODE -ne 0) {
    throw "Open Interpreter 安装或验证失败。修复网络后请重跑安装器，或执行: $bin runtime ensure"
  }

  $loginArgs = @("login", "--api-base-url", $apiBase, "--web-base-url", $webBase)
  if ([Environment]::UserInteractive -and -not [Console]::IsInputRedirected) {
    Write-Host ""
    Write-Host "→ " -ForegroundColor Blue -NoNewline
    Write-Host "开始登录 $apiBase…"
    try {
      & $bin @loginArgs
    } catch {
      Write-Host ""
      Write-Host "⚠ 自动登录未完成,稍后手动重试: " -ForegroundColor Yellow -NoNewline
      Write-Host "tp-agent login --api-base-url $apiBase --web-base-url $webBase" -ForegroundColor Cyan
    }
  } else {
    Write-Host ""
    Write-Host "下一步: " -NoNewline
    Write-Host "tp-agent login --api-base-url $apiBase --web-base-url $webBase" -ForegroundColor Cyan
  }
} finally {
  Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
}
