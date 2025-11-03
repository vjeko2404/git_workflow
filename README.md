# Universal Git Workflow Script

`git_workflow.sh` is a single, powerful shell script that guides you through a clean, fork-based Git workflow. It works both as an interactive, menu-driven tool and as a set of direct CLI commands for automation.

It's designed to formalize best practices (like syncing from upstream before branching) and automate repetitive tasks (like branch cleanup and PR creation).

## Features

-   **Modular:** Each step of the workflow is a self-contained function.
    
-   **Context-Aware:** Detects your repo's state (dirty tree, current branch, remotes) to provide smart suggestions and prevent common errors.
    
-   **Fork & Upstream Native:** Built specifically for the fork-and-pull-request model.
    
-   **Dual Mode:**
    
    -   **Interactive Menu:** A full-screen UI for a guided experience.
        
    -   **CLI Commands:** Fast, direct commands (e.g., `git_workflow.sh new ...`) for power users and automation.
        
-   **Guardrails:** Protects you from mistakes like committing to `main` or forgetting to sync.
    
-   **Self-Contained:** A single script with no external dependencies other than `git` (and `gh` for the best PR experience).
    
-   **Per-Project Config:** Saves your preferences (remote names, etc.) to a `.git/gitflowrc` file, keeping your working directory clean.
    

## Installation

1.  **Download the script** (`git_workflow.sh`) to your local machine.
    
2.  **Move it** to a directory in your system's `PATH`:
    
    ```
    mv git_workflow.sh /usr/local/bin/git_workflow.sh
    
    ```
    
3.  **Make it executable:**
    
    ```
    chmod +x /usr/local/bin/git_workflow.sh
    
    ```
    
4.  You can now run `git_workflow.sh` from any directory, just like you run `git`.
    

## Quick Start

1.  **Navigate to your Git repo** and run the script for the first time to set it up:
    
    ```
    cd /path/to/your-project
    git_workflow.sh init
    
    ```
    
    This will ask for your remote names (e.g., `origin`, `upstream`) and save them.
    
2.  **Start new work:**
    
    ```
    # This syncs `main` from `upstream` *before* creating your branch
    git_workflow.sh new "my-awesome-feature"
    
    ```
    
3.  **Code, then commit:**
    
    ```
    # Commits all changes with a message
    git_workflow.sh commit "Add my awesome feature"
    
    # Or run interactively
    git_workflow.sh commit
    
    ```
    
4.  **Push and create PR:**
    
    ```
    git_workflow.sh push
    git_workflow.sh pr
    
    ```
    
5.  **Clean up after your PR is merged:**
    
    ```
    git_workflow.sh clean
    
    ```
    

## Detailed Guide

For a complete list of commands and a detailed end-to-end walkthrough, please see the [**How to Use the Git Workflow Script**]([https://www.google.com/search?q=git_workflow_usage.md "null"](https://github.com/vjeko2404/git_workflow/blob/main/git_workflow_instructions.md)) guide.
