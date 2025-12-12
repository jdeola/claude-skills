#!/bin/bash
#
# sync-skills.sh - Sync Claude Skills to user and project locations
#
# Usage: ./sync-skills.sh [--dry-run] [--verbose] [--projects-only] [--user-only]
#
# Triggers: pre-push hook, manual execution
#

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_ROOT="$(dirname "$SCRIPT_DIR")"

# Use local config if it exists, otherwise use default
if [[ -f "$SCRIPT_DIR/sync-config.local.json" ]]; then
    CONFIG_FILE="$SCRIPT_DIR/sync-config.local.json"
else
    CONFIG_FILE="$SCRIPT_DIR/sync-config.json"
fi

LOG_FILE="$SKILLS_ROOT/.sync-log"

# User-level targets
USER_CLAUDE_DIR="$HOME/.claude"
USER_COMMANDS_DIR="$USER_CLAUDE_DIR/commands/jd"
USER_HOOKS_DIR="$USER_CLAUDE_DIR/hooks/skills"
USER_SCRIPTS_DIR="$USER_CLAUDE_DIR/scripts/skills"

# Flags
DRY_RUN=false
VERBOSE=false
PROJECTS_ONLY=false
USER_ONLY=false

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ============================================================================
# Helpers
# ============================================================================

log() {
    local level="$1"
    shift
    local msg="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        INFO)  echo -e "${BLUE}[INFO]${NC} $msg" ;;
        OK)    echo -e "${GREEN}[✓]${NC} $msg" ;;
        WARN)  echo -e "${YELLOW}[WARN]${NC} $msg" ;;
        ERROR) echo -e "${RED}[ERROR]${NC} $msg" ;;
        DRY)   echo -e "${YELLOW}[DRY-RUN]${NC} $msg" ;;
        SYNC)  echo -e "${CYAN}[SYNC]${NC} $msg" ;;
    esac
    
    echo "[$timestamp] [$level] $msg" >> "$LOG_FILE"
}

verbose() {
    if $VERBOSE; then
        log INFO "$@"
    fi
}

ensure_dir() {
    local dir="$1"
    if $DRY_RUN; then
        log DRY "Would create directory: $dir"
    else
        mkdir -p "$dir"
        verbose "Ensured directory: $dir"
    fi
}

sync_file() {
    local src="$1"
    local dest="$2"
    local mode="${3:-copy}"  # copy or symlink
    
    if [[ ! -f "$src" ]]; then
        log WARN "Source not found: $src"
        return 1
    fi
    
    if $DRY_RUN; then
        if [[ "$mode" == "symlink" ]]; then
            log DRY "Would symlink: $dest -> $src"
        else
            log DRY "Would copy: $src -> $dest"
        fi
        return 0
    fi
    
    ensure_dir "$(dirname "$dest")"
    
    if [[ "$mode" == "symlink" ]]; then
        rm -f "$dest" 2>/dev/null || true
        ln -s "$src" "$dest"
        verbose "Symlinked: $dest -> $src"
    else
        cp "$src" "$dest"
        verbose "Copied: $src -> $dest"
    fi
}

# ============================================================================
# Sync Functions
# ============================================================================

sync_user_commands() {
    log INFO "Syncing commands to user scope..."
    ensure_dir "$USER_COMMANDS_DIR"
    
    local count=0
    
    # Command mappings: source|destination
    # Using symlinks so changes are always live
    local COMMANDS="
context-engineering/commands/start.md|start.md
context-engineering/commands/done.md|done.md
context-engineering/commands/impact-map.md|impact-map.md
context-engineering/commands/context-hygiene.md|context-hygiene.md
data-mutation-consistency/commands/analyze-mutations.md|mutation-analyze.md
data-mutation-consistency/commands/check-mutation.md|mutation-check.md
data-mutation-consistency/commands/fix-mutations.md|mutation-fix.md
skill-refinement/commands/refine-skills.md|refine-skills.md
skill-refinement/commands/apply-generalization.md|apply-generalization.md
skill-refinement/commands/review-patterns.md|review-patterns.md
"
    
    echo "$COMMANDS" | while IFS='|' read -r src_rel dest_name; do
        # Skip empty lines
        [[ -z "$src_rel" ]] && continue
        
        local src="$SKILLS_ROOT/$src_rel"
        local dest="$USER_COMMANDS_DIR/$dest_name"
        
        if sync_file "$src" "$dest" "symlink"; then
            count=$((count + 1))
        fi
    done
    
    log OK "Synced commands to ~/.claude/commands/jd/"
}

sync_user_hooks() {
    log INFO "Syncing hooks to user scope..."
    ensure_dir "$USER_HOOKS_DIR"
    
    local count=0
    
    # Find all .sh files in hooks/ directories
    while IFS= read -r -d '' hook; do
        local rel_path="${hook#$SKILLS_ROOT/}"
        local skill_name=$(echo "$rel_path" | cut -d'/' -f1)
        local hook_name=$(basename "$hook")
        local dest="$USER_HOOKS_DIR/${skill_name}--${hook_name}"
        
        if sync_file "$hook" "$dest" "symlink"; then
            ((count++))
        fi
    done < <(find "$SKILLS_ROOT" -path "*hooks/*.sh" -type f -print0 2>/dev/null)
    
    log OK "Synced $count hooks to ~/.claude/hooks/skills/"
}

sync_user_scripts() {
    log INFO "Syncing Python scripts to user scope..."
    ensure_dir "$USER_SCRIPTS_DIR"
    
    local count=0
    
    # Sync each skill's scripts directory
    for skill_dir in "$SKILLS_ROOT"/*/; do
        local skill_name=$(basename "$skill_dir")
        local scripts_dir="$skill_dir/scripts"
        
        if [[ -d "$scripts_dir" ]]; then
            local dest_dir="$USER_SCRIPTS_DIR/$skill_name"
            ensure_dir "$dest_dir"
            
            # Copy Python files (not symlink - they may need __pycache__)
            while IFS= read -r -d '' script; do
                local script_name=$(basename "$script")
                if sync_file "$script" "$dest_dir/$script_name" "copy"; then
                    ((count++))
                fi
            done < <(find "$scripts_dir" -name "*.py" -type f -print0 2>/dev/null)
        fi
    done
    
    log OK "Synced $count scripts to ~/.claude/scripts/skills/"
}

sync_projects() {
    log INFO "Syncing to registered projects..."
    
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log WARN "No sync-config.json found. Skipping project sync."
        return 0
    fi
    
    # Read project paths from config
    local projects
    projects=$(python3 -c "
import json
import sys
try:
    with open('$CONFIG_FILE') as f:
        config = json.load(f)
    for p in config.get('projects', []):
        if p.get('enabled', True):
            print(p['path'])
except Exception as e:
    print(f'Error: {e}', file=sys.stderr)
    sys.exit(1)
" 2>/dev/null) || {
        log WARN "Could not parse sync-config.json"
        return 1
    }
    
    if [[ -z "$projects" ]]; then
        log INFO "No projects registered for sync"
        return 0
    fi
    
    local project_count=0
    while IFS= read -r project_path; do
        # Expand ~ if present
        project_path="${project_path/#\~/$HOME}"
        
        if [[ ! -d "$project_path" ]]; then
            log WARN "Project not found: $project_path"
            continue
        fi
        
        log SYNC "Syncing to: $project_path"
        sync_to_project "$project_path"
        ((project_count++))
    done <<< "$projects"
    
    log OK "Synced to $project_count projects"
}

sync_to_project() {
    local project_path="$1"
    local project_name=$(basename "$project_path")
    local project_claude="$project_path/.claude"
    local project_commands="$project_claude/commands/$project_name"
    
    ensure_dir "$project_commands"
    
    # Get project-specific config
    local namespace="$project_name"
    if [[ -f "$CONFIG_FILE" ]]; then
        namespace=$(python3 -c "
import json
with open('$CONFIG_FILE') as f:
    config = json.load(f)
for p in config.get('projects', []):
    if p['path'].replace('~', '$HOME') == '$project_path' or p['path'] == '$project_path':
        print(p.get('namespace', '$project_name'))
        break
else:
    print('$project_name')
" 2>/dev/null) || namespace="$project_name"
    fi
    
    project_commands="$project_claude/commands/$namespace"
    ensure_dir "$project_commands"
    
    local count=0
    
    # Copy all commands (not symlink - projects may need offline access)
    for skill_dir in "$SKILLS_ROOT"/*/; do
        local commands_dir="$skill_dir/commands"
        if [[ -d "$commands_dir" ]]; then
            for cmd in "$commands_dir"/*.md; do
                [[ -f "$cmd" ]] || continue
                local cmd_name=$(basename "$cmd")
                if sync_file "$cmd" "$project_commands/$cmd_name" "copy"; then
                    ((count++))
                fi
            done
        fi
    done
    
    verbose "Synced $count commands to $project_commands"
}

generate_help_file() {
    log INFO "Generating help.md..."
    
    local help_file="$USER_COMMANDS_DIR/help.md"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    if $DRY_RUN; then
        log DRY "Would generate: $help_file"
        return 0
    fi
    
    cat > "$help_file" << 'HELPEOF'
---
name: help
description: "List all available /jd commands and their functionality"
category: utility
complexity: low
mcp-servers: []
---

# /jd:help - Custom Skills Command Reference

## Overview

The `/jd:` namespace contains commands from your custom Claude Skills library.
These complement the SuperClaude `/sc:` commands with project-specific workflows.

---

## Available Commands

### Session Management (context-engineering)

| Command | Description |
|---------|-------------|
| `/jd:start` | Initialize development session with full context loading |
| `/jd:done` | Post-implementation validation, commit prep, and context extraction |
| `/jd:impact-map` | Map dependencies before implementing features or changes |
| `/jd:context-hygiene` | Manage context window during long sessions |

### Data Mutation Consistency (data-mutation-consistency)

| Command | Description |
|---------|-------------|
| `/jd:mutation-analyze` | Full codebase mutation analysis with scoring |
| `/jd:mutation-check` | Single file mutation pattern check |
| `/jd:mutation-fix` | Generate fix plan for mutation issues |

### Skill Refinement (skill-refinement)

| Command | Description |
|---------|-------------|
| `/jd:refine-skills` | Capture and apply skill refinements |
| `/jd:apply-generalization` | Apply queued generalizations to user-scope skills |
| `/jd:review-patterns` | Review tracked refinement patterns |

---

## Related Resources

- **Skills Library:** `~/dev-local/CLAUDE-SKILLS/`
- **SuperClaude Commands:** `/sc:help`
- **Skill Documentation:** See each skill's `SKILL.md` for detailed usage
HELPEOF

    log OK "Generated help.md"
}

# ============================================================================
# Main
# ============================================================================

show_help() {
    cat << EOF
Claude Skills Sync Script

USAGE:
    ./sync-skills.sh [OPTIONS]

OPTIONS:
    --dry-run       Show what would be done without making changes
    --verbose       Show detailed output
    --projects-only Only sync to registered projects
    --user-only     Only sync to user-level ~/.claude/
    --help          Show this help message

CONFIGURATION:
    Edit scripts/sync-config.json to register projects for sync.

EXAMPLES:
    ./sync-skills.sh                    # Full sync
    ./sync-skills.sh --dry-run          # Preview changes
    ./sync-skills.sh --user-only        # Only user scope

EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --projects-only)
                PROJECTS_ONLY=true
                shift
                ;;
            --user-only)
                USER_ONLY=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                log ERROR "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

main() {
    local start_time=$(date +%s)
    
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "  Claude Skills Sync"
    echo "═══════════════════════════════════════════════════════════"
    echo ""
    
    if $DRY_RUN; then
        log WARN "DRY RUN MODE - No changes will be made"
        echo ""
    fi
    
    # User-level sync
    if ! $PROJECTS_ONLY; then
        sync_user_commands
        sync_user_hooks
        # sync_user_scripts  # Uncomment if you want script copying
        generate_help_file
    fi
    
    # Project-level sync
    if ! $USER_ONLY; then
        sync_projects
    fi
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    log OK "Sync completed in ${duration}s"
    echo "═══════════════════════════════════════════════════════════"
    echo ""
}

# Run
parse_args "$@"
main
