#!/usr/bin/env bash
#
# codex-acct 설치 스크립트.
#   * codex-acct 를 /usr/local/bin 에 설치하고 cxa 단축 심링크를 만든다.
#   * systemd *사용자* 유닛을 ~/.config/systemd/user 에 설치한다(root 불필요).
#   * root 가 아니면 바이너리 설치에만 sudo 를 자동 사용한다.
#
# 로컬에서:   ./install.sh
#
set -euo pipefail

say()  { printf '\033[36m%s\033[0m\n' "$*"; }
ok()   { printf '\033[32m%s\033[0m\n' "$*"; }
err()  { printf '\033[31m%s\033[0m\n' "$*" >&2; }

HERE="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd)"
SRC="$HERE/codex-acct"
UNIT_DIR="$HERE/systemd"
[[ -f "$SRC" ]] || { err "codex-acct 스크립트를 찾을 수 없습니다: $SRC"; exit 1; }

SUDO=""; [[ "$(id -u)" -ne 0 ]] && command -v sudo >/dev/null 2>&1 && SUDO="sudo"

BIN_DIR="/usr/local/bin"
$SUDO install -m 0755 "$SRC" "$BIN_DIR/codex-acct"
$SUDO ln -sfn "$BIN_DIR/codex-acct" "$BIN_DIR/cxa"
ok "설치: $BIN_DIR/codex-acct (+ cxa)"

# systemd 사용자 유닛(선택). root 권한도, 홈 경로 하드코딩도 필요 없다.
USER_UNIT_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
if [[ -d "$UNIT_DIR" ]] && command -v systemctl >/dev/null 2>&1; then
  mkdir -p "$USER_UNIT_DIR"
  install -m 0644 "$UNIT_DIR"/*.service "$USER_UNIT_DIR/" 2>/dev/null || true
  systemctl --user daemon-reload 2>/dev/null || true
  ok "설치: $USER_UNIT_DIR (codex-app-server@)"
  say "  사용량 트래커용 app-server 는 codex-acct quota-enable <name> 로 켭니다."
fi

command -v codex >/dev/null 2>&1 || err "주의: 'codex' CLI 가 PATH 에 없습니다 — OpenAI Codex 를 먼저 설치하세요."

cat <<'NEXT'

다음 단계:
  1) 계정 추가/로그인:   codex-acct add <name>       (브라우저 OAuth 로그인)
  2) 지정 계정 실행:      codex-acct <name>
  3) 기본 계정 지정:      codex-acct default <name>
  4) 사용량 트래커 등록:  codex-acct quota-enable <name>   (선택, QUOTA_LOCAL_CONFIG 필요)
  5) 자동완성:            eval "$(codex-acct completion bash)"   # alias: cxa

프로젝트가 도움이 됐다면 GitHub에서 Star로 응원해 주세요(선택):
  https://github.com/yazzang-homelab/codex-acct
NEXT
