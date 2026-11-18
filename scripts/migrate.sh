#!/usr/bin/env bash
set -euo pipefail

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

resolve_executable() {
  local target="$1" link
  while [[ -L "$target" ]]; do
    link="$(readlink "$target")"
    if [[ "$link" = /* ]]; then
      target="$link"
    else
      target="$(dirname "$target")/$link"
    fi
  done
  printf '%s/%s\n' "$(cd "$(dirname "$target")" && pwd -P)" "$(basename "$target")"
}

validate_path() {
  local target="$1" parent physical
  [[ "$target" = "$HOME/"* ]] || die "Refusing a path outside HOME: $target"
  case "$target/" in
    */../*|*/./*) die "Refusing a non-normalized path: $target" ;;
  esac
  parent="$(dirname "$target")"
  while [[ ! -d "$parent" ]]; do
    parent="$(dirname "$parent")"
  done
  physical="$(cd "$parent" && pwd -P)"
  [[ "$physical" = "$HOME" || "$physical" = "$HOME/"* ]] \
    || die "A parent directory points outside HOME: $target"
  [[ "$physical" != "$repo_root" && "$physical" != "$repo_root/"* ]] \
    || die "Refusing to modify the migration checkout: $target"
  if [[ -d "$target" && ! -L "$target" ]]; then
    physical="$(cd "$target" && pwd -P)"
    [[ "$repo_root" != "$physical" && "$repo_root" != "$physical/"* ]] \
      || die "Clone this repository outside the old chezmoi source directory first."
  fi
}

add_backup_path() {
  local target="$1" existing
  local retained=()
  case "$target" in
    "$HOME/.ssh/config"|"$HOME/.ssh/conf.d/00-github"|"$HOME/.ssh/conf.d/00-ssh")
      [[ "$ssh_mode" != skip ]] || return 0
      ;;
    "$HOME/.ssh"|"$HOME/.ssh/"*|"$HOME/.gnupg"|"$HOME/.gnupg/"*|\
    "$HOME/.dotfiles-encrypt-key.txt"|"$HOME/.git-credentials"|"$HOME/.netrc"|\
    "$config_home/gh"|"$config_home/gh/"*|\
    "$config_home/git/profiles"|"$config_home/git/profiles/"*)
      return
      ;;
  esac
  [[ -e "$target" || -L "$target" ]] || return 0
  for existing in "${backup_paths[@]:-}"; do
    [[ -n "$existing" ]] || continue
    [[ "$target" != "$existing" && "$target" != "$existing/"* ]] || return 0
    if [[ "$existing" != "$target/"* ]]; then
      retained+=("$existing")
    fi
  done
  validate_path "$target"
  backup_paths=("${retained[@]:-}" "$target")
}

collect_backup_paths() {
  local target managed source
  backup_paths=()
  for target in \
    "$config_home/zsh" "$config_home/mise" "$config_home/sheldon" \
    "$config_home/nix" "$config_home/nix-darwin" \
    "$HOME/.zshenv" "$HOME/.apm" "$HOME/deno_scripts" \
    "$HOME/.claude/keybindings.json" \
    "$HOME/.copilot/copilot-instructions.md" "$HOME/.copilot/settings.json" \
    "$HOME/.ssh/config" "$HOME/.ssh/conf.d/00-github" "$HOME/.ssh/conf.d/00-ssh" \
    "$config_home/ghostty/config" "$config_home/herdr/config.toml" \
    "$config_home/tinycast/settings.json" "$config_home/karabiner/karabiner.json" \
    "$config_home/git/config" "$config_home/git/alias.gitconfig" "$config_home/git/ignore" \
    "$config_home/git/profile.gitconfig" \
    "$HOME/.nix-profile" "$HOME/.nix-defexpr" "$HOME/.nix-channels" "$HOME/.nixpkgs" \
    "$state_home/nix" "$data_home/nix" "$cache_home/nix" \
    "$HOME/.local/bin/chezmoi" "$HOME/bin/chezmoi"; do
    add_backup_path "$target"
  done

  if command -v chezmoi >/dev/null 2>&1 && [[ -d "$config_home/chezmoi" ]]; then
    source="$(chezmoi source-path)"
    managed="$(chezmoi managed --exclude dirs,scripts,encrypted --path-style absolute)"
    while IFS= read -r target; do
      [[ -n "$target" ]] || continue
      add_backup_path "$target"
    done <<< "$managed"
    add_backup_path "$source"
  else
    printf '%s\n' "No usable chezmoi metadata; using this repository's known legacy paths."
  fi

  for target in "$config_home/chezmoi" "$data_home/chezmoi" \
    "$state_home/chezmoi" "$cache_home/chezmoi"; do
    add_backup_path "$target"
  done
}

nix_is_present() {
  [[ -d /nix/store || -e /nix/receipt.json ]]
}

nix_volume_is_present() {
  local volumes
  volumes="$(/usr/sbin/diskutil apfs list -plist | /usr/bin/plutil -p -)" \
    || die "Could not inspect APFS volumes; refusing to continue."
  grep -q '"Name" => "Nix Store"' <<< "$volumes"
}

darwin_is_present() {
  [[ -e /run/current-system || -e /Library/LaunchDaemons/org.nixos.activate-system.plist ]]
}

inspect_nix() {
  nix_installer=""
  nix_command=""
  darwin_uninstaller=""
  nix_present=false
  darwin_present=false
  [[ ! -e /etc/NIXOS ]] || die "NixOS cannot be migrated by uninstalling system Nix."
  if nix_is_present; then
    nix_present=true
    for nix_installer in /nix/lix-installer /nix/nix-installer; do
      [[ ! -x "$nix_installer" ]] || break
    done
    [[ -x "$nix_installer" && -f /nix/receipt.json ]] \
      || die "No installer receipt/uninstaller. Follow your Nix installer's uninstall instructions, then rerun."
  elif [[ "$os" = Darwin ]] && nix_volume_is_present; then
    die "An unmounted Nix Store volume remains. Complete its uninstall before rerunning; do not start a new Nix installation."
  fi
  if [[ "$os" = Darwin ]] && darwin_is_present; then
    darwin_present=true
    if [[ -x /run/current-system/sw/bin/darwin-uninstaller ]]; then
      darwin_uninstaller=/run/current-system/sw/bin/darwin-uninstaller
    else
      for nix_command in /nix/var/nix/profiles/default/bin/nix /run/current-system/sw/bin/nix; do
        [[ ! -x "$nix_command" ]] || break
      done
      [[ -x "$nix_command" ]] || die "Restore Nix and uninstall nix-darwin before migrating."
    fi
  fi
}

uninstall_darwin() {
  if [[ -n "$darwin_uninstaller" ]]; then
    sudo "$darwin_uninstaller" </dev/null
  else
    sudo "$nix_command" --extra-experimental-features "nix-command flakes" \
      run github:nix-darwin/nix-darwin#darwin-uninstaller </dev/null
  fi
}

uninstall_nix() {
  local recovery_dir
  recovery_dir="$(mktemp -d "$state_dir/uninstaller.XXXXXX")"
  cp "$nix_installer" "$recovery_dir/nix-installer"
  cp /nix/receipt.json "$recovery_dir/receipt.json"
  printf 'Uninstaller and receipt saved at: %s\n' "$recovery_dir"
  sudo "$recovery_dir/nix-installer" uninstall --no-confirm "$recovery_dir/receipt.json"
}

remove_nix() {
  if "$darwin_present"; then
    printf '%s\n' "Uninstalling nix-darwin before Nix/Lix."
    uninstall_darwin
    ! darwin_is_present || die "nix-darwin is still active; refusing to uninstall Nix."
  fi
  if "$nix_present"; then
    printf '%s\n' "Uninstalling Nix/Lix with its saved installer receipt."
    uninstall_nix
    ! nix_is_present || die "Nix/Lix still exists; cleanup is not complete."
    if [[ "$os" = Darwin ]] && nix_volume_is_present; then
      die "The Nix Store APFS volume still exists; complete its uninstall before rerunning."
    fi
  fi
}

backup_path() {
  local target="$1" destination="$backup_dir/${1#"$HOME/"}"
  [[ -e "$target" || -L "$target" ]] || return 0
  if [[ -e "$destination" || -L "$destination" ]]; then
    destination="$(mktemp -d "$backup_dir/recreated.XXXXXX")/${1#"$HOME/"}"
    printf 'Backing up a recreated path separately: %s\n' "$target"
  fi
  mkdir -p "$(dirname "$destination")"
  mv "$target" "$destination"
}

ensure_mise() {
  local candidate resolved
  mise_command=""
  if candidate="$(command -v mise)"; then
    resolved="$(resolve_executable "$candidate")"
    case "$resolved" in
      /nix/*) ;;
      *) mise_command="$candidate" ;;
    esac
  fi
  if [[ -z "$mise_command" ]]; then
    work_dir="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-migration.XXXXXX")"
    curl -fsSL https://mise.run -o "$work_dir/install-mise.sh"
    MISE_INSTALL_PATH="$work_dir/mise" sh "$work_dir/install-mise.sh"
    "$work_dir/mise" bootstrap --help >/dev/null
    backup_path "$HOME/.local/bin/mise"
    mkdir -p "$HOME/.local/bin"
    mv "$work_dir/mise" "$HOME/.local/bin/mise"
    mise_command="$HOME/.local/bin/mise"
  fi
  "$mise_command" bootstrap --help >/dev/null \
    || die "Upgrade mise first; this configuration requires mise bootstrap."
}

cleanup_temp() {
  if [[ -n "${work_dir:-}" ]]; then
    rm -f "$work_dir/install-mise.sh" "$work_dir/mise"
    rmdir "$work_dir"
  fi
}

bootstrap_current() {
  # 旧環境の削除済みパスや mise のセッション状態を引き継がないようにする
  unset NIX_PATH NIX_PROFILES NIX_SSL_CERT_FILE
  unset __MISE_DIFF __MISE_ORIG_PATH __MISE_SESSION
  export PATH="$safe_path"
  export XDG_CONFIG_HOME="$HOME/.config" XDG_DATA_HOME="$HOME/.local/share"
  export XDG_STATE_HOME="$HOME/.local/state" XDG_CACHE_HOME="$HOME/.cache"
  export MISE_CONFIG_DIR="$HOME/.config/mise"
  "$mise_command" -C "$repo_root" trust "$repo_root/mise.toml"
  run_bootstrap "$mise_command" "$repo_root" "$profile" "$ssh_mode" --yes
}

main() {
  local arg dry_run=false assume_yes=false answer target candidate resolved profile="" ssh_mode
  local script_path="${BASH_SOURCE[0]}"
  for arg in "$@"; do
    case "$arg" in
      --dry-run) dry_run=true ;;
      --yes) assume_yes=true ;;
      --help|-h)
        printf '%s\n' \
          "Usage: bash scripts/migrate.sh [--dry-run] [--yes]" \
          "Set DOTFILES_SSH=skip or DOTFILES_SSH=apply to choose without prompting."
        return
        ;;
      *) die "Unknown option: $arg" ;;
    esac
  done
  [[ "$(id -u)" != 0 ]] || die "Run as your login user, not root."
  os="$(uname -s)"
  case "$os:$(uname -m)" in
    Darwin:arm64|Linux:aarch64|Linux:arm64|Linux:x86_64) ;;
    *) die "Only Apple Silicon macOS and arm64/x86_64 Linux are supported." ;;
  esac
  HOME="$(cd "$HOME" && pwd -P)"
  export HOME
  repo_root="$(CDPATH= cd "$(dirname "$script_path")/.." && pwd -P)"
  source "$repo_root/scripts/bootstrap.sh"
  if [[ -n "${MISE_ENV:-}" ]]; then
    profile="$(profile_from_selection "$MISE_ENV")"
  fi
  config_home="${XDG_CONFIG_HOME:-"$HOME/.config"}"
  data_home="${XDG_DATA_HOME:-"$HOME/.local/share"}"
  state_home="${XDG_STATE_HOME:-"$HOME/.local/state"}"
  cache_home="${XDG_CACHE_HOME:-"$HOME/.cache"}"
  state_dir="$HOME/.local/state/dotfiles-migration"
  validate_path "$state_dir"
  [[ ! -L "$state_dir" ]] || die "Migration state must not be a symlink."
  backup_dir=""
  work_dir=""
  if [[ -f "$state_dir/backup-dir" ]]; then
    IFS= read -r backup_dir < "$state_dir/backup-dir"
    [[ "$backup_dir" = "$state_dir/backup."* && -d "$backup_dir" && ! -L "$backup_dir" ]] \
      || die "Invalid saved backup directory: $backup_dir"
  fi
  [[ ! -f "$state_dir/cleanup-complete" || -n "$backup_dir" ]] \
    || die "Migration state is missing its backup directory; restore backup-dir before resuming."
  ssh_mode="$(choose_ssh_mode "$@")"
  if [[ ! -f "$state_dir/cleanup-complete" ]]; then
    inspect_nix
    collect_backup_paths
    printf '%s\n' "Backups will be kept under: $state_dir"
    for target in "${backup_paths[@]:-}"; do
      [[ -n "$target" ]] || continue
      printf '  move %s\n' "$target"
    done
    if "$darwin_present"; then
      printf '%s\n' "  uninstall nix-darwin"
    fi
    if "$nix_present"; then
      printf '%s\n' "  uninstall Nix/Lix (system-wide, affecting ALL users)"
    fi
  else
    printf '%s\n' "Legacy cleanup already completed; only reapplying the new setup."
    nix_present=false
  fi
  printf '%s\n' "  ensure a mise executable outside /nix, then run mise bootstrap"
  "$dry_run" && return 0

  check_sudo_local
  if ! "$assume_yes"; then
    [[ -t 0 ]] || die "Use --yes for a non-interactive migration."
    printf '%s' "Type MIGRATE to continue: "
    IFS= read -r answer
    [[ "$answer" = MIGRATE ]] || die "Migration cancelled."
  fi
  profile="$(choose_profile "$profile")"

  safe_path="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
  for target in bash curl git; do
    candidate="$(PATH="$safe_path" command -v "$target")" \
      || die "Install $target with the system package manager before migrating."
    resolved="$(resolve_executable "$candidate")"
    [[ "$resolved" != /nix/* ]] || die "$target must be available outside /nix."
  done
  if [[ "$os" = Darwin ]]; then
    xcode-select --print-path >/dev/null \
      || die "Install Command Line Tools with xcode-select --install first."
  fi
  if "$nix_present" || [[ "$os" = Darwin ]]; then
    sudo -v
  fi
  umask 077
  mkdir -p "$state_dir"
  if [[ -z "$backup_dir" ]]; then
    backup_dir="$(mktemp -d "$state_dir/backup.XXXXXX")"
    printf '%s\n' "$backup_dir" > "$state_dir/backup-dir"
  fi
  trap 'status=$?; cleanup_temp; if (( status != 0 )); then printf "Migration failed. Backups: %s\nRerun this script to resume; no automatic rollback is performed.\n" "$backup_dir" >&2; fi' EXIT
  ensure_mise
  if [[ ! -f "$state_dir/cleanup-complete" ]]; then
    for target in "${backup_paths[@]:-}"; do
      [[ -n "$target" ]] || continue
      backup_path "$target"
    done
    remove_nix
    touch "$state_dir/cleanup-complete"
  fi
  bootstrap_current
  printf 'Migration complete. Backups: %s\nOpen a new login shell to use the new environment.\n' "$backup_dir"
}

if [[ "${BASH_SOURCE[0]}" = "$0" ]]; then
  main "$@"
fi
