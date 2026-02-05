#!/bin/bash
# ============================================================
# UEFN Sync — Linux (source) → Windows (UEFN)
# Copie les fichiers .verse vers les projets UEFN Windows
# ============================================================

set -euo pipefail

# === Configuration ===
LINUX_BASE="$HOME/projects/perso/uefn"
UEFN_WIN_BASE="/mnt/c/Users/WsiAccount/UEFN-Projects"

# Mapping: sub-projet Linux → dossier UEFN Windows
# Format: ["linux-name"]="WindowsProjectName"
declare -A PROJECT_MAP=(
    # ["battle-arena"]="BattleArena"
    # ["zombie-horde"]="ZombieHorde"
    # Ajouter les mappings ici quand on crée des sub-projets
)

# === Colors ===
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# === Functions ===
log()         { echo -e "${CYAN}[sync]${NC} $1"; }
log_success() { echo -e "${GREEN}[sync] ✅ $1${NC}"; }
log_warn()    { echo -e "${YELLOW}[sync] ⚠️  $1${NC}"; }
log_error()   { echo -e "${RED}[sync] ❌ $1${NC}" >&2; }

show_usage() {
    cat << 'EOF'
Usage: sync.sh [OPTIONS] [sub-projet]

Sync Verse code from Linux to Windows UEFN project.

Arguments:
  sub-projet          Name of the sub-project to sync

Options:
  --all               Sync all sub-projects
  --dry-run           Preview what would be copied
  --reverse           Sync Windows → Linux (pull from UEFN)
  --list              List available sub-projects
  -h, --help          Show this help

Examples:
  ./sync.sh battle-arena          # Sync one sub-project
  ./sync.sh --all                 # Sync everything
  ./sync.sh --dry-run battle-arena  # Preview sync
  ./sync.sh --reverse battle-arena  # Pull from Windows
EOF
}

check_windows_access() {
    if [[ ! -d "/mnt/c" ]]; then
        log_error "Windows filesystem not accessible (/mnt/c not found)"
        exit 1
    fi
}

ensure_win_dir() {
    local win_dir="$1"
    if [[ ! -d "$win_dir" ]]; then
        log_warn "Windows directory not found: $win_dir"
        read -rp "Create it? [y/N] " confirm
        if [[ "$confirm" =~ ^[yY]$ ]]; then
            mkdir -p "$win_dir"
            log_success "Created $win_dir"
        else
            log_error "Aborted"
            exit 1
        fi
    fi
}

sync_project() {
    local sub="$1"
    local dry_run="${2:-false}"
    local reverse="${3:-false}"
    local win_name="${PROJECT_MAP[$sub]:-}"

    if [[ -z "$win_name" ]]; then
        log_error "Sub-project '$sub' not found in PROJECT_MAP"
        log "Available: ${!PROJECT_MAP[*]:-none}"
        log "Add mapping in sync.sh: [\"$sub\"]=\"WindowsName\""
        return 1
    fi

    local linux_dir="$LINUX_BASE/$sub/verse"
    local win_dir="$UEFN_WIN_BASE/$win_name/Verse"

    if [[ "$reverse" == "true" ]]; then
        # Windows → Linux (pull)
        local src="$win_dir"
        local dst="$linux_dir"
        local direction="Windows → Linux"
    else
        # Linux → Windows (push)
        local src="$linux_dir"
        local dst="$win_dir"
        local direction="Linux → Windows"
    fi

    if [[ ! -d "$src" ]]; then
        log_error "Source directory not found: $src"
        return 1
    fi

    log "Syncing [$sub] ($direction)"
    log "  From: $src"
    log "  To:   $dst"

    # Count files
    local count
    count=$(find "$src" -name "*.verse" 2>/dev/null | wc -l)
    log "  Files: $count .verse file(s)"

    if [[ "$dry_run" == "true" ]]; then
        log_warn "DRY RUN — no files copied"
        find "$src" -name "*.verse" -exec echo "  → {}" \;
        return 0
    fi

    ensure_win_dir "$dst"
    rsync -av --include="*.verse" --include="*/" --exclude="*" "$src/" "$dst/"
    log_success "Synced $count file(s) for [$sub]"
}

list_projects() {
    log "Available sub-projects:"
    if [[ ${#PROJECT_MAP[@]} -eq 0 ]]; then
        log_warn "No sub-projects configured yet"
        log "Add mappings to PROJECT_MAP in sync.sh"
        return
    fi
    for key in "${!PROJECT_MAP[@]}"; do
        local linux_dir="$LINUX_BASE/$key/verse"
        local count=0
        if [[ -d "$linux_dir" ]]; then
            count=$(find "$linux_dir" -name "*.verse" 2>/dev/null | wc -l)
        fi
        echo -e "  ${CYAN}$key${NC} → ${PROJECT_MAP[$key]} ($count .verse files)"
    done
}

# === Main ===
main() {
    local dry_run=false
    local reverse=false
    local sync_all=false
    local target=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --all)      sync_all=true; shift ;;
            --dry-run)  dry_run=true; shift ;;
            --reverse)  reverse=true; shift ;;
            --list)     list_projects; exit 0 ;;
            -h|--help)  show_usage; exit 0 ;;
            -*)         log_error "Unknown option: $1"; show_usage; exit 1 ;;
            *)          target="$1"; shift ;;
        esac
    done

    check_windows_access

    if [[ "$sync_all" == "true" ]]; then
        if [[ ${#PROJECT_MAP[@]} -eq 0 ]]; then
            log_warn "No sub-projects configured"
            exit 0
        fi
        for key in "${!PROJECT_MAP[@]}"; do
            sync_project "$key" "$dry_run" "$reverse"
            echo ""
        done
        log_success "All projects synced"
    elif [[ -n "$target" ]]; then
        sync_project "$target" "$dry_run" "$reverse"
    else
        log_error "No target specified. Use --all or provide a sub-project name."
        echo ""
        list_projects
        exit 1
    fi
}

main "$@"
