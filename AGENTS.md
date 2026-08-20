# Repository guidance

This is a personal chezmoi source repository. Read [README.md](README.md) for
supported platforms, initial setup, and manual rebuild commands. The chezmoi
source root is `home/`, as configured by `.chezmoiroot`.
CI runs `chezmoi init --apply` on macOS and Linux for pushes that change
`home/**`.

## Ownership and editing

- Edit files under `home/`, not their rendered copies under `$HOME`.
- Keep version and tool data in the concern-specific files under
  `home/.chezmoidata/`: `versions.toml`, `lix.toml`, `nix.toml`, and
  `homebrew.toml`. Common CLI packages and macOS fonts belong in `nix.toml`;
  Homebrew is only for macOS-specific formulae and applications.
- Keep machine-derived values (`platform`, `useSudo`, and `brewCommand`) in
  `home/.chezmoi.toml.tmpl`. Use `.platform` elsewhere instead of branching on
  `.chezmoi.os` or `.chezmoi.arch`. Supported values are `darwin-arm64`,
  `linux-arm64`, and `linux-x86_64`; Intel macOS is unsupported.
- Preserve chezmoi naming semantics: `dot_` maps to a leading dot, `private_`
  sets private permissions, `.tmpl` is rendered as a Go template, and scripts in
  `home/.chezmoiscripts/` run in filename order according to their `run_once_`
  or `run_onchange_` prefix. The scripts install or upgrade Lix, install
  Homebrew on Apple Silicon macOS, apply the unified Nix configuration for the
  current platform, and generate Karabiner-Elements configuration on Apple
  Silicon macOS.
- Do not commit credentials, tokens, or private keys. The `private_` prefix
  controls destination permissions; it does not make repository content secret.
- Edit `home/deno_scripts/karabiner/generate_config.ts` or its
  `base_config.json`, not the generated `~/.config/karabiner/karabiner.json`.
  Edit `home/dot_config/nix/flake.nix.tmpl` for the cross-platform package and
  nix-darwin flake. Platform-specific source locks live at
  `home/dot_config/nix/.flake-darwin.lock` and `.flake-linux.lock`; the rendered
  lock is selected by `home/dot_config/nix/flake.lock.tmpl`. Do not edit the
  rendered lock in the home directory.
- The source uses age encryption configured by `home/.chezmoi.toml.tmpl`.
  Git profile files under `home/dot_config/git/profiles/` are encrypted and
  should remain encrypted; never add credentials, tokens, private keys, or
  plaintext decrypted profiles.
- Shell scripts use Bash when they rely on `pipefail`, arrays, or `[[ ... ]]`.
  When a variable touches Japanese or other non-ASCII text, write `${name}` to
  make the variable boundary explicit.

## Validation

Run the smallest relevant checks first:

- For every change: `git diff --check`.
- For chezmoi templates and scripts, preview this worktree with a disposable
  config so the user's active chezmoi config is not used or overwritten:

  ```sh
  config_file="$(mktemp)"
  chezmoi execute-template --init < home/.chezmoi.toml.tmpl > "$config_file"
  chezmoi --config "$config_file" --config-format toml \
    --source "$PWD/home" apply --dry-run
  rm -f "$config_file"
  ```

  Keep platform branches renderable for all three supported `.platform` values;
  syntax-check each rendered shell script with `bash -n`.

- For Karabiner TypeScript:
  `mise exec deno@2.7.1 -- deno fmt --check home/deno_scripts/karabiner` and
  `mise exec deno@2.7.1 -- deno check home/deno_scripts/karabiner/generate_config.ts`.
- Nix is not guaranteed to be installed on the development machine. If it is
  unavailable, state that Nix evaluation/build was not run instead of claiming
  validation. The authoritative end-to-end check is
  `.github/workflows/ci.yaml`, which runs `chezmoi init --apply` on macOS and
  Linux and supplies the GitHub token to Nix and Homebrew.
