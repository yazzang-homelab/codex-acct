# codex-acct

[English](README.md) | [한국어](README.ko.md)

A small launcher for switching between named OpenAI Codex (ChatGPT) accounts. It separates
accounts with `CODEX_HOME`; it does not patch or wrap the Codex CLI.

```bash
codex-acct work        # launch Codex with the "work" account
codex-acct personal    # launch with "personal"
codex-acct             # launch the default account, or show a picker
```

> **Unofficial third-party tool.** Not affiliated with, sponsored by, or endorsed by OpenAI.
> Report problems with this launcher here, not to the Codex issue tracker. See
> [`NOTICE.md`](NOTICE.md).

---

## Design principle: use documented inputs only

The official Codex documentation defines the interface this launcher uses:

> Codex stores its local state under `CODEX_HOME` (defaults to `~/.codex`).
> Common files you may see there: `config.toml` … `auth.json` (if you use file-based
> credential storage) **or your OS keychain/keyring** …
>
> — [Codex advanced configuration](https://developers.openai.com/codex/config-advanced)

The launcher does only three things:

- executes `codex` with `CODEX_HOME=~/.codex-accounts/<name>`;
- symlinks the shared `config.toml` from the base `~/.codex`, keeping model settings
  consistent across accounts; and
- provides named slots, status, a default account, a prompt segment, and shell completion.

It checks only whether `auth.json` exists. It never reads or copies credential contents and
never modifies the base `~/.codex` account.

---

## Platform behavior

| Credential storage mode | Settings and sessions | **Login isolation** |
| --- | --- | --- |
| File-based (`$CODEX_HOME/auth.json`) | isolated per account | ✅ isolated |
| OS keychain/keyring | isolated per account | ❌ **not isolated** |

When Codex stores credentials in an OS keychain/keyring, the login lives outside
`CODEX_HOME`, so every slot shares the same login. If no slot contains `auth.json`, the
launcher warns about this possibility instead of falsely claiming that every slot is logged
out.

---

## Intended use

This tool is for **one person who separately subscribes to multiple accounts** and wants to
switch between them cleanly on one machine. It is not for pooling or rotating accounts to
circumvent usage limits, or for sharing one subscription between people. Users remain
responsible for complying with OpenAI's terms.

---

## Install

> The `codex` CLI must be on `PATH`.

```bash
git clone https://github.com/yazzang-homelab/codex-acct.git
cd codex-acct
./install.sh
```

The installer places `codex-acct` and the `cxa` alias in `/usr/local/bin` (the only step that
may use `sudo`). Optional systemd **user units** go under `~/.config/systemd/user`; they do
not run as root or contain a hard-coded home path.

---

## Usage

```bash
codex-acct add <name>            # create a slot and run browser OAuth login
codex-acct <name> [args…]        # launch Codex with a named account
codex-acct login  <name>         # log in again
codex-acct logout <name>         # remove that slot's credentials
codex-acct list | status         # list login state and tracker port
codex-acct default [name]        # get or set the default account
codex-acct which | prompt        # active account / shell prompt segment
codex-acct dir <name>            # print the slot's CODEX_HOME
codex-acct completion bash|zsh   # shell completion (also supports the cxa alias)
```

### Environment variables

| Variable | Default | Purpose |
| --- | --- | --- |
| `CODEX_ACCOUNTS_DIR` | `~/.codex-accounts` | Slot root |
| `CODEX_BASE_HOME` | `~/.codex` | Source of the shared `config.toml` |
| `CODEX_ACCT_BIN` | `codex` | Codex executable |
| `QUOTA_LOCAL_CONFIG` | `~/.config/quota-tracker/accounts.local.json` | Optional usage-tracker account file |
| `CODEX_QUOTA_PORT_BASE` | `9881` | First app-server port assigned to a slot |

---

## Optional usage-tracker integration

Codex usage can be queried through a local per-account `app-server` WebSocket:

```bash
codex-acct quota-enable  <name>   # allocate a port, start the user unit, register the slot
codex-acct quota-disable <name>   # stop the instance and unregister the slot
```

- Ports are allocated from `CODEX_QUOTA_PORT_BASE`, skipping ports already assigned.
- `CODEX_HOME` and the assigned port are stored in
  `~/.codex-accounts/<name>/app-server.env` for the user unit.
- The tracker is an external tool. If the directory containing `QUOTA_LOCAL_CONFIG` does not
  exist, registration is skipped; account switching still works normally.

## Using multiple accounts with Gajae-Code

Use [`gjc-acct`](https://github.com/yazzang-homelab/gjc-acct). It selects a slot through
`CODEX_HOME` and imports it with Gajae-Code's official credential importer. Gajae-Code can
store multiple OAuth credentials for one provider and select one when a session starts.
Choose the strategy with
`GJC_CREDENTIAL_RANKING_MODE=balanced|earliest-reset`.

`codex-acct` never extracts OAuth tokens or modifies gjc's `.env` or `models.yml`.

---

## Ecosystem

| Tool | Target | Isolation mechanism |
| --- | --- | --- |
| [`claude-acct`](https://github.com/yazzang-homelab/claude-acct) | Claude Code | `CLAUDE_CONFIG_DIR` |
| **`codex-acct`** | OpenAI Codex CLI | `CODEX_HOME` |
| [`gjc-acct`](https://github.com/yazzang-homelab/gjc-acct) | Gajae-Code | consumes slots from both |

---

## License and attribution

MIT — see [`LICENSE`](LICENSE). Upstream attribution and the interfaces this tool depends on
are documented in [`NOTICE.md`](NOTICE.md).
