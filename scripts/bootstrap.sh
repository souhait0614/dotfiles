#!/usr/bin/env bash
set -euo pipefail

profile_error() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

validate_profile() {
  case "$1" in
    souhait|work_a|work_p) ;;
    *) profile_error "Select exactly one profile: souhait, work_a, or work_p. Run bash scripts/bootstrap.sh." ;;
  esac
}

check_sudo_local() {
  if [[ "$(uname -s)" = Darwin && -e /etc/pam.d/sudo_local && ! -L /etc/pam.d/sudo_local ]]; then
    profile_error "Inspect /etc/pam.d/sudo_local and move it to /etc/pam.d/sudo_local.before-nix-darwin before continuing; do not overwrite an existing backup."
  fi
}

choose_profile() {
  local profile="${1:-}" choice
  if [[ -z "$profile" ]]; then
    [[ -t 0 ]] || profile_error "A profile is required without a terminal: souhait, work_a, or work_p."
    printf '%s\n' "1) souhait" "2) work_a" "3) work_p" >&2
    printf '%s' "Profile: " >&2
    IFS= read -r choice || profile_error "Profile selection cancelled."
    case "$choice" in
      1) profile=souhait ;;
      2) profile=work_a ;;
      3) profile=work_p ;;
      *) profile="$choice" ;;
    esac
  fi
  validate_profile "$profile"
  printf '%s\n' "$profile"
}

bootstrap_main() {
  local repo_root mise_command profile=""
  local script_path="${BASH_SOURCE[0]}"
  case "${1:-}" in
    --check)
      validate_profile "${2:-${MISE_ENV:-}}"
      check_sudo_local
      return
      ;;
    --help|-h)
      printf '%s\n' "Usage: bash scripts/bootstrap.sh [souhait|work_a|work_p] [mise bootstrap options...]"
      return
      ;;
    souhait|work_a|work_p)
      profile="$1"
      shift
      ;;
    ""|-*) ;;
    *) profile_error "Unknown profile: $1" ;;
  esac
  profile="$(choose_profile "$profile")"
  repo_root="$(CDPATH= cd "$(dirname "$script_path")/.." && pwd -P)"
  mise_command="${DOTFILES_MISE_BIN:-mise}"
  command -v "$mise_command" >/dev/null \
    || profile_error "Install a recent mise before bootstrapping."
  MISE_TRUSTED_CONFIG_PATHS="$repo_root" \
    "$mise_command" -C "$repo_root" -E "$profile" bootstrap --save-env "$@"
}

if [[ "${BASH_SOURCE[0]}" = "$0" ]]; then
  bootstrap_main "$@"
fi
