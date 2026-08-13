# codex-acct

[English](README.md) | [한국어](README.ko.md)

여러 OpenAI Codex(ChatGPT) 계정을 이름으로 골라 실행하는 작은 런처입니다.
`CODEX_HOME` 을 계정별로 갈라 쓰는 것이 전부이고, Codex CLI 를 패치하거나 감싸지 않습니다.

```bash
codex-acct work        # "work" 계정으로 codex 실행
codex-acct personal    # ...또는 "personal"
codex-acct             # 기본 계정(없으면 대화형 선택)
```

> **비공식 서드파티 도구입니다.** OpenAI 와 제휴·후원·승인 관계가 없습니다.
> 이 런처를 쓰다 생긴 문제는 여기로 신고하십시오. Codex 이슈 트래커에 올리지 마십시오.
> [`NOTICE.md`](NOTICE.md) 참고.

---

## 설계 원칙: 공개된 입력만 쓴다

Codex 공식 문서가 이 도구가 기대는 것을 그대로 정의합니다.

> Codex stores its local state under `CODEX_HOME` (defaults to `~/.codex`).
> Common files you may see there: `config.toml` … `auth.json` (if you use file-based
> credential storage) **or your OS keychain/keyring** …
>
> — [Codex advanced configuration](https://developers.openai.com/codex/config-advanced)

그래서 이 런처가 하는 일은 세 가지뿐입니다.

- `CODEX_HOME=~/.codex-accounts/<name>` 으로 `codex` 를 `exec` 한다.
- 자격증명이 없는 공용 자산을 base `~/.codex` 로 심링크한다 — `config.toml`, `AGENTS.md`,
  그리고 `skills/`·`prompts/` 의 개별 항목. 모델 설정과 커스텀 스킬이 어느 슬롯에서든 같다.
- 슬롯 목록·기본 계정·프롬프트 조각·자동완성 같은 편의를 붙인다.

`CODEX_HOME` 은 스킬·프롬프트 검색 루트까지 바꿉니다. 그래서 이 공유가 없으면 슬롯으로
띄운 순간 base 에서 만든 스킬과 커스텀 프롬프트가 전부 사라집니다. 항목 단위로 연결하므로
codex 가 관리하는 `skills/.system` 과 같은 이름의 슬롯 전용 항목은 건드리지 않습니다.

`auth.json` 은 **존재 여부만** 봅니다. 내용을 읽지 않고, 계정 간 복사하지 않습니다.
base `~/.codex` 는 건드리지 않습니다.

---

## 플랫폼별 동작 (먼저 읽으십시오)

| 자격증명 저장 모드 | 설정·스킬 | 세션(`/resume`) | **로그인 격리** |
| --- | --- | --- | --- |
| 파일 기반 (`$CODEX_HOME/auth.json`) | base 와 공유 | 계정별 분리(공유는 opt-in) | ✅ 분리됨 |
| OS keychain / keyring | base 와 공유 | 계정별 분리(공유는 opt-in) | ❌ **분리되지 않음** |

Codex 가 OS keychain/keyring 저장 모드로 동작하면 자격증명이 `CODEX_HOME` 밖에 있어서
슬롯을 갈라도 로그인은 하나로 공유됩니다. 이 도구는 슬롯에 `auth.json` 이 하나도 없을 때
그 가능성을 알려주고, 거짓 '미로그인' 으로 단정하지 않습니다.

---

## 무엇을 위한 도구인가 / 아닌가

**한 사람이 각각 정상 구독한 여러 계정을 한 머신에서 깔끔히 전환**하기 위한 것입니다.
한도를 우회하려고 계정을 풀링/로테이션하거나 하나의 구독을 여러 사람이 나눠 쓰는 용도가
**아닙니다.** 그런 사용은 OpenAI 이용약관에 어긋나며, 준수 책임은 사용자에게 있습니다.


---

## 설치

> `codex` CLI 가 PATH 에 있어야 합니다.

```bash
git clone https://github.com/yazzang-homelab/codex-acct.git
cd codex-acct
./install.sh
```

- `/usr/local/bin/codex-acct` (+ `cxa` 단축) 설치 — 이때만 sudo 를 씁니다.
- systemd **사용자 유닛**을 `~/.config/systemd/user/` 에 설치합니다. root 권한도,
  홈 경로 하드코딩도 없습니다(`%h` 사용). 선택 기능이라 기본 비활성입니다.

---

## 사용법

```bash
codex-acct add <name>            # 슬롯 생성 + codex login (브라우저 OAuth)
codex-acct <name> [args…]        # 지정 계정으로 codex 실행
codex-acct login  <name>         # (재)로그인
codex-acct logout <name>         # 자격증명 제거
codex-acct list | status         # 목록 + 로그인/포트
codex-acct default [name]        # 무인자 실행 시 기본 계정
codex-acct which | prompt        # 활성 계정 표시 / PS1 조각
codex-acct dir <name>            # CODEX_HOME 경로
codex-acct link <name> [--merge] # resume 목록을 base 와 공유
codex-acct unlink <name>         # 계정 전용 resume 목록으로 되돌림
codex-acct completion bash|zsh   # 자동완성 (alias: cxa)
```

### resume 목록 공유 (opt-in)

`/resume` 목록은 `sessions/` 를 스캔해서 나오는 게 아니라 `$CODEX_HOME/state_*.sqlite` 의
인덱스에서 나옵니다. 둘 중 하나만 연결하면 목록과 본문이 어긋나므로 `codex-acct link` 는
둘을 같이 base 로 연결합니다.

```bash
codex-acct link work          # sessions/ + state_*.sqlite → ~/.codex
codex-acct link work --merge  # 슬롯에 있던 전용 기록을 옆으로 보관한 뒤 연결
codex-acct unlink work        # 해제 — 이후 기록은 계정 전용으로 쌓임
```

기본값이 '분리' 인 이유는 하나입니다. 인덱스를 공유하면 SQLite 쓰기 락을 공유합니다.
**연결된 상태에서 두 슬롯을 동시에 띄우지 마십시오.** 이 도구는 한 번에 한 계정을 쓰는
전환기이지 풀이 아닙니다. 내용이 있는 전용 기록은 절대 덮어쓰지 않으며, `--merge` 도
병합이 아니라 `<이름>.pre-link-<시각>` 으로 옆에 보관만 합니다. codex 가 새
`state_N.sqlite` 로 마이그레이션하면 `codex-acct link` 를 다시 실행하십시오. 이미 연결된
슬롯은 실행할 때 새 인덱스를 자동으로 이어받습니다.

### 환경변수

| 변수 | 기본값 | 설명 |
|------|--------|------|
| `CODEX_ACCOUNTS_DIR` | `~/.codex-accounts` | 슬롯 루트 |
| `CODEX_BASE_HOME` | `~/.codex` | 공용 설정·스킬·프롬프트 원본 |
| `CODEX_ACCT_BIN` | `codex` | codex 바이너리 |
| `QUOTA_LOCAL_CONFIG` | `~/.config/quota-tracker/accounts.local.json` | (선택) 사용량 트래커 계정 파일 |
| `CODEX_QUOTA_PORT_BASE` | `9881` | 슬롯 app-server 시작 포트 |

---

## 선택 기능 1 — 사용량 트래커 연동

Codex 사용량은 계정별 로컬 `app-server`(WebSocket)로 조회할 수 있습니다.

```bash
codex-acct quota-enable  <name>   # 포트 배정 → systemd --user codex-app-server@<name> 기동 + 트래커 등록
codex-acct quota-disable <name>   # 인스턴스 정지 + 트래커에서 해제
```

- 포트는 `CODEX_QUOTA_PORT_BASE`(기본 `9881`)부터 자동 배정하며 이미 쓰는 포트를 피합니다.
- 배정값은 `~/.codex-accounts/<name>/app-server.env` 에 기록되고 사용자 유닛이 읽습니다.
- 트래커는 **외부 도구**입니다. `QUOTA_LOCAL_CONFIG` 가 가리키는 디렉터리가 없으면
  등록을 조용히 건너뜁니다(에러 아님).

## Gajae-Code에서 여러 계정 사용

[`gjc-acct`](https://github.com/yazzang-homelab/gjc-acct)를 사용하십시오. 각 슬롯을
`CODEX_HOME`으로 선택한 뒤 Gajae-Code의 공식 자격증명 임포터로 가져옵니다. Gajae-Code는
같은 provider의 OAuth 자격증명을 여러 개 보관하고 세션 시작 시 하나를 선택하는 기능을
네이티브로 제공합니다. 선택 전략은 `GJC_CREDENTIAL_RANKING_MODE=balanced|earliest-reset`으로
지정할 수 있습니다.

`codex-acct`는 OAuth 토큰을 추출하거나 `.env`·`models.yml`을 수정하지 않습니다.

---

## 생태계

| 도구 | 대상 | 격리 수단 |
| --- | --- | --- |
| [`claude-acct`](https://github.com/yazzang-homelab/claude-acct) | Claude Code | `CLAUDE_CONFIG_DIR` |
| **`codex-acct`** | OpenAI Codex CLI | `CODEX_HOME` |
| [`gjc-acct`](https://github.com/yazzang-homelab/gjc-acct) | Gajae-Code | 위 두 슬롯을 소비 |

---

## 라이선스 / 귀속

MIT — [`LICENSE`](LICENSE) 참고. 귀속과 의존 인터페이스의 범위는 [`NOTICE.md`](NOTICE.md).
