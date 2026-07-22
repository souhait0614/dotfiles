# Repository guidance

This is a personal chezmoi source repository. Read [README.md](README.md) for
supported platforms, initial setup, and manual rebuild commands. The chezmoi
source root is `home/`, as configured by `.chezmoiroot`.

## Ownership and editing

- Edit files under `home/`, not their rendered copies under `$HOME`.
- Keep version and tool data in the concern-specific files under
  `home/.chezmoidata/`. Common CLI packages and macOS fonts belong in
  `nix.toml`; Homebrew is only for macOS-specific formulae and applications.
- Keep machine-derived values (`platform`, `useSudo`, and `brew_command`) in
  `home/.chezmoi.toml.tmpl`. Use `.platform` elsewhere instead of branching on
  `.chezmoi.os` or `.chezmoi.arch`. Supported values are `darwin-arm64`,
  `linux-arm64`, and `linux-x86_64`; Intel macOS is unsupported.
- Preserve chezmoi naming semantics: `dot_` maps to a leading dot, `private_`
  sets private permissions, `.tmpl` is rendered as a Go template, and scripts in
  `home/.chezmoiscripts/` run in filename order according to their `run_once_`
  or `run_onchange_` prefix.
- Do not commit credentials, tokens, or private keys. The `private_` prefix
  controls destination permissions; it does not make repository content secret.
- Edit `home/deno_scripts/karabiner/generate_config.ts` or its
  `base_config.json`, not the generated `~/.config/karabiner/karabiner.json`.
  Destination `flake.lock` files are also generated state and are not repository
  sources.
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
  validation. The authoritative end-to-end check is `.github/workflows/ci.yaml`,
  which runs `chezmoi init --apply` on macOS and Linux for changes under
  `home/**`.
