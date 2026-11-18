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

profile_from_selection() {
  local selection="$1" profile="${1%%,*}"
  validate_profile "$profile"
  case "$selection" in
    "$profile"|"$profile,skip-ssh"|"$profile,apply-ssh") printf '%s\n' "$profile" ;;
    *) profile_error "Select one machine profile, optionally followed by skip-ssh or apply-ssh." ;;
  esac
}

is_wsl() {
  [[ "$(uname -s)" = Linux ]] || return 1
  [[ -n "${WSL_DISTRO_NAME:-}" || -n "${WSL_INTEROP:-}" ]] ||
    grep -Eiq 'microsoft|wsl' <<< "$(uname -r)"
}

choose_ssh_mode() {
  local mode="${DOTFILES_SSH:-}" non_interactive=false arg answer
  if [[ -z "$mode" ]] && is_wsl; then
    mode=skip
    for arg in "$@"; do
      case "$arg" in
        -n|--dry-run|-y|--yes|-h|--help) non_interactive=true ;;
      esac
    done
    if [[ -t 0 ]] && ! "$non_interactive"; then
      printf '%s' 'WSL detected. Skip managing ~/.ssh? (recommended if shared with Windows) [Y/n]: ' >&2
      IFS= read -r answer || profile_error "SSH selection cancelled."
      case "$answer" in
        ""|[Yy]|[Yy][Ee][Ss]) ;;
        [Nn]|[Nn][Oo]) mode=apply ;;
        *) profile_error "Answer yes or no." ;;
      esac
    fi
  fi
  case "$mode" in
    skip) printf '%s\n' 'Leaving ~/.ssh untouched.' >&2 ;;
    apply|"") ;;
    *) profile_error "DOTFILES_SSH must be skip or apply." ;;
  esac
  printf '%s\n' "$mode"
}

check_sudo_local() {
  if [[ "$(uname -s)" = Darwin && -e /etc/pam.d/sudo_local && ! -L /etc/pam.d/sudo_local ]]; then
    profile_error "Inspect /etc/pam.d/sudo_local and move it to /etc/pam.d/sudo_local.before-nix-darwin before continuing; do not overwrite an existing backup."
  fi
}

check_zsh() {
  if ! command -v zsh >/dev/null 2>&1; then
    printf '%s\n' "Warning: zsh is not installed. Install zsh and set it as your login shell." >&2
    return
  fi
  case "${SHELL:-}" in
    /nix/*|/run/current-system/*|"$HOME/.nix-profile/"*|"${XDG_STATE_HOME:-$HOME/.local/state}/nix/"*)
      printf '%s\n' "Warning: Recommend setting a non-Nix zsh as your login shell with chsh." >&2
      ;;
    */zsh)
      if [[ ! -x "$SHELL" ]]; then
        printf '%s\n' "Warning: Recommend setting zsh as your login shell with chsh." >&2
      fi
      ;;
    *)
      printf '%s\n' "Warning: Recommend setting zsh as your login shell with chsh." >&2
      ;;
  esac
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

run_bootstrap() {
  local mise_command="$1" repo_root="$2" profile="$3" ssh_mode="$4"
  shift 4
  # apply-ssh は設定を上書きせず、WSL で適用を選んだことだけを記録する
  MISE_TRUSTED_CONFIG_PATHS="$repo_root" \
    "$mise_command" -C "$repo_root" -E "$profile${ssh_mode:+,$ssh_mode-ssh}" bootstrap --save-env "$@"
}

bootstrap_main() {
  local repo_root mise_command selection ssh_mode profile=""
  local script_path="${BASH_SOURCE[0]}"
  case "${1:-}" in
    --check)
      selection="${2:-${MISE_ENV:-}}"
      profile="$(profile_from_selection "$selection")"
      if [[ "$selection" = "$profile" ]] && is_wsl; then
        profile_error "WSL: Run bash scripts/bootstrap.sh $profile to choose whether to manage ~/.ssh."
      fi
      check_sudo_local
      check_zsh
      return
      ;;
    --help|-h)
      printf '%s\n' \
        "Usage: bash scripts/bootstrap.sh [souhait|work_a|work_p] [mise bootstrap options...]" \
        "Set DOTFILES_SSH=skip or DOTFILES_SSH=apply to choose without prompting."
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
  ssh_mode="$(choose_ssh_mode "$@")"
  run_bootstrap "$mise_command" "$repo_root" "$profile" "$ssh_mode" "$@"
}

if [[ "${BASH_SOURCE[0]}" = "$0" ]]; then
  bootstrap_main "$@"
fi
