#!/usr/bin/env bash
# Helper functions for multi-repository git coordination in spec-kit

MULTIREPO_CONFIG_NAME=".specify/multirepo.json"

is_multirepo_enabled() {
    local repo_root="${1:-$(pwd)}"
    local config_file="$repo_root/$MULTIREPO_CONFIG_NAME"
    if [ ! -f "$config_file" ]; then
        return 1
    fi

    local enabled
    enabled=$(python3 -c "
import json, sys
try:
    with open('$config_file') as f:
        data = json.load(f)
    print(str(data.get('enabled', False)).lower())
except Exception:
    print('false')
" 2>/dev/null)

    [ "$enabled" = "true" ]
}

# Resolve and return all valid repository directories configured in multirepo.json
get_multirepo_dirs() {
    local repo_root="${1:-$(pwd)}"
    local config_file="$repo_root/$MULTIREPO_CONFIG_NAME"

    if [ ! -f "$config_file" ]; then
        echo "$repo_root"
        return 0
    fi

    python3 -c "
import json, os, sys

config_file = '$config_file'
repo_root = '$repo_root'

try:
    with open(config_file) as f:
        data = json.load(f)
    repos = data.get('repositories', [])
    resolved = []
    # Always include current repo_root
    canonical_root = os.path.realpath(repo_root)
    resolved.append(canonical_root)

    for r in repos:
        p = os.path.realpath(os.path.join(repo_root, r))
        if os.path.isdir(p) and os.path.exists(os.path.join(p, '.git')):
            if p not in resolved:
                resolved.append(p)
    for p in resolved:
        print(p)
except Exception as e:
    print(repo_root)
" 2>/dev/null
}

get_multirepo_base_branch() {
    local repo_root="${1:-$(pwd)}"
    local config_file="$repo_root/$MULTIREPO_CONFIG_NAME"
    if [ -f "$config_file" ]; then
        python3 -c "
import json
try:
    with open('$config_file') as f:
        data = json.load(f)
    print(data.get('base_branch', 'main'))
except Exception:
    print('main')
" 2>/dev/null
    else
        echo "main"
    fi
}

get_multirepo_abort_on_dirty() {
    local repo_root="${1:-$(pwd)}"
    local config_file="$repo_root/$MULTIREPO_CONFIG_NAME"
    if [ -f "$config_file" ]; then
        python3 -c "
import json
try:
    with open('$config_file') as f:
        data = json.load(f)
    print(str(data.get('abort_on_dirty', True)).lower())
except Exception:
    print('true')
" 2>/dev/null
    else
        echo "true"
    fi
}

# Extract highest sequential feature number across all configured repositories
get_multirepo_highest_number() {
    local repo_root="${1:-$(pwd)}"
    local skip_fetch="${2:-false}"
    local global_highest=0

    while IFS= read -r repo_dir; do
        [ -d "$repo_dir" ] || continue

        if [ "$skip_fetch" != "true" ]; then
            git -C "$repo_dir" fetch --all --prune >/dev/null 2>&1 || true
        fi

        # 1. Inspect git branches
        local branches
        branches=$(git -C "$repo_dir" branch -a 2>/dev/null || echo "")
        if [ -n "$branches" ]; then
            while IFS= read -r branch; do
                local clean_branch
                clean_branch=$(echo "$branch" | sed 's/^[* ]*//; s|^remotes/[^/]*/||')
                if echo "$clean_branch" | grep -Eq '^[0-9]{3,}-' && ! echo "$clean_branch" | grep -Eq '^[0-9]{8}-[0-9]{6}-'; then
                    local num
                    num=$(echo "$clean_branch" | grep -Eo '^[0-9]+' || echo "0")
                    num=$((10#$num))
                    if [ "$num" -gt "$global_highest" ]; then
                        global_highest=$num
                    fi
                fi
            done <<< "$branches"
        fi

        # 2. Inspect specs directory
        local specs_dir="$repo_dir/specs"
        if [ -d "$specs_dir" ]; then
            for dir in "$specs_dir"/*; do
                [ -d "$dir" ] || continue
                local dirname
                dirname=$(basename "$dir")
                if echo "$dirname" | grep -Eq '^[0-9]{3,}-' && ! echo "$dirname" | grep -Eq '^[0-9]{8}-[0-9]{6}-'; then
                    local num
                    num=$(echo "$dirname" | grep -Eo '^[0-9]+' || echo "0")
                    num=$((10#$num))
                    if [ "$num" -gt "$global_highest" ]; then
                        global_highest=$num
                    fi
                fi
            done
        fi
    done < <(get_multirepo_dirs "$repo_root")

    echo "$global_highest"
}

# Pre-flight checks across all repositories
# Returns 0 if all clean and ready, 1 on failure
check_multirepo_preflight() {
    local repo_root="$1"
    local branch_name="$2"
    local is_dry_run="${3:-false}"
    local allow_dirty="${4:-false}"
    local abort_on_dirty
    abort_on_dirty=$(get_multirepo_abort_on_dirty "$repo_root")
    if [ "$allow_dirty" = "true" ]; then
        abort_on_dirty="false"
    fi

    local has_errors=false

    while IFS= read -r repo_dir; do
        [ -d "$repo_dir" ] || continue
        local repo_name
        repo_name=$(basename "$repo_dir")

        # 1. Verify git worktree
        if ! git -C "$repo_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
            >&2 echo "Error: '$repo_name' ($repo_dir) is not a valid Git repository."
            has_errors=true
            continue
        fi

        # 2. Check for dirty working tree if abort_on_dirty is true
        local dirty_status
        dirty_status=$(git -C "$repo_dir" status --porcelain --untracked-files=no 2>/dev/null || echo "")
        if [ -n "$dirty_status" ]; then
            if [ "$abort_on_dirty" = "true" ] && [ "$is_dry_run" != "true" ]; then
                >&2 echo "Error: Repository '$repo_name' has uncommitted changes to tracked files:"
                >&2 echo "$dirty_status"
                >&2 echo "Aborting multi-repository branch creation to prevent inconsistent state."
                >&2 echo "Please commit or stash changes in '$repo_name' before running speckit-specify."
                has_errors=true
            else
                >&2 echo "[warning] Repository '$repo_name' has uncommitted changes to tracked files:"
                >&2 echo "$dirty_status"
            fi
        fi

        # 3. Check if target branch already exists in this repo
        if git -C "$repo_dir" branch --list "$branch_name" | grep -q .; then
            if [ "$is_dry_run" = "true" ]; then
                >&2 echo "[dry-run] Warning: Branch '$branch_name' already exists in repository '$repo_name'."
            else
                >&2 echo "Error: Branch '$branch_name' already exists in repository '$repo_name'."
                has_errors=true
            fi
        fi
    done < <(get_multirepo_dirs "$repo_root")

    if [ "$has_errors" = "true" ]; then
        return 1
    fi
    return 0
}

# Checkout/create branch across all configured repositories
create_multirepo_branches() {
    local repo_root="$1"
    local branch_name="$2"
    local base_branch
    base_branch=$(get_multirepo_base_branch "$repo_root")

    local created_repos=()
    local failed=false

    while IFS= read -r repo_dir; do
        [ -d "$repo_dir" ] || continue
        local repo_name
        repo_name=$(basename "$repo_dir")

        # Determine base reference to branch from
        local start_ref="$base_branch"
        if ! git -C "$repo_dir" show-ref --verify --quiet "refs/heads/$base_branch" 2>/dev/null; then
            if git -C "$repo_dir" show-ref --verify --quiet "refs/heads/master" 2>/dev/null; then
                start_ref="master"
            else
                start_ref="$(git -C "$repo_dir" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "HEAD")"
            fi
        fi

        local create_err
        if ! create_err=$(git -C "$repo_dir" checkout -b "$branch_name" "$start_ref" 2>&1); then
            >&2 echo "Error: Failed to create branch '$branch_name' in '$repo_name' from '$start_ref'."
            if [ -n "$create_err" ]; then
                >&2 echo "$create_err"
            fi
            failed=true
            break
        else
            created_repos+=("$repo_name")
        fi
    done < <(get_multirepo_dirs "$repo_root")

    if [ "$failed" = "true" ]; then
        >&2 echo "Warning: Multi-repository branch creation partially failed."
        return 1
    fi

    return 0
}

# Print or build JSON summary of all repos
get_multirepo_json_summary() {
    local repo_root="$1"
    local branch_name="$2"
    local status="${3:-created}"

    python3 -c "
import json, os, sys

repo_root = '$repo_root'
branch_name = '$branch_name'
status = '$status'
config_file = os.path.join(repo_root, '$MULTIREPO_CONFIG_NAME')

repos_list = []
try:
    with open(config_file) as f:
        data = json.load(f)
    configured = data.get('repositories', [])
    canonical_root = os.path.realpath(repo_root)
    resolved = [canonical_root]
    for r in configured:
        p = os.path.realpath(os.path.join(repo_root, r))
        if os.path.isdir(p) and os.path.exists(os.path.join(p, '.git')):
            if p not in resolved:
                resolved.append(p)
    for p in resolved:
        repos_list.append({
            'name': os.path.basename(p),
            'path': p,
            'branch': branch_name,
            'status': status
        })
except Exception:
    repos_list.append({
        'name': os.path.basename(repo_root),
        'path': repo_root,
        'branch': branch_name,
        'status': status
    })

print(json.dumps(repos_list))
" 2>/dev/null
}
