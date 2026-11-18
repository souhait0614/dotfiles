#!/usr/bin/env bash
set -euo pipefail

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

find_nix() {
  local candidate
  for candidate in /nix/var/nix/profiles/default/bin/nix /run/current-system/sw/bin/nix; do
    if [[ -x "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return
    fi
  done
  return 1
}

homebrew_is_present() {
  [[ -x /opt/homebrew/bin/brew ]]
}

main() {
  local repo_root nix_command lix_version
  local script_path="${BASH_SOURCE[0]}"
  case "$(uname -s):$(uname -m)" in
    Linux:aarch64|Linux:arm64|Linux:x86_64)
      printf '%s\n' "Linux: nix-darwin setup is not applicable."
      return
      ;;
    Darwin:arm64) ;;
    *) die "nix-darwin setup supports Apple Silicon macOS only." ;;
  esac
  case "${DOTFILES_PROFILE:-}" in
    souhait|work_a|work_p) ;;
    *) die "Select a machine profile with bash scripts/bootstrap.sh first." ;;
  esac
  [[ "$(id -u)" != 0 ]] || die "Run mise bootstrap as your login user, not root."
  xcode-select --print-path >/dev/null \
    || die "Install Command Line Tools with xcode-select --install first."
  repo_root="$(CDPATH= cd "$(dirname "$script_path")/.." && pwd -P)"
  lix_version="${DOTFILES_LIX_VERSION:?Run this script through mise bootstrap or mise run bootstrap.}"
  installer_file="$(mktemp)"
  trap 'rm -f "$installer_file"' EXIT

  if ! nix_command="$(find_nix)"; then
    curl -fsSL https://install.lix.systems/lix -o "$installer_file"
    NIX_INSTALLER_NIX_PACKAGE_URL="https://releases.lix.systems/lix/lix-$lix_version/lix-$lix_version-aarch64-darwin.tar.xz" \
      sh "$installer_file" install --no-confirm
    nix_command="$(find_nix)" || die "The Lix installer did not provide a nix executable."
  fi
  if ! homebrew_is_present; then
    curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh -o "$installer_file"
    NONINTERACTIVE=1 /bin/bash "$installer_file"
    homebrew_is_present || die "The Homebrew installer did not provide brew."
  fi

  DOTFILES_USERNAME="$(id -un)"
  DOTFILES_HOME="$HOME"
  export DOTFILES_USERNAME DOTFILES_HOME
  sudo --preserve-env=DOTFILES_USERNAME,DOTFILES_HOME,DOTFILES_PROFILE,CI,NIX_CONFIG \
    "$nix_command" --extra-experimental-features "nix-command flakes" \
    run "path:$repo_root/nix-darwin#darwin-rebuild" --impure -- \
    switch --flake "path:$repo_root/nix-darwin#default" --impure
}

if [[ "${BASH_SOURCE[0]}" = "$0" ]]; then
  main "$@"
fi
