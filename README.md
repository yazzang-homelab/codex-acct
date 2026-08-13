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
- symlinks shared, credential-free assets from the base `~/.codex` — `config.toml`,
  `AGENTS.md`, and the individual entries of `skills/` and `prompts/` — so model settings
  and custom skills behave identically in every slot; and
- provides named slots, status, a default account, a prompt segment, and shell completion.

`CODEX_HOME` also relocates the skill and prompt lookup roots, so without this sharing a
slot would silently lose every skill and custom prompt you created in the base account.
Entries are linked one by one: Codex-managed items (`skills/.system`) and any slot-local
entry of the same name are left untouched.

It checks only whether `auth.json` exists. It never reads or copies credential contents and
never modifies the base `~/.codex` account.

---

## Platform behavior

| Credential storage mode | Settings & skills | Sessions (`/resume`) | **Login isolation** |
| --- | --- | --- | --- |
| File-based (`$CODEX_HOME/auth.json`) | shared with base | isolated (opt-in sharing) | ✅ isolated |
| OS keychain/keyring | shared with base | isolated (opt-in sharing) | ❌ **not isolated** |

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
codex-acct link <name> [--merge] # share the resume list with the base account
codex-acct unlink <name>         # go back to a slot-private resume list
codex-acct completion bash|zsh   # shell completion (also supports the cxa alias)
```

### Sharing the resume list (opt-in)

The `/resume` list does not come from scanning `sessions/`; it comes from the index in
`$CODEX_HOME/state_*.sqlite`. Linking only one of the two leaves the list and the transcripts
out of sync, so `codex-acct link` connects both to the base account:

```bash
codex-acct link work          # sessions/ + state_*.sqlite -> ~/.codex
codex-acct link work --merge  # same, but move an existing slot-private record aside first
codex-acct unlink work        # detach; later sessions stay slot-private
```

This is off by default, and for one reason: a shared index means a shared SQLite writer
lock. **Do not run two slots at the same time while they are linked** — this launcher is a
one-account-at-a-time switcher, not a pool. A slot-private record with content is never
overwritten; `--merge` moves it aside as `<name>.pre-link-<timestamp>` instead of merging it.
When Codex migrates to a new `state_N.sqlite`, run `codex-acct link` again — launching an
already-linked slot picks the new index up automatically.

### Environment variables

| Variable | Default | Purpose |
| --- | --- | --- |
| `CODEX_ACCOUNTS_DIR` | `~/.codex-accounts` | Slot root |
| `CODEX_BASE_HOME` | `~/.codex` | Source of the shared config, skills, and prompts |
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
