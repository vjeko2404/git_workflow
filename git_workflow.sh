#!/bin/bash
#
# Universal Git Workflow Script
#
# A modular, full-scope Git workflow script that guides a user
# through a clean, fork-based Pull Request flow.
#
# Implements the 12-point plan:
# 1. check_git_context
# 2. detect_repo_state
# 3. sync_upstream_main
# 4. create_feature_branch
# 5. stage_and_commit_changes
# 6. push_to_fork
# 7. create_pull_request
# 8. clean_up_branches
# 9. status_overview
# 10. interactive_menu
# 11. config_and_init
# 12. fatal_guardrails
#
# Bonus:
# - Auto-adds config to .gitignore

# --- Script Setup ---
# Exit immediately if a command exits with a non-zero status.
set -e
# Treat unset variables as an error
# set -u (Disabled for now, can be too strict with config files)
# Pipeline's return value is the status of the last command to exit non-zero
set -o pipefail

# --- Constants & Colors ---
RST="\033[0m"
RED="\033[0;31m"
GRN="\033[0;32m"
YLW="\033[0;33m"
BLU="\033[0;34m"
MAG="\033[0;35m"
CYN="\033[0;36m"

# Emojis (for visual cues)
EM_GIT="🧱"
EM_WARN="⚠️"
EM_ERR="❌"
EM_OK="✅"
EM_INFO="ℹ️"
EM_SPIN="⏳"
EM_BRANCH="🌿"
EM_PUSH="⬆️"
EM_PULL="⬇️"
EM_PR="📬"
EM_CLEAN="🧹"
EM_COMMIT="📝"
EM_SETUP="⚙️"
EM_STATUS="📊"

# --- Config File ---
# We store this inside .git to keep the working tree clean.
CONFIG_FILE=".git/gitflowrc"

# --- Helper Functions (Logging & Utils) ---

info() { echo -e "${CYN}${EM_INFO} $1${RST}"; }
success() { echo -e "${GRN}${EM_OK} $1${RST}"; }
warn() { echo -e "${YLW}${EM_WARN} $1${RST}"; }
fatal() {
    echo -e "${RED}${EM_ERR} $1${RST}"
    exit 1
}
prompt() { echo -e -n "${MAG}? $1${RST} "; }

# Utility to check if a command exists
check_command() {
    if ! command -v "$1" &>/dev/null; then
        fatal "Command '$1' not found, but it is required. Please install it."
    fi
}

# Utility to check if we're in an interactive TTY
is_interactive() {
    [ -t 1 ]
}

# --- MODULE 1 & 2: Context and State Detection ---

# Helper to get current branch name
get_current_branch() {
    git rev-parse --abbrev-ref HEAD
}

# Helper to check if the working tree is dirty
is_dirty() {
    ! git diff --quiet || ! git diff --cached --quiet
}

# This function loads config and detects repo state (Module 1, 2, 11)
load_config_and_state() {
    # 1. check_git_context: Ensure we are in a git repo
    if ! git rev-parse --is-inside-work-tree &>/dev/null; then
        fatal "Not a Git repository. Exiting."
    fi

    # 2. Load defaults
    ORIGIN_REMOTE="origin"
    UPSTREAM_REMOTE="upstream"
    MAIN_BRANCH="main"
    GITHUB_USER=""

    # 3. Load from config file (Module 11)
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    fi

    # 4. detect_repo_state (Module 2)
    CURRENT_BRANCH=$(get_current_branch)
    ORIGIN_URL=$(git config --get "remote.${ORIGIN_REMOTE}.url" || echo "")
    UPSTREAM_URL=$(git config --get "remote.${UPSTREAM_REMOTE}.url" || echo "")

    # 5. Validations (Module 1, 12)
    if [ -z "$ORIGIN_URL" ]; then
        fatal "Remote '$ORIGIN_REMOTE' not found. Please add it or run 'init'."
    fi
    if [ -z "$UPSTREAM_URL" ]; then
        warn "Remote '$UPSTREAM_REMOTE' not found. This script works best with a fork."
        warn "Please add the upstream remote: git remote add $UPSTREAM_REMOTE <upstream_repo_url>"
        # Allow to continue, but some features will be disabled
    fi

    # Auto-detect main branch name if default 'main' doesn't exist
    if ! git show-ref --verify --quiet "refs/remotes/$UPSTREAM_REMOTE/$MAIN_BRANCH"; then
        if git show-ref --verify --quiet "refs/remotes/$UPSTREAM_REMOTE/master"; then
            MAIN_BRANCH="master"
            info "Auto-detected main branch as 'master'"
        elif [ -n "$UPSTREAM_URL" ]; then
            # Only warn if upstream is set, otherwise it's normal
            warn "Could not find '$MAIN_BRANCH' or 'master' on upstream. Using '$MAIN_BRANCH' as default."
        fi
    fi

    # Flag protected branches
    IS_ON_PROTECTED_BRANCH=false
    if [[ "$CURRENT_BRANCH" == "$MAIN_BRANCH" || "$CURRENT_BRANCH" == "master" ]]; then
        IS_ON_PROTECTED_BRANCH=true
    fi
}

# --- MODULE 12: Fatal Guardrails ---

# Guard against a dirty working tree
guard_dirty_tree() {
    if is_dirty; then
        warn "Your working tree is dirty (uncommitted changes)."
        if is_interactive; then
            prompt "Press (s) to stash, (a) to abort, (c) to continue anyway. [a]"
            read -r action
            case "$action" in
                s | S)
                    git stash
                    success "Changes stashed."
                    ;;
                c | C)
                    warn "Continuing with a dirty tree."
                    ;;
                *)
                    fatal "Aborted due to dirty working tree."
                    ;;
            esac
        else
            fatal "Working tree is dirty. Stash or commit changes first, or use --force."
        fi
    fi
}

# Guard against running feature-specific commands on 'main'
guard_on_main() {
    if $IS_ON_PROTECTED_BRANCH; then
        fatal "This operation is not allowed on the '$MAIN_BRANCH' branch. Please create a feature branch first."
    fi
}

# --- MODULE 11: Config and Init ---

run_configuration() {
    info "${EM_SETUP} Running initial setup..."

    prompt "Name of your fork remote? (Default: origin)"
    read -r val
    ORIGIN_REMOTE=${val:-origin}

    prompt "Name of the upstream remote? (Default: upstream)"
    read -r val
    UPSTREAM_REMOTE=${val:-upstream}

    prompt "Default main branch name? (Default: main)"
    read -r val
    MAIN_BRANCH=${val:-main}

    prompt "Your GitHub username (for PR URL fallback):"
    read -r GITHUB_USER

    # Save to config
    echo "# Git Workflow Config" >"$CONFIG_FILE"
    echo "ORIGIN_REMOTE=\"$ORIGIN_REMOTE\"" >>"$CONFIG_FILE"
    echo "UPSTREAM_REMOTE=\"$UPSTREAM_REMOTE\"" >>"$CONFIG_FILE"
    echo "MAIN_BRANCH=\"$MAIN_BRANCH\"" >>"$CONFIG_FILE"
    echo "GITHUB_USER=\"$GITHUB_USER\"" >>"$CONFIG_FILE"

    success "Configuration saved to $CONFIG_FILE"

    # Bonus: Add to .gitignore
    if [ -f ".gitignore" ]; then
        if ! grep -q ".git/gitflowrc" ".gitignore"; then
            info "Adding $CONFIG_FILE to .gitignore"
            echo -e "\n# Git workflow config\n.git/gitflowrc" >>.gitignore
        fi
    fi

    # Add self to .gitignore
    if [ -f ".gitignore" ]; then
        if ! grep -q "git_workflow.sh" ".gitignore"; then
            info "Adding 'git_workflow.sh' to .gitignore"
            echo -e "\n# Git workflow script\ngit_workflow.sh" >>.gitignore
        fi
    fi
}

# --- MODULE 3: Sync Upstream Main ---

sync_upstream_main() {
    info "${EM_PULL} Syncing '$MAIN_BRANCH' from '$UPSTREAM_REMOTE'..."
    if [ -z "$UPSTREAM_URL" ]; then fatal "Upstream remote not set."; fi

    # Go to main branch first
    if ! $IS_ON_PROTECTED_BRANCH; then
        info "Switching to '$MAIN_BRANCH' branch..."
        git checkout "$MAIN_BRANCH"
        CURRENT_BRANCH="$MAIN_BRANCH" # Update state
        IS_ON_PROTECTED_BRANCH=true
    fi

    guard_dirty_tree

    info "Fetching from '$UPSTREAM_REMOTE'..."
    git fetch "$UPSTREAM_REMOTE"

    info "Rebasing local '$MAIN_BRANCH' onto '$UPSTREAM_REMOTE/$MAIN_BRANCH'..."
    if ! git rebase "$UPSTREAM_REMOTE/$MAIN_BRANCH"; then
        fatal "Rebase failed! Fix conflicts and run 'git rebase --continue' or 'git rebase --abort'."
    fi

    success "'$MAIN_BRANCH' is now in sync with '$UPSTREAM_REMOTE/$MAIN_BRANCH'."

    # Optional: push to origin
    if is_interactive; then
        prompt "Push updated '$MAIN_BRANCH' to '$ORIGIN_REMOTE'? (y/N)"
        read -r push_orig
        if [[ "$push_orig" == "y" || "$push_orig" == "Y" ]]; then
            info "Pushing to '$ORIGIN_REMOTE/$MAIN_BRANCH'..."
            git push "$ORIGIN_REMOTE" "$MAIN_BRANCH"
        fi
    fi
}

# --- MODULE 4: Create Feature Branch ---

create_feature_branch() {
    local branch_name=$1
    if [ -z "$branch_name" ]; then
        if is_interactive; then
            prompt "Enter new branch name (e.g., 'fix/login' or 'feature/dashboard'):"
            read -r branch_name
        else
            fatal "Branch name not provided."
        fi
    fi

    # Simple sanitization
    local sanitized_name=$(echo "$branch_name" | tr '[:upper:]' '[:lower:]' | tr -s '[:space:]' '-' | sed 's/[^a-z0-9\-\/]//g')

    if [ -z "$sanitized_name" ]; then
        fatal "Invalid branch name provided."
    fi

    info "Syncing '$MAIN_BRANCH' before branching..."
    sync_upstream_main

    info "${EM_BRANCH} Creating and checking out new branch: '$sanitized_name'"
    git checkout -b "$sanitized_name"

    success "Switched to new branch '$sanitized_name' based on '$MAIN_BRANCH'."
}

# --- MODULE 5: Stage and Commit Changes ---

stage_and_commit_changes() {
    if ! is_dirty; then
        warn "No changes to commit."
        return 0
    fi

    info "Changes detected:"
    git status -s

    if is_interactive; then
        prompt "Stage (a)ll, (i)nteractive, or (n)o? [a]"
        read -r action

        case "$action" in
            i | I)
                info "Entering interactive add. Stage your files, then exit patch mode."
                git add -p
                # Check if anything was staged
                if git diff --cached --quiet; then
                    warn "No files were staged. Commit aborted."
                    return 1
                fi
                ;;
            n | N)
                warn "Commit aborted."
                return 1
                ;;
            *)
                info "Staging all changes..."
                git add .
                ;;
        esac

        # Check for amend
        prompt "Amend previous commit? (y/N)"
        read -r amend
        if [[ "$amend" == "y" || "$amend" == "Y" ]]; then
            git commit --amend
            success "Changes amended to previous commit."
            return 0
        fi

        prompt "Enter commit message (or press Enter to open $EDITOR):"
        read -r commit_msg

        if [ -z "$commit_msg" ]; then
            git commit
        else
            git commit -m "$commit_msg"
        fi

    else
        # Non-interactive mode
        info "Staging all changes for non-interactive commit..."
        git add .
        local commit_msg=$1
        if [ -z "$commit_msg" ]; then
            commit_msg="Auto-commit by git_workflow.sh"
            warn "No commit message provided. Using default: '$commit_msg'"
        fi
        git commit -m "$commit_msg"
    fi

    success "${EM_COMMIT} Changes committed."
}

# --- MODULE 6: Push to Fork ---

push_to_fork() {
    guard_on_main

    info "${EM_PUSH} Pushing '$CURRENT_BRANCH' to '$ORIGIN_REMOTE'..."

    # Check if remote branch exists
    if git ls-remote --exit-code --heads "$ORIGIN_REMOTE" "$CURRENT_BRANCH" &>/dev/null; then
        info "Remote branch exists. Pushing updates."
        git push "$ORIGIN_REMOTE" "$CURRENT_BRANCH"
    else
        info "New branch. Setting upstream tracking and pushing."
        git push --set-upstream "$ORIGIN_REMOTE" "$CURRENT_BRANCH"
    fi

    success "Branch '$CURRENT_BRANCH' pushed to '$ORIGIN_REMOTE'."
}

# --- MODULE 7: Create Pull Request ---

create_pull_request() {
    guard_on_main
    if [ -z "$UPSTREAM_URL" ]; then fatal "Upstream remote not set. Cannot create PR."; fi

    # Ensure branch is pushed
    if ! git ls-remote --exit-code --heads "$ORIGIN_REMOTE" "$CURRENT_BRANCH" &>/dev/null; then
        warn "Branch not found on '$ORIGIN_REMOTE'. Pushing first..."
        push_to_fork
    fi

    local base_branch="$MAIN_BRANCH"
    local head_branch="$CURRENT_BRANCH"
    local upstream_repo_full
    upstream_repo_full=$(echo "$UPSTREAM_URL" | sed -E 's/.*:([^\/]+\/[^\.]+)(\.git)?/\1/' | sed -E 's/.*\/([^\/]+\/[^\/]+)$/\1/')

    info "${EM_PR} Preparing to create Pull Request..."
    info "  Base: $UPSTREAM_REMOTE/$base_branch"
    info "  Head: $ORIGIN_REMOTE/$head_branch"

    if command -v gh &>/dev/null; then
        info "GitHub CLI found. Creating PR (will open in browser)..."
        # Try to create PR. Fill as much as possible.
        gh pr create --repo "$upstream_repo_full" --base "$base_branch" --head "$head_branch" --web
        success "Opened PR in browser."
    else
        warn "GitHub CLI ('gh') not found. Please install it for the best experience."
        info "Please open this URL in your browser to create the PR:"

        # Fallback URL generation
        local upstream_repo_url=$(echo "$UPSTREAM_URL" | sed 's/\.git$//' | sed 's/git@github.com:/https:/github.com\//')
        
        # Determine head_ref (username)
        local head_ref="$GITHUB_USER"
        if [ -z "$head_ref" ]; then
             head_ref=$(echo "$ORIGIN_URL" | sed -E 's/.*:([^\/]+)\/.*/\1/' | sed -E 's/.*\/([^\/]+)\/.*/\1/')
        fi
        
        if [ -z "$head_ref" ]; then
            head_ref="YOUR_USERNAME"
        fi

        local pr_url="$upstream_repo_url/compare/$base_branch...$head_ref:$head_branch"
        echo -e "${BLU}$pr_url${RST}"
    fi
}

# --- MODULE 8: Clean Up Branches ---

clean_up_branches() {
    local branch_to_delete=$1
    if [ -z "$branch_to_delete" ]; then
        branch_to_delete=$CURRENT_BRANCH
    fi

    if [[ "$branch_to_delete" == "$MAIN_BRANCH" || "$branch_to_delete" == "master" ]]; then
        fatal "Cannot delete the '$MAIN_BRANCH' branch!"
    fi

    info "${EM_CLEAN} This will delete branch '$branch_to_delete' locally and on '$ORIGIN_REMOTE'."
    if is_interactive; then
        prompt "Are you sure? (This assumes the PR was merged) (y/N)"
        read -r confirm
        if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
            warn "Cleanup aborted."
            return 1
        fi
    fi

    info "Switching to '$MAIN_BRANCH' and syncing..."
    # We don't call sync_upstream_main to avoid the push prompt
    git checkout "$MAIN_BRANCH"
    if [ -n "$UPSTREAM_URL" ]; then
        git fetch "$UPSTREAM_REMOTE"
        git rebase "$UPSTREAM_REMOTE/$MAIN_BRANCH"
    fi

    info "Deleting local branch '$branch_to_delete'..."
    if ! git branch -D "$branch_to_delete"; then
        warn "Could not delete local branch. It might have unmerged changes."
    fi

    info "Deleting remote branch '$ORIGIN_REMOTE/$branch_to_delete'..."
    if ! git push "$ORIGIN_REMOTE" --delete "$branch_to_delete"; then
        warn "Could not delete remote branch. It might be protected or already gone."
    fi

    success "Cleanup complete."
}

# --- MODULE 9: Status Overview ---

show_status_overview() {
    info "${EM_STATUS} --- Git Workflow Status ---"

    echo -e "  Branch: ${GRN}$CURRENT_BRANCH${RST}"
    if $IS_ON_PROTECTED_BRANCH; then
        echo -e "  ${YLW}You are on the main branch.${RST}"
    fi

    # Remotes
    echo -e "\n  Remotes:"
    echo -e "    Origin (${ORIGIN_REMOTE}): ${BLU}$ORIGIN_URL${RST}"
    if [ -n "$UPSTREAM_URL" ]; then
        echo -e "    Upstream (${UPSTREAM_REMOTE}): ${BLU}$UPSTREAM_URL${RST}"
    else
        echo -e "    Upstream (${UPSTREAM_REMOTE}): ${RED}Not Configured${RST}"
    fi

    # Dirty state
    echo -e "\n  Working Tree:"
    if is_dirty; then
        warn "  You have uncommitted changes."
        git status -s | sed 's/^/    /'
    else
        success "  Working tree is clean."
    fi

    # Commit status
    if ! $IS_ON_PROTECTED_BRANCH && [ -n "$UPSTREAM_URL" ]; then
        echo -e "\n  Commit Status:"
        # Check against upstream/main
        local merge_base
        merge_base=$(git merge-base "$UPSTREAM_REMOTE/$MAIN_BRANCH" HEAD)
        local head_commit
        head_commit=$(git rev-parse HEAD)

        if [[ "$merge_base" == "$head_commit" ]]; then
            info "  Your branch is even with '$UPSTREAM_REMOTE/$MAIN_BRANCH'."
        else
            local commits_ahead
            commits_ahead=$(git rev-list --count "$UPSTREAM_REMOTE/$MAIN_BRANCH"..HEAD)
            if [ "$commits_ahead" -gt 0 ]; then
                info "  You have ${GRN}$commits_ahead commit(s)${RST} ahead of '$UPSTREAM_REMOTE/$MAIN_BRANCH'."
                git log --oneline --graph --decorate -n "$commits_ahead" "$UPSTREAM_REMOTE/$MAIN_BRANCH"..HEAD | sed 's/^/    /'
            else
                info "  Your branch seems to be behind '$UPSTREAM_REMOTE/$MAIN_BRANCH'."
            fi
        fi
    fi

    # Next Action
    echo -e "\n  Next Action Suggestion:"
    if is_dirty; then
        info "  Run '${CYN}$0 commit${RST}' to save your changes."
    elif ! $IS_ON_PROTECTED_BRANCH; then
        if ! git ls-remote --exit-code --heads "$ORIGIN_REMOTE" "$CURRENT_BRANCH" &>/dev/null; then
            info "  Run '${CYN}$0 push${RST}' to push your branch."
        else
            info "  Run '${CYN}$0 pr${RST}' to create a Pull Request."
        fi
    elif $IS_ON_PROTECTED_BRANCH; then
        info "  Run '${CYN}$0 new <branch-name>${RST}' to start new work."
    fi
    echo -e "-----------------------------------"
}

# --- MODULE 10: Interactive Menu ---

show_interactive_menu() {
    while true; do
        # Reload state every loop
        load_config_and_state

        clear
        echo -e "${BLU}${EM_GIT} Git Workflow Helper ${EM_GIT}${RST}"
        echo -e "---------------------------------"
        echo -e "  Current Branch: ${GRN}$CURRENT_BRANCH${RST}"
        if is_dirty; then echo -e "  ${YLW}Working tree is dirty!${RST}"; fi
        echo -e "---------------------------------"
        echo -e "  1. ${CYN}Show Status / Suggest Action${RST}"
        echo -e "  2. ${GRN}Start New Feature/Fix...${RST} (syncs main, creates branch)"
        echo -e "  3. ${YLW}Sync Main from Upstream${RST}"

        # Context-aware options
        local disabled_str="${RST}(Unavailable on main)${RST}"
        if ! $IS_ON_PROTECTED_BRANCH; then
            echo -e "  4. ${BLU}Commit Changes...${RST}"
            echo -e "  5. ${MAG}Push Branch to Fork ($ORIGIN_REMOTE)${RST}"
            echo -e "  6. ${GRN}Create Pull Request${RST}"
            echo -e "  7. ${RED}Clean Up Branch (After Merge)${RST}"
        else
            echo -e "  4. ${disabled_str}"
            echo -e "  5. ${disabled_str}"
            echo -e "  6. ${disabled_str}"
            echo -e "  7. ${disabled_str}"
        fi

        echo -e "  8. ${CYN}Run Setup/Configuration${RST}"
        echo -e "  Q. ${RST}Quit"
        echo -e "---------------------------------"

        prompt "Select an option [1-8, Q]:"
        read -r choice

        case "$choice" in
            1) show_status_overview; read -r -p "Press Enter to continue..." ;;
            2) create_feature_branch ;;
            3) sync_upstream_main ;;
            4) if ! $IS_ON_PROTECTED_BRANCH; then stage_and_commit_changes; else warn "Operation not available on main."; fi ;;
            5) if ! $IS_ON_PROTECTED_BRANCH; then push_to_fork; else warn "Operation not available on main."; fi ;;
            6) if ! $IS_ON_PROTECTED_BRANCH; then create_pull_request; else warn "Operation not available on main."; fi ;;
            7) if ! $IS_ON_PROTECTED_BRANCH; then clean_up_branches "$CURRENT_BRANCH"; else warn "Operation not available on main."; fi ;;
            8) run_configuration ;;
            q | Q) echo "Exiting."; exit 0 ;;
            *) warn "Invalid option." ;;
        esac

        if [[ "$choice" != "1" && "$choice" != "" ]]; then
            read -r -p "Press Enter to continue..."
        fi
    done
}

# --- Main Execution ---

show_help() {
    echo "Usage: $0 [command] [args]"
    echo ""
    echo "  A tool to manage a fork-based Git PR workflow."
    echo ""
    echo "  Commands:"
    echo "    (no args)     Show interactive menu"
    echo "    init/config   Run first-time setup (or re-configure)"
    echo "    status        Show status overview and next-action suggestion"
    echo "    sync          Fetch and rebase local main from upstream/main"
    echo "    new <name>    Create a new feature branch (syncs main first)"
    echo "    commit [msg]  Stage and commit changes (interactive if no msg)"
    echo "    push          Push current branch to fork (origin)"
    echo "    pr            Create a Pull Request (uses 'gh' or prints URL)"
    echo "    clean [name]  Delete branch locally and on fork (default: current)"
    echo "    help          Show this help message"
}

main() {
    # Always check for git
    check_command "git"

    # Check for config first
    if [ ! -f "$CONFIG_FILE" ] && [[ "$1" != "init" && "$1" != "config" && "$1" != "help" && "$1" != "" ]]; then
        warn "Config file not found. Running initial setup first..."
        run_configuration
    elif [ ! -f "$CONFIG_FILE" ] && [ "$1" == "" ] && is_interactive; then
        warn "Welcome! Config file not found."
        run_configuration
    fi

    # Load state *after* config check
    load_config_and_state

    # Non-interactive CLI commands
    if [ "$#" -gt 0 ]; then
        case "$1" in
            init | config)
                run_configuration
                ;;
            status)
                show_status_overview
                ;;
            sync)
                sync_upstream_main
                ;;
            new | feature | fix)
                shift
                create_feature_branch "$@"
                ;;
            commit)
                shift
                stage_and_commit_changes "$@" # Pass msg
                ;;
            push)
                push_to_fork
                ;;
            pr | pull-request)
                create_pull_request
                ;;
            clean | cleanup)
                shift
                clean_up_branches "$@" # Optional branch name
                ;;
            help | --help | -h)
                show_help
                ;;
            *)
                fatal "Unknown command: $1. Use 'help' for usage."
                ;;
        esac
        exit 0
    fi

    # Interactive Menu
    if is_interactive; then
        show_interactive_menu
    else
        warn "Not an interactive terminal. Showing help."
        show_help
        fatal "Please provide a command."
    fi
}

# Pass all arguments to the main function
main "$@"
