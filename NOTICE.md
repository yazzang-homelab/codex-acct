# Notices

`codex-acct` is an **unofficial third-party launcher**. It is not affiliated with,
sponsored by, or endorsed by OpenAI.

## What it depends on

The tool contains no OpenAI code and does not patch, wrap, or intercept the Codex CLI.
It sets a documented input and `exec`s the real binary.

- **`CODEX_HOME`** — public, documented location for Codex local state. The official
  [advanced configuration guide](https://developers.openai.com/codex/config-advanced)
  states: *"Codex stores its local state under `CODEX_HOME` (defaults to `~/.codex`)."*
- **`$CODEX_HOME/config.toml`** — your own file, shared between slots with an ordinary
  symlink so model and settings stay identical across accounts.
- **`$CODEX_HOME/auth.json`** — used only as a boolean "has this slot logged in yet".
  Its contents are never read or copied. The same docs note credentials may live in an OS
  keychain/keyring instead, in which case per-account login isolation does not apply; the
  tool says so rather than guessing.
- **`codex login` / `codex login status` / `codex app-server`** — invoked as the documented
  CLI, never reimplemented.

Nothing here reaches into Codex internal state formats. If OpenAI changes the layout of the
files above, that is this repository's problem to fix, not theirs.

## Optional integrations

- **Usage tracker** — writes `codex_accounts` entries into a file you point
  `QUOTA_LOCAL_CONFIG` at. The tracker itself is a separate, external tool; when the path
  does not exist the integration is skipped.

## Trademarks and policy

OpenAI, ChatGPT, and Codex are trademarks of OpenAI. This tool switches between accounts
**you have separately subscribed to**. It does not pool accounts, rotate them to evade usage
limits, or share one subscription among people. Complying with OpenAI's terms remains the
user's responsibility.

## Related

- [`claude-acct`](https://github.com/yazzang-homelab/claude-acct) — same idea for Claude Code.
- [`gjc-acct`](https://github.com/yazzang-homelab/gjc-acct) — consumes slots from both.

Send bugs and questions here, not to the upstream projects' issue trackers.
