#!/usr/bin/env sh
set -eu

fail() {
  printf '%s\n' "pre-push check failed: $*" >&2
  exit 1
}

warn() {
  printf '%s\n' "warning: $*" >&2
}

info() {
  printf '%s\n' "$*"
}

repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || fail "not inside a git repository"
cd "$repo_root"

upstream=$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true)

if [ -n "$upstream" ]; then
  range="$upstream...HEAD"
  changed_files=$(git diff --name-only "$range")
else
  range="HEAD"
  changed_files=$(git diff-tree --no-commit-id --name-only -r HEAD 2>/dev/null || true)
  warn "no upstream branch configured; checking the latest commit only"
fi

tracked_files=$(git ls-files)
files_to_check=$(printf '%s\n%s\n' "$changed_files" "$tracked_files" | sed '/^$/d' | sort -u)

info "== Push safety check =="
if [ -n "$upstream" ]; then
  info "Comparing: $range"
fi

if [ -n "$changed_files" ]; then
  info ""
  info "Files in commits that are not on upstream yet:"
  printf '%s\n' "$changed_files" | sed 's/^/  - /'
else
  info ""
  info "No local commits ahead of upstream."
fi

bad_paths=$(printf '%s\n' "$files_to_check" |
  grep -E '(^|/)(\.env($|\.)|id_rsa$|id_ed25519$|\.?npmrc$)|\.(pem|key|p12|pfx|sqlite|sqlite3|db|log)$|(^|/)node_modules/|(^|/)__pycache__/' |
  grep -vE '(^|/)\.env\.example$' || true)
if [ -n "$bad_paths" ]; then
  printf '%s\n' "$bad_paths" | sed 's/^/blocked path: /' >&2
  fail "dangerous or local-only files are tracked or about to be pushed"
fi

large_files=$(
  printf '%s\n' "$files_to_check" |
    while IFS= read -r path; do
      [ -f "$path" ] || continue
      size=$(wc -c < "$path" | tr -d ' ')
      if [ "$size" -gt 1048576 ]; then
        printf '%s (%s bytes)\n' "$path" "$size"
      fi
    done
)
if [ -n "$large_files" ]; then
  printf '%s\n' "$large_files" | sed 's/^/large file: /' >&2
  fail "files larger than 1 MiB are tracked or about to be pushed"
fi

secret_hits=$(
  printf '%s\n' "$files_to_check" |
    while IFS= read -r path; do
      [ -f "$path" ] || continue
      case "$path" in
        *.png|*.jpg|*.jpeg|*.gif|*.ico|*.pdf|*.zip|*.gz|*.tar|*.tgz) continue ;;
      esac
      grep -nE '(AKIA[0-9A-Z]{16}|sk-[A-Za-z0-9_-]{20,}|ghp_[A-Za-z0-9_]{20,}|github_pat_[A-Za-z0-9_]{20,}|-----BEGIN (RSA |OPENSSH |EC |DSA )?PRIVATE KEY-----)' "$path" 2>/dev/null |
        sed "s#^#$path:#" || true
    done
)
if [ -n "$secret_hits" ]; then
  printf '%s\n' "$secret_hits" | sed 's/^/possible secret: /' >&2
  fail "possible secret material found"
fi

compose_changed=$(printf '%s\n' "$changed_files" | grep -E '(^|/)docker-compose\.ya?ml$' || true)
if [ -n "$compose_changed" ] && grep -nE '^[[:space:]]*-[[:space:]]*"[0-9]+:[0-9]+"' docker-compose.yml >/dev/null 2>&1; then
  warn "docker-compose.yml publishes ports on all host interfaces. Prefer 127.0.0.1:host:container for local-only services."
fi

info ""
info "Push safety check passed."
