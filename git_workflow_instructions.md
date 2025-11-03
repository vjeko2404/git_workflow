
# How to Use the Universal Git Workflow Script

This guide explains how to install, set up, and use the `git_workflow.sh` script to manage a clean, fork-based pull request workflow.

## 1. Installation

1.  **Place the Script:** Move the `git_workflow.sh` file to a directory in your system's `PATH`. A common location is `/usr/local/bin`.
    
    ```
    mv git_workflow.sh /usr/local/bin/git_workflow.sh
    
    ```
    
2.  **Make it Executable:** You only need to do this once.
    
    ```
    chmod +x /usr/local/bin/git_workflow.sh
    
    ```
    

Now you can run the script from any directory (just like `git`) by typing its name: `git_workflow.sh`.

## 2. One-Time Setup (Per Repository)

The first time you run the script inside a new repository, it will automatically guide you through a quick setup:

```
# Navigate to your git repo
cd /path/to/your-project

# Run the script
git_workflow.sh

```

It will ask you to configure:

-   **Origin Remote:** The name of your fork (e.g., `origin`).
    
-   **Upstream Remote:** The name of the main project repo (e.g., `upstream`).
    
-   **Main Branch:** The name of the default branch (e.g., `main` or `master`).
    
-   **GitHub Username:** Used for creating PR URLs if the `gh` CLI isn't found.
    

This configuration is saved to a `.git/gitflowrc` file, so you won't be asked again for this project.

## 3. Two Ways to Use the Script

The script works in two modes, giving you flexibility.

### Mode 1: Interactive Menu (The Guided Way)

This is the easiest method. Simply run the script with no arguments:

```
git_workflow.sh

```

This launches a full-screen menu that guides you through every action. It's context-aware, so it will disable options that don't make sense (like trying to create a PR from your `main` branch).

```
🧱 Git Workflow Helper 🧱
---------------------------------
  Current Branch: main
---------------------------------
  1. Show Status / Suggest Action
  2. Start New Feature/Fix...
  3. Sync Main from Upstream
  4. (Unavailable on main)
  ...
  Q. Quit
---------------------------------
? Select an option [1-8, Q]:

```

### Mode 2: Direct CLI Commands (The Fast Way)

You can use `git_workflow.sh` as an extension of `git` itself by providing commands directly.

```
git_workflow.sh [command] [arguments]

```

This is fast, powerful, and ideal for automation.

## Example End-to-End Workflow (CLI Mode)

Here is how you would use the script to contribute a new feature from start to finish.

### Step 1: Start New Work

Run the `new` command to create your branch.

```
git_workflow.sh new "feature/add-user-profile"

```

-   **What it does:**
    
    1.  Runs `sync` to switch to your `main` branch.
        
    2.  Fetches and rebases `main` from `upstream` to get the latest changes.
        
    3.  Creates your new branch (`feature/add-user-profile`) from this up-to-date `main`.
        

### Step 2: Write Code & Commit

After you've made changes, use the `commit` command.

```
# To commit all changes with a message:
git_workflow.sh commit "Add user profile page"

# To launch an interactive session:
git_workflow.sh commit

```

-   **What it does:**
    
    -   If you provide a message, it stages all changes and commits them.
        
    -   If you don't provide a message, it asks you to stage files (all, interactive, etc.) and prompts for a commit message.
        

### Step 3: Push to Your Fork

Your commits are local. Send them to your fork (`origin`).

```
git_workflow.sh push

```

-   **What it does:** Pushes your current branch to `origin` and sets up remote tracking.
    

### Step 4: Create the Pull Request

Your branch is on your fork. Time to open the PR.

```
git_workflow.sh pr

```

-   **What it does:**
    
    -   **If you have the GitHub CLI (`gh`) installed:** It runs `gh pr create` and opens your browser directly to the new PR page.
        
    -   **If not:** It prints a special URL. Copy and paste this URL into your browser, and it will open the "Create PR" page with your fork/branch pre-filled.
        

### Step 5: Clean Up (After Your PR is Merged)

Your PR is merged! Your feature branch is no longer needed.

```
git_workflow.sh clean

```

-   **What it does:**
    
    1.  Switches you back to the `main` branch.
        
    2.  Runs `sync` to pull the latest changes (including your merged PR).
        
    3.  Deletes the feature branch from your local machine.
        
    4.  Deletes the feature branch from your fork (`origin`).
        

## Other Useful Commands

-   `git_workflow.sh status`: Shows a full report of your current branch, remotes, and dirty status, and suggests a next action.
    
-   `git_workflow.sh sync`: Just syncs your `main` branch from `upstream` without creating a new branch.
    
-   `git_workflow.sh help`: Displays the full list of commands.
