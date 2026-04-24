#!/usr/bin/env bash
set -euo pipefail

# Sync repository entries into Claude global directories via symlinks.
# Precedence for config dir:
# 1) CLAUDE_CONFIG_DIR (if set)
# 2) $HOME/.claude

print_usage() {
  cat <<'EOF'
Usage: setup-claude-links.sh [--dry-run|-n] [--help|-h]

Options:
  --dry-run, -n  Show planned changes without modifying the filesystem
  --help, -h     Show this help message
EOF
}

DRY_RUN=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run|-n)
      DRY_RUN=1
      ;;
    --help|-h)
      print_usage
      exit 0
      ;;
    *)
      echo "[error] unknown argument: $1" >&2
      print_usage >&2
      exit 2
      ;;
  esac
  shift
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

if [[ -n "${CLAUDE_CONFIG_DIR:-}" ]]; then
  CLAUDE_DIR="${CLAUDE_CONFIG_DIR}"
else
  CLAUDE_DIR="${HOME}/.claude"
fi

CREATED=0
REPLACED=0
FAILED=0

is_git_bash() {
  case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*) return 0 ;;
    *) return 1 ;;
  esac
}

create_symlink_windows_fallback() {
  local src="$1"
  local dest="$2"

  if ! command -v cygpath >/dev/null 2>&1; then
    return 1
  fi

  local src_win
  local dest_win
  src_win="$(cygpath -w "$src")"
  dest_win="$(cygpath -w "$dest")"

  if [[ -d "$src" ]]; then
    cmd.exe //c "mklink /D \"${dest_win}\" \"${src_win}\"" >/dev/null 2>&1
  else
    cmd.exe //c "mklink \"${dest_win}\" \"${src_win}\"" >/dev/null 2>&1
  fi
}

create_symlink() {
  local src="$1"
  local dest="$2"

  if ln -s "$src" "$dest" >/dev/null 2>&1; then
    return 0
  fi

  if is_git_bash && create_symlink_windows_fallback "$src" "$dest"; then
    return 0
  fi

  return 1
}

sync_group() {
  local group="$1"
  local src_dir="${REPO_ROOT}/${group}"
  local dst_dir="${CLAUDE_DIR}/${group}"

  if [[ ! -d "$src_dir" ]]; then
    echo "[warn] source directory not found, skipping: ${src_dir}" >&2
    return 0
  fi

  if [[ "$DRY_RUN" -eq 0 ]]; then
    mkdir -p "$dst_dir"
  elif [[ ! -d "$dst_dir" ]]; then
    echo "[dry-run] would create directory: ${dst_dir}" >&2
  fi

  # Iterate direct children only to merge into an existing global structure.
  while IFS= read -r -d '' src_item; do
    local item_name
    local dest_item
    local had_existing=0
    local item_kind="file"
    local item_note=""

    item_name="$(basename "$src_item")"
    dest_item="${dst_dir}/${item_name}"

    if [[ -d "$src_item" ]]; then
      item_kind="directory"
      if [[ -f "$src_item/SKILL.md" ]]; then
        item_note=" (includes SKILL.md and nested files)"
      else
        item_note=" (includes nested files)"
      fi
    fi

    if [[ -e "$dest_item" || -L "$dest_item" ]]; then
      had_existing=1
      if [[ "$DRY_RUN" -eq 0 ]]; then
        rm -rf "$dest_item"
      fi
    fi

    if [[ "$DRY_RUN" -eq 1 ]]; then
      if [[ "$had_existing" -eq 1 ]]; then
        REPLACED=$((REPLACED + 1))
        echo "[dry-run] would replace ${group}/${item_name} [${item_kind} symlink]${item_note}" >&2
      else
        CREATED=$((CREATED + 1))
        echo "[dry-run] would create ${group}/${item_name} [${item_kind} symlink]${item_note}" >&2
      fi
      continue
    fi

    if create_symlink "$src_item" "$dest_item"; then
      if [[ "$had_existing" -eq 1 ]]; then
        REPLACED=$((REPLACED + 1))
        echo "[replaced] ${group}/${item_name} [${item_kind} symlink]${item_note}" >&2
      else
        CREATED=$((CREATED + 1))
        echo "[created] ${group}/${item_name} [${item_kind} symlink]${item_note}" >&2
      fi
    else
      FAILED=$((FAILED + 1))
      echo "[failed] ${group}/${item_name} -> could not create symbolic link" >&2
      if is_git_bash; then
        echo "         hint: enable Windows Developer Mode or run terminal as Administrator" >&2
      fi
    fi
  done < <(find "$src_dir" -mindepth 1 -maxdepth 1 -print0)
}

echo "Using Claude config directory: ${CLAUDE_DIR}" >&2
if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "Running in dry-run mode (no filesystem changes)" >&2
fi

sync_group "agents"
sync_group "commands"
sync_group "skills"
sync_group "hooks"

if [[ "$DRY_RUN" -eq 1 ]]; then
  STATUS="dry-run"
  EXIT_CODE=0
elif [[ "$FAILED" -gt 0 ]]; then
  STATUS="partial"
  EXIT_CODE=1
else
  STATUS="ok"
  EXIT_CODE=0
fi

if [[ "$DRY_RUN" -eq 1 ]]; then
  DRY_RUN_BOOL="true"
else
  DRY_RUN_BOOL="false"
fi

printf '{"status":"%s","dry_run":%s,"created":%d,"replaced":%d,"failed":%d,"claude_dir":"%s"}\n' \
  "$STATUS" "$DRY_RUN_BOOL" "$CREATED" "$REPLACED" "$FAILED" "$CLAUDE_DIR"

exit "$EXIT_CODE"
