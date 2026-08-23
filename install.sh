#!/bin/sh
# Talon Pilot · tp-agent 一键安装(macOS / Linux)。
#   curl -fsSL https://raw.githubusercontent.com/stcn52/talon-pilot-client/main/install.sh | sh
#
# 从公开仓 https://github.com/stcn52/talon-pilot-client 的 Release 下对应平台的
# tp-agent + 控制面辅助命令 tp 装进 PATH,随后自动准备默认的
# Open Interpreter runtime,最后在可交互终端里登录到本站。
set -e

RELEASE_BASE="${TP_AGENT_RELEASE_BASE:-https://github.com/stcn52/talon-pilot-client}"
RELEASE_API="${TP_AGENT_RELEASE_API:-https://api.github.com/repos/stcn52/talon-pilot-client}"
API_BASE="${TP_API_BASE:-https://ai.xgit.pro}"
WEB_BASE="${TP_WEB_BASE:-$API_BASE}"
OS="$(uname -s)"
ARCH="$(uname -m)"

if [ -t 1 ]; then
  C_BOLD="$(printf '\033[1m')"; C_DIM="$(printf '\033[2m')"
  C_GREEN="$(printf '\033[32m')"; C_BLUE="$(printf '\033[34m')"
  C_YELLOW="$(printf '\033[33m')"; C_CYAN="$(printf '\033[36m')"; C_RESET="$(printf '\033[0m')"
else
  C_BOLD=; C_DIM=; C_GREEN=; C_BLUE=; C_YELLOW=; C_CYAN=; C_RESET=
fi

case "${OS}-${ARCH}" in
  Darwin-arm64) ASSET="tp-agent-macos-arm64.tar.gz" ;;
  Darwin-x86_64) ASSET="tp-agent-macos-x64.tar.gz" ;;
  Linux-x86_64|Linux-amd64) ASSET="tp-agent-linux-x64.tar.gz" ;;
  *) echo "${C_YELLOW}不支持的平台: ${OS}-${ARCH}${C_RESET}(目前支持 macOS arm64/x64、Linux x64)" >&2; exit 1 ;;
esac

if [ -n "${TP_AGENT_ASSET_URL:-}" ]; then
  URL="$TP_AGENT_ASSET_URL"
elif [ -n "${TP_AGENT_VERSION:-}" ]; then
  URL="${RELEASE_BASE}/releases/download/${TP_AGENT_VERSION}/${ASSET}"
else
  # 查公开 API，避免依赖重定向后的最终 tag。
  URL="$(curl -fsSL "${RELEASE_API}/releases/latest" 2>/dev/null \
    | grep -o "https://[^\"\\\\]*${ASSET}" | head -n 1 || true)"
  if [ -z "$URL" ]; then
    echo "${C_YELLOW}无法解析最新 Release,请检查 ${RELEASE_BASE}${C_RESET}" >&2
    exit 1
  fi
fi
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

printf '%s↓%s 下载 tp-agent %s(%s)%s…\n' "$C_BLUE" "$C_RESET" "$C_DIM" "$ASSET" "$C_RESET"
curl -fsSL "$URL" -o "$TMP/$ASSET"
tar -xzf "$TMP/$ASSET" -C "$TMP"
[ -f "$TMP/tp-agent" ] || {
  echo "${C_YELLOW}安装包缺少 tp-agent，拒绝安装${C_RESET}" >&2
  exit 1
}
[ -f "$TMP/tp" ] || {
  echo "${C_YELLOW}安装包缺少配套控制面命令 tp，拒绝安装${C_RESET}" >&2
  exit 1
}

DEST="${TP_AGENT_INSTALL_DIR:-/usr/local/bin}"
if [ -z "${TP_AGENT_INSTALL_DIR:-}" ] && [ ! -w "$DEST" ]; then
  DEST="$HOME/.local/bin"
fi
mkdir -p "$DEST"
install -m 0755 "$TMP/tp" "$DEST/tp" 2>/dev/null \
  || { cp "$TMP/tp" "$DEST/tp"; chmod +x "$DEST/tp"; }
install -m 0755 "$TMP/tp-agent" "$DEST/tp-agent" 2>/dev/null \
  || { cp "$TMP/tp-agent" "$DEST/tp-agent"; chmod +x "$DEST/tp-agent"; }

BIN="$DEST/tp-agent"
TP_BIN="$DEST/tp"
printf '%s✓%s 已安装: %s%s%s\n' "$C_GREEN" "$C_RESET" "$C_BOLD" "$BIN" "$C_RESET"
printf '%s✓%s 已安装: %s%s%s\n' "$C_GREEN" "$C_RESET" "$C_BOLD" "$TP_BIN" "$C_RESET"

case ":$PATH:" in
  *":$DEST:"*) PATH_OK=1 ;;
  *) PATH_OK=0
     printf '%s⚠%s %s 不在 PATH,请加入: %sexport PATH="%s:$PATH"%s\n' \
       "$C_YELLOW" "$C_RESET" "$DEST" "$C_CYAN" "$DEST" "$C_RESET" ;;
esac

printf '\n%s→%s 准备默认 runtime: Open Interpreter…\n' "$C_BLUE" "$C_RESET"
if ! "$BIN" runtime ensure; then
  printf '%s✗%s Open Interpreter 安装或验证失败。修复网络后可重跑安装器，或执行: %s%s runtime ensure%s\n' \
    "$C_YELLOW" "$C_RESET" "$C_CYAN" "$BIN" "$C_RESET" >&2
  exit 1
fi

LOGIN_CMD="$BIN login --api-base-url $API_BASE --web-base-url $WEB_BASE"
if [ -t 0 ] && [ -t 1 ]; then
  printf '\n%s→%s 开始登录 %s…\n' "$C_BLUE" "$C_RESET" "$API_BASE"
  $LOGIN_CMD || {
    printf '\n%s⚠%s 自动登录未完成,稍后手动重试: %s%s%s\n' \
      "$C_YELLOW" "$C_RESET" "$C_CYAN" "$LOGIN_CMD" "$C_RESET"
  }
else
  printf '\n下一步: %s%s%s\n' "$C_CYAN" "$LOGIN_CMD" "$C_RESET"
fi
