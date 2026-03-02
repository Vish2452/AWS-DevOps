# Git & GitHub — Complete Guide with Real-World Examples

> A practical reference covering every Git concept from basics to advanced workflows. Explained so anyone — fresher or experienced — can follow along.

---

## Table of Contents

1. [What is Git and Why It Matters](#1--what-is-git-and-why-it-matters)
2. [Setting Up Git](#2--setting-up-git)
3. [Core Concepts — Staging, Commits, History](#3--core-concepts--staging-commits-history)
4. [Branching — Create, Switch, Delete](#4--branching--create-switch-delete)
5. [Merging — Bringing Branches Together](#5--merging--bringing-branches-together)
6. [Rebase — Rewriting History Cleanly](#6--rebase--rewriting-history-cleanly)
7. [Cherry-Pick — Copy Specific Commits](#7--cherry-pick--copy-specific-commits)
8. [Stashing — Save Work Temporarily](#8--stashing--save-work-temporarily)
9. [Undoing Changes — Reset, Revert, Restore](#9--undoing-changes--reset-revert-restore)
10. [Resolving Merge Conflicts](#10--resolving-merge-conflicts)
11. [Remote Repositories & Collaboration](#11--remote-repositories--collaboration)
12. [Pull Requests & Code Review](#12--pull-requests--code-review)
13. [GitFlow — The Complete Branching Strategy](#13--gitflow--the-complete-branching-strategy)
14. [Hotfix Workflow](#14--hotfix-workflow)
15. [Conventional Commits](#15--conventional-commits)
16. [Tagging & Semantic Versioning](#16--tagging--semantic-versioning)
17. [Advanced Git Commands](#17--advanced-git-commands)
18. [.gitignore — Hiding Files from Git](#18--gitignore--hiding-files-from-git)
19. [Git Aliases — Time-Saving Shortcuts](#19--git-aliases--time-saving-shortcuts)
20. [Real-World Workflow — Day in the Life](#20--real-world-workflow--day-in-the-life)
21. [Quick Reference Cheat Sheet](#21--quick-reference-cheat-sheet)

---

## 1 — What is Git and Why It Matters

Git is a **version control system** — it tracks every change made to your code, who made it, and when.

> **Think of it this way:** Imagine you're writing a book with 5 coauthors.
> - Without Git: Everyone emails Word files back and forth. Someone overwrites chapters. Nobody knows who changed what. Chaos.
> - With Git: Everyone works on their own copy. Changes are tracked line by line. You can see who wrote what, when, and why. If someone makes a mistake, you can undo just that one change.
>
> **Every tech company uses Git.** Netflix, Google, Amazon, Microsoft — all of them. If you want to work in DevOps or software engineering, Git is not optional.

### Git vs GitHub — What's the Difference?

| | Git | GitHub |
|---|-----|--------|
| **What** | A tool (software) on your computer | A website/platform in the cloud |
| **Where** | Runs locally on your laptop/server | Runs at github.com |
| **Purpose** | Track changes to files | Store Git repos online + collaboration features |
| **Analogy** | The pen you write with | The library where everyone stores their notebooks |

> You can use Git without GitHub (just locally). But GitHub adds collaboration: Pull Requests, code reviews, issue tracking, CI/CD, and more.

---

## 2 — Setting Up Git

### First-Time Setup (Do This Once)

```bash
# Tell Git your name and email (appears in every commit)
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Set default branch name to "main" (modern standard)
git config --global init.defaultBranch main

# Set default editor (for commit messages)
git config --global core.editor "code --wait"     # VS Code
git config --global core.editor "nano"             # Nano (simpler)

# Enable colored output (easier to read)
git config --global color.ui auto

# Check your settings
git config --list
```

### Starting a New Repository

```bash
# Option 1: Create a new repo from scratch
mkdir my-project
cd my-project
git init                    # Initializes an empty Git repository
echo "# My Project" > README.md
git add README.md
git commit -m "Initial commit"

# Option 2: Clone an existing repo from GitHub
git clone https://github.com/username/repo-name.git
cd repo-name
```

> **What does `git init` actually do?** It creates a hidden `.git/` folder inside your project. This folder stores ALL the version history, branches, and configuration. Delete it, and the project is no longer tracked by Git.

---

## 3 — Core Concepts — Staging, Commits, History

### The Three Areas of Git

Understanding this is the KEY to understanding Git:

```
┌──────────────┐     git add     ┌──────────────┐    git commit    ┌──────────────┐
│              │  ──────────────▶ │              │  ───────────────▶│              │
│   WORKING    │                 │   STAGING    │                  │  REPOSITORY  │
│  DIRECTORY   │                 │    AREA      │                  │   (History)  │
│              │  ◀──────────── │  (Index)     │                  │              │
│  Your files  │   git restore  │  Ready to    │                  │  Permanent   │
│  as you see  │                │  be saved    │                  │  snapshots   │
│  them        │                │              │                  │              │
└──────────────┘                └──────────────┘                  └──────────────┘
```

> **Think of it like shipping a package:**
> 1. **Working Directory** = Your desk — where you're working on items
> 2. **Staging Area** = The packing box — you decide what goes in the box
> 3. **Repository** = The shipped package — sealed, labeled, tracked forever
>
> You don't have to ship everything on your desk. You pick what goes in the box (`git add`), then you seal and label it (`git commit`).

### Essential Commands

```bash
# Check what's changed (most used command!)
git status                  # Shows modified, staged, and untracked files

# Stage files (add to the packing box)
git add filename.txt        # Stage one specific file
git add .                   # Stage ALL changed files in current directory
git add *.js                # Stage all .js files
git add src/                # Stage everything in the src folder

# Commit (seal the box with a label)
git commit -m "feat: add user login page"            # Commit with message
git commit -am "fix: resolve null pointer error"     # Stage + commit tracked files in one step

# View history
git log                     # Show all commits (press q to exit)
git log --oneline           # Compact view — one line per commit
git log --oneline --graph   # Visual branch graph
git log --oneline -10       # Last 10 commits only
git log --author="John"     # Commits by a specific person
git log --since="2 weeks ago"   # Recent commits only
```

### Understanding Commits

Every commit is a **snapshot** of your entire project at that moment. Each commit has:

```
commit a1b2c3d4e5f6 (HEAD -> main)       ← Unique ID (hash)
Author: John Doe <john@example.com>       ← Who made it
Date:   Mon Mar 02 10:30:00 2026          ← When

    feat: add user login page              ← Why (commit message)
```

> **The hash (`a1b2c3d4...`)** is like a fingerprint — every commit has a unique one. You use it to reference specific commits in commands like `cherry-pick`, `revert`, and `reset`.

### Viewing Changes

```bash
# See what you've changed (before staging)
git diff                        # Shows exact line-by-line changes
git diff filename.txt           # Changes in a specific file

# See what you've staged (before committing)
git diff --staged               # Shows what's in the staging area

# See changes in a specific commit
git show a1b2c3d                # Shows the changes in commit a1b2c3d
git show HEAD                   # Show the latest commit

# See who changed each line (find who introduced a bug)
git blame filename.txt          # Shows author + date for every line
git blame -L 40,60 app.js      # Blame only lines 40-60
```

---

## 4 — Branching — Create, Switch, Delete

Branches let multiple people work on different features at the same time without interfering with each other.

> **Think of it this way:** The `main` branch is a highway. When you create a branch, you take an exit ramp, build something on a side road, and then merge back onto the highway when you're done.
>
> **Why branches matter:** Without branches, every developer pushes directly to the same code. One person's half-finished feature breaks another person's work. Branches keep everyone's work isolated until it's ready.

### Branch Commands

```bash
# See all branches
git branch                      # List local branches (* = current branch)
git branch -a                   # List local + remote branches
git branch -v                   # List branches with last commit info

# Create a new branch
git branch feature/login        # Create branch (but stay on current branch)
git checkout -b feature/login   # Create AND switch to new branch (old way)
git switch -c feature/login     # Create AND switch to new branch (modern way)

# Switch between branches
git checkout main               # Switch to main (old way)
git switch main                 # Switch to main (modern way)

# Rename a branch
git branch -m old-name new-name             # Rename a local branch
git branch -m feature/old feature/new       # Example

# Delete a branch
git branch -d feature/login     # Delete (only if merged) — safe
git branch -D feature/login     # Force delete (even if not merged) — careful!

# Delete a remote branch
git push origin --delete feature/login      # Remove branch from GitHub
```

### Branch Naming Conventions (Industry Standard)

```
feature/   → New features          feature/user-authentication
bugfix/    → Bug fixes             bugfix/login-timeout
hotfix/    → Urgent production fix hotfix/payment-crash
release/   → Release preparation   release/v2.1.0
docs/      → Documentation only    docs/api-guide
chore/     → Maintenance tasks     chore/update-dependencies
refactor/  → Code refactoring      refactor/database-layer
test/      → Adding tests          test/auth-unit-tests
```

> **Tip:** Use lowercase, use hyphens (`-`) not underscores or spaces. Include a ticket number if your team uses Jira or similar: `feature/JIRA-123-user-login`.

---

## 5 — Merging — Bringing Branches Together

Merging combines the work from one branch into another.

> **Think of it this way:** You built a new room on a side road (feature branch). Merging is connecting that room to the main building (main branch).

### How Merge Works

```bash
# Step 1: Switch to the branch you want to merge INTO
git checkout main               # Go to main (the target)

# Step 2: Merge the other branch into it
git merge feature/login         # Bring feature/login changes into main
```

### Two Types of Merge

**1. Fast-Forward Merge (Simple — No Extra Commit)**
```
Before:
main:     A → B → C
                    ╲
feature:             D → E

After merge (fast-forward):
main:     A → B → C → D → E
```
> This happens when main hasn't changed since the feature branch was created. Git just moves the pointer forward.

**2. Three-Way Merge (Creates a Merge Commit)**
```
Before:
main:     A → B → C → F
                    ╲
feature:             D → E

After merge:
main:     A → B → C → F → M (merge commit)
                    ╲     ╱
feature:             D → E
```
> This happens when BOTH branches have new commits. Git creates a special "merge commit" that combines both.

### Merge Commands

```bash
git merge feature/login                     # Standard merge
git merge --no-ff feature/login             # Force a merge commit (even if fast-forward is possible)
git merge --squash feature/login            # Squash all feature commits into one before merging
git merge --abort                           # Cancel a merge in progress (if conflicts)
```

> **When to use `--squash`?** When a feature branch has messy commits like "WIP", "fix typo", "oops". Squashing combines them into one clean commit for the main branch.

---

## 6 — Rebase — Rewriting History Cleanly

Rebase moves your branch's commits to start from the latest point on another branch — creating a cleaner, linear history.

> **Think of it this way:**
> - **Merge** = "I built my house last week, and the neighborhood changed since then. I'll add a bridge connecting my old house to the new road."
> - **Rebase** = "I'll pick up my house and move it to the end of the new road, as if I built it today."

### How Rebase Works

```
Before rebase:
main:     A → B → C → F
                    ╲
feature:             D → E

After rebase:
main:     A → B → C → F
                        ╲
feature:                 D' → E'   (same changes, but replayed on top of F)
```

### Rebase Commands

```bash
# Rebase your current branch onto main
git checkout feature/login
git rebase main                             # Replay feature commits on top of main's latest

# Interactive rebase — edit, squash, reorder commits
git rebase -i HEAD~5                        # Edit the last 5 commits

# After rebase, force push (because history changed)
git push --force-with-lease origin feature/login
```

### Interactive Rebase — Clean Up Before Merging

```bash
git rebase -i HEAD~4                        # Edit last 4 commits
```

This opens an editor:
```
pick a1b2c3d feat: add login form
pick e4f5g6h WIP: work in progress          ← You can squash this
pick i7j8k9l fix: typo in form              ← You can squash this too
pick m0n1o2p feat: add form validation

# Commands:
# p, pick   = use commit as-is
# r, reword = use commit, but change the message
# s, squash = combine with previous commit
# f, fixup  = like squash, but discard this commit's message
# d, drop   = remove this commit entirely
```

Change it to:
```
pick a1b2c3d feat: add login form
squash e4f5g6h WIP: work in progress
squash i7j8k9l fix: typo in form
pick m0n1o2p feat: add form validation
```

> **Result:** 4 messy commits become 2 clean commits.

### Merge vs Rebase — When to Use Which?

| | Merge | Rebase |
|---|-------|--------|
| **History** | Preserves exact history (branching visible) | Creates linear, clean history |
| **Safety** | Safe — never rewrites history | Rewrites history (careful with shared branches!) |
| **Use When** | Merging feature → main (final merge) | Updating your feature branch with latest main |
| **Golden Rule** | — | **NEVER rebase a branch others are working on** |

> **Practical rule:**
> - Use `git rebase main` to update YOUR feature branch with latest main changes
> - Use `git merge` when bringing your feature INTO main

---

## 7 — Cherry-Pick — Copy Specific Commits

Cherry-pick lets you take a single commit from one branch and apply it to another — without merging the entire branch.

> **Think of it this way:** You have a basket of 10 apples (commits) on a branch. Cherry-pick lets you take just 1 or 2 specific apples and put them in a different basket (branch). You don't take all 10.
>
> **When is this useful?**
> - A bug fix is on `develop` but you need it on `main` NOW (before the full release)
> - A commit was made on the wrong branch — pick it off and put it on the right one
> - You want ONE specific feature from a long-running branch

### Cherry-Pick Commands

```bash
# Step 1: Find the commit hash you want
git log --oneline feature/payments
# Output:
# f7a8b9c feat: add Stripe integration
# d4e5f6g fix: handle payment timeout     ← You want THIS one
# a1b2c3d feat: add payment page

# Step 2: Switch to the target branch
git checkout main

# Step 3: Cherry-pick the specific commit
git cherry-pick d4e5f6g
# This creates a NEW commit on main with the same changes as d4e5f6g
```

### Advanced Cherry-Pick

```bash
# Cherry-pick multiple commits
git cherry-pick abc1234 def5678 ghi9012

# Cherry-pick a range of commits
git cherry-pick abc1234..ghi9012            # From abc1234 to ghi9012 (exclusive start)
git cherry-pick abc1234^..ghi9012           # From abc1234 to ghi9012 (inclusive)

# Cherry-pick without committing (stage changes only)
git cherry-pick --no-commit d4e5f6g         # Apply changes but don't auto-commit

# If cherry-pick causes conflicts
git cherry-pick d4e5f6g
# CONFLICT! Fix the files, then:
git add .
git cherry-pick --continue                  # Continue after resolving

# Or abort the cherry-pick
git cherry-pick --abort                     # Cancel and go back to before
```

### Real-World Cherry-Pick Scenario

```
Scenario: Production has a critical bug. The fix is on the develop branch,
but develop also has 20 other unfinished features you can't release yet.

develop:  A → B → C → D(fix) → E → F → G
main:     A → B → X → Y

Solution: Cherry-pick ONLY the fix commit (D) to main

git checkout main
git cherry-pick D
# Now main has the fix, without any of the unfinished features

main:     A → B → X → Y → D'(fix)
```

---

## 8 — Stashing — Save Work Temporarily

Stash saves your uncommitted changes in a temporary storage, giving you a clean working directory.

> **Think of it this way:** You're cooking dinner (working on a feature). Suddenly the doorbell rings — your boss calls with an urgent production bug. You can't leave half-chopped vegetables everywhere. So you put everything in a container and store it in the fridge (stash). Fix the bug, come back, take the container out (stash pop), and continue cooking.
>
> **When you need stash:**
> - Boss says "fix this bug NOW" — but you have uncommitted changes on your feature branch
> - You need to switch branches but `git checkout` refuses because you have unsaved changes
> - You want to temporarily try something else without losing your current work

### Stash Commands

```bash
# Save current changes to stash
git stash                               # Stash tracked files
git stash -u                            # Stash tracked + untracked files
git stash save "WIP: login form styling"# Stash with a description (easier to find later)

# View your stashes
git stash list
# Output:
# stash@{0}: WIP on feature/login: a1b2c3d WIP: login form styling
# stash@{1}: WIP on main: e4f5g6h fixing payment bug

# Restore stashed changes
git stash pop                           # Apply latest stash AND remove it from stash list
git stash apply                         # Apply latest stash but KEEP it in stash list
git stash pop stash@{1}                 # Apply a specific stash

# Delete stashes
git stash drop stash@{0}               # Delete a specific stash
git stash clear                         # Delete ALL stashes — irreversible!

# See what's in a stash without applying it
git stash show stash@{0}               # Summary of changes
git stash show -p stash@{0}            # Full diff of changes
```

### Real-World Stash Workflow

```bash
# You're working on a feature...
# (files modified but not committed)

# URGENT: Production bug reported!
git stash save "WIP: half-done login validation"

# Switch to main and fix the bug
git checkout main
git checkout -b hotfix/payment-crash
# ... fix the bug ...
git commit -m "fix: handle null payment ID"
git push origin hotfix/payment-crash
# Create PR, get it merged

# Go back to your feature and restore your work
git checkout feature/login
git stash pop
# Your half-done work is back exactly as you left it!
```

---

## 9 — Undoing Changes — Reset, Revert, Restore

Things go wrong. Git gives you multiple ways to undo changes — each for a different situation.

> **Think of it this way:**
> - `git restore` = Erasing pencil marks on the current page (undo uncommitted changes)
> - `git revert` = Writing a correction on the next page: "Page 5 was wrong, here's the fix" (safe undo)
> - `git reset` = Ripping out pages from the notebook (rewrites history — careful!)

### `git restore` — Undo Uncommitted Changes

```bash
# Discard changes in a file (go back to last commit)
git restore filename.txt                    # Undo changes in working directory
git restore .                               # Undo ALL changes in working directory

# Unstage a file (remove from staging area, keep changes)
git restore --staged filename.txt           # Unstage — file goes back to "modified"
git restore --staged .                      # Unstage everything
```

### `git revert` — Safely Undo a Commit (Recommended)

Revert creates a NEW commit that undoes the changes of a previous commit. The original commit stays in history.

```bash
# Revert a specific commit
git revert a1b2c3d                          # Creates a new commit undoing a1b2c3d
git revert HEAD                             # Revert the most recent commit

# Revert without auto-committing (review first)
git revert --no-commit a1b2c3d              # Apply the undo, but let you review before committing

# Revert multiple commits
git revert a1b2c3d e4f5g6h                 # Revert two specific commits
git revert HEAD~3..HEAD                     # Revert the last 3 commits
```

```
Before revert:
A → B → C → D(broken)

After git revert D:
A → B → C → D(broken) → D'(undo D)        ← History preserved, damage undone
```

> **Use revert** when you need to undo a commit that's already been pushed. It's safe because it doesn't change history.

### `git reset` — Rewrite History (Use Carefully)

Reset moves the branch pointer backward — as if those commits never happened.

```bash
# Three modes of reset:
git reset --soft HEAD~1         # Undo last commit, keep changes staged
git reset --mixed HEAD~1        # Undo last commit, keep changes unstaged (default)
git reset --hard HEAD~1         # Undo last commit, DELETE all changes — gone forever!
```

> **Understanding the three modes:**
>
> | Mode | Commit | Staging Area | Working Directory | Use When |
> |------|--------|-------------|-------------------|----------|
> | `--soft` | Undone | Kept | Kept | "I want to redo my commit message or combine commits" |
> | `--mixed` | Undone | Cleared | Kept | "I want to restage my files differently" |
> | `--hard` | Undone | Cleared | Cleared | "Throw everything away and go back" — DANGEROUS |

```bash
# Common scenarios:

# "I committed but the message is wrong"
git reset --soft HEAD~1         # Undo commit, changes still staged
git commit -m "correct message" # Recommit with better message

# "I committed files I shouldn't have"
git reset --mixed HEAD~1        # Undo commit, files go back to modified
git add only-these-files.txt    # Re-stage only what you want
git commit -m "clean commit"

# "I broke everything and want to start over from the last good commit"
git reset --hard HEAD~3         # Go back 3 commits — all changes GONE

# "I already pushed and need to reset" (ONLY for your own branches)
git reset --hard HEAD~2
git push --force-with-lease origin feature/my-branch
```

> **GOLDEN RULE:** Never use `git reset --hard` on shared branches (`main`, `develop`). Other people's work will be lost. Use `git revert` instead.

### Recovering from Mistakes — `git reflog`

Even after a hard reset, Git keeps a secret log of everything for 30 days:

```bash
git reflog
# Output:
# a1b2c3d HEAD@{0}: reset: moving to HEAD~3        ← You hard-reset here
# e4f5g6h HEAD@{1}: commit: feat: add dashboard     ← The "lost" commit!
# i7j8k9l HEAD@{2}: commit: feat: add settings

# Recover the lost commit
git reset --hard e4f5g6h        # Jump back to before the mistake
```

> **`git reflog` is your safety net.** As long as you act within ~30 days, almost nothing in Git is truly lost.

---

## 10 — Resolving Merge Conflicts

Conflicts happen when two branches change the **same lines** in the **same file**. Git can't decide which version to keep — so it asks YOU.

> **Think of it this way:** Two coworkers both edit line 25 of the same document. One writes "The sky is blue." The other writes "The sky is red." Git says: "I don't know which one you want. Please pick."
>
> **Conflicts are NORMAL.** They happen in every team. Don't panic.

### What a Conflict Looks Like

When you try to merge and there's a conflict, Git marks the file like this:

```
function getUser() {
<<<<<<< HEAD (your current branch)
    return fetchFromCache(userId);
=======
    return fetchFromDatabase(userId);
>>>>>>> feature/new-db-layer (incoming branch)
}
```

**How to read it:**
- `<<<<<<< HEAD` → Your current branch's version
- `=======` → Separator
- `>>>>>>> feature/new-db-layer` → The incoming branch's version

### How to Resolve Conflicts

```bash
# Step 1: Try to merge (conflict happens)
git merge feature/new-db-layer
# CONFLICT (content): Merge conflict in src/user.js

# Step 2: Open the file and choose what to keep
# Option A: Keep your version
# Option B: Keep their version
# Option C: Combine both (most common!)

# After editing, the file should look like:
function getUser() {
    const cached = fetchFromCache(userId);
    return cached || fetchFromDatabase(userId);  // Combined both approaches
}

# Step 3: Mark as resolved and commit
git add src/user.js                         # Mark conflict as resolved
git commit -m "fix: resolve merge conflict in user service"

# If you want to ABORT the merge entirely
git merge --abort                           # Go back to before the merge
```

### Resolve Conflicts in VS Code

VS Code makes it easy with clickable buttons:

```
<<<<<<< HEAD
    return fetchFromCache(userId);
    ┌────────────────────────────────────┐
    │ Accept Current | Accept Incoming |  │
    │ Accept Both    | Compare Changes |  │
    └────────────────────────────────────┘
=======
    return fetchFromDatabase(userId);
>>>>>>> feature/new-db-layer
```

### Tips for Avoiding Conflicts

1. **Pull frequently:** `git pull origin develop` before starting work every morning
2. **Small PRs:** Merge features often — don't let branches live for weeks
3. **Communicate:** If two people need to edit the same file, coordinate
4. **Rebase before merge:** `git rebase develop` keeps your branch up to date

---

## 11 — Remote Repositories & Collaboration

Remote repositories are copies of your project stored on GitHub (or GitLab, Bitbucket). They enable team collaboration.

### Remote Commands

```bash
# View remotes
git remote -v                               # Show all remotes with URLs
# Output:
# origin  https://github.com/you/project.git (fetch)
# origin  https://github.com/you/project.git (push)

# Add a remote
git remote add origin https://github.com/you/project.git
git remote add upstream https://github.com/original/project.git  # For forks

# Push (send your commits to GitHub)
git push origin main                        # Push main branch
git push origin feature/login               # Push a feature branch
git push -u origin feature/login            # Push AND set tracking (-u = set upstream)
git push --force-with-lease origin feature   # Force push safely (after rebase)

# Pull (get latest changes from GitHub)
git pull origin main                        # Fetch + merge latest main
git pull --rebase origin main               # Fetch + rebase (cleaner history)

# Fetch (download changes WITHOUT merging — just look)
git fetch origin                            # Get latest from GitHub
git fetch --all                             # Fetch from all remotes
git log origin/main --oneline               # See what's new on remote
git diff main origin/main                   # Compare your main with remote main
```

> **`git pull` vs `git fetch`:**
> - `git fetch` = "Download the mail but don't open it" (safe, just look)
> - `git pull` = "Download and apply immediately" (fetch + merge in one step)

### Clone vs Fork

| Action | When to Use | Command |
|--------|------------|---------|
| **Clone** | You have access to the repo (team member) | `git clone URL` |
| **Fork** | You DON'T have access (open-source contribution) | Fork on GitHub → `git clone your-fork-URL` |

### Fork Workflow (Open Source Contribution)

```bash
# 1. Fork the repo on GitHub (click "Fork" button)

# 2. Clone YOUR fork
git clone https://github.com/YOUR-USERNAME/project.git
cd project

# 3. Add original repo as "upstream"
git remote add upstream https://github.com/ORIGINAL-OWNER/project.git

# 4. Create a feature branch
git checkout -b feature/my-improvement

# 5. Make changes, commit, push to YOUR fork
git add .
git commit -m "feat: add dark mode support"
git push origin feature/my-improvement

# 6. Create Pull Request on GitHub (from your fork to original repo)

# 7. Keep your fork up to date
git fetch upstream
git checkout main
git merge upstream/main
git push origin main
```

---

## 12 — Pull Requests & Code Review

A Pull Request (PR) is a request to merge your branch into another branch. It's where code review, discussion, and quality checks happen.

> **Think of it this way:** You've written an essay (your code changes). Before it gets published (merged to main), your editor (reviewer) reads it, suggests corrections, and gives approval.
>
> **Why PRs matter:**
> - Catch bugs BEFORE they reach production
> - Share knowledge — reviewers learn about parts of the code they didn't write
> - Maintain code quality standards
> - Create a documented history of WHY changes were made

### Creating a Pull Request

```bash
# Using GitHub CLI (gh)
gh pr create --base develop --title "feat: add user registration" \
  --body "## Changes
  - Added /api/register endpoint
  - Added input validation
  - Added unit tests
  
  ## Testing
  - Tested locally with Postman
  - All unit tests pass
  
  Closes #42"

# Or simply push and use the GitHub web UI
git push origin feature/user-registration
# Then go to GitHub → "Compare & Pull Request" button appears
```

### Reviewing a Pull Request

```bash
# Check out a PR locally to test it
gh pr checkout 42                   # Checkout PR #42

# Approve a PR
gh pr review 42 --approve --body "LGTM! Clean code, good test coverage."

# Request changes
gh pr review 42 --request-changes --body "Please add error handling for null inputs."

# Merge a PR
gh pr merge 42 --squash --delete-branch    # Squash merge and delete the branch
gh pr merge 42 --merge                      # Regular merge
gh pr merge 42 --rebase                     # Rebase merge
```

### Branch Protection Rules

> **Why protect branches?** Without protection, anyone can push directly to `main` — one mistake and production breaks. Protection rules enforce quality.

**Recommended rules for `main` branch:**
- Require at least 1 approval before merging
- Require all CI/CD checks to pass
- No direct pushes — all changes must come through PRs
- Require linear history (no merge commits)
- Require signed commits (optional, high security)

```bash
# Configure via GitHub CLI
gh api repos/OWNER/REPO/branches/main/protection \
  --method PUT \
  --field required_pull_request_reviews='{"required_approving_review_count":1}' \
  --field required_status_checks='{"strict":true,"contexts":["ci/build","ci/test"]}' \
  --field enforce_admins=true
```

---

## 13 — GitFlow — The Complete Branching Strategy

GitFlow is a structured branching model used by teams to manage releases, features, and hotfixes in a controlled way.

> **When to use GitFlow:** Projects with scheduled releases (e.g., every 2 weeks), mobile apps, enterprise software. If you deploy many times a day (like Netflix), use Trunk-Based Development instead (see note at the end).

### The Branch Structure

```
PRODUCTION (what users see)
│
▼
main ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━▶ Always stable, always deployable
│                                                            Tags: v1.0.0, v1.1.0, v2.0.0
│          ┌─── hotfix/critical-bug ──── merge to main + develop
│          │
│     ┌────┴─── release/v1.1.0 ──── final testing ──── merge to main + develop
│     │
▼     │
develop ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━▶ Integration branch
│     ▲         ▲          ▲
│     │         │          │
│  feature/  feature/   feature/         ← Developers work here
│  login     dashboard  payments
```

### Branch Purposes

| Branch | Created From | Merges Into | Purpose | Who Works Here |
|--------|-------------|-------------|---------|----------------|
| `main` | — | — | Production-ready code. Every commit is a release. | Nobody directly |
| `develop` | `main` | — | Integration of all features. "Next release" staging ground. | Nobody directly |
| `feature/*` | `develop` | `develop` | Individual features or tasks. | Developers |
| `release/*` | `develop` | `main` + `develop` | Prepare & test a release. Final bug fixes only. | QA + Release manager |
| `hotfix/*` | `main` | `main` + `develop` | Emergency production fixes. | On-call engineer |

### Full GitFlow Walkthrough

#### Step 1: Initial Setup

```bash
# Create the develop branch from main
git checkout main
git checkout -b develop
git push -u origin develop
```

#### Step 2: Feature Development

```bash
# Developer starts a new feature
git checkout develop
git pull origin develop                     # Always get latest
git checkout -b feature/user-authentication

# Work on the feature (multiple commits)
git add .
git commit -m "feat(auth): add login endpoint"
git add .
git commit -m "feat(auth): add JWT token validation"
git add .
git commit -m "test(auth): add login unit tests"

# Keep feature branch updated with develop
git fetch origin
git rebase origin/develop                   # Stay current with team's work

# Push feature branch
git push -u origin feature/user-authentication

# Create PR: feature/user-authentication → develop
gh pr create --base develop \
  --title "feat(auth): add user authentication" \
  --body "Adds login/register endpoints with JWT tokens"
```

#### Step 3: Code Review & Merge to Develop

```bash
# Reviewer reviews the PR on GitHub
# After approval:
gh pr merge --squash --delete-branch        # Squash merge into develop
```

#### Step 4: Release Preparation (feature → develop → release → staging/QA)

```bash
# When enough features are ready for release:
git checkout develop
git pull origin develop
git checkout -b release/v1.1.0

# On the release branch:
# - Only bug fixes, documentation, version bumps
# - NO new features!

# Update version number
echo "1.1.0" > VERSION
git add .
git commit -m "chore: bump version to 1.1.0"

# Fix a bug found during QA testing
git commit -m "fix: resolve date formatting in reports"

# Push release branch for QA/staging testing
git push -u origin release/v1.1.0
```

#### Step 5: Deploy to Staging / QA

```bash
# In your CI/CD pipeline (e.g., GitHub Actions):
# release/* branches auto-deploy to STAGING environment
# QA team tests on staging

# If QA finds a bug → fix it on the release branch
git checkout release/v1.1.0
git commit -m "fix: correct pagination offset"
git push origin release/v1.1.0
# Staging re-deploys automatically
```

#### Step 6: Merge Release to Production

```bash
# Release is tested and approved. Merge to main.
git checkout main
git pull origin main
git merge --no-ff release/v1.1.0            # Merge with a merge commit
git tag -a v1.1.0 -m "Release v1.1.0"      # Tag the release
git push origin main --tags                  # Push main + tag

# ALSO merge release back into develop (so develop gets the bug fixes too)
git checkout develop
git merge --no-ff release/v1.1.0
git push origin develop

# Delete the release branch
git branch -d release/v1.1.0
git push origin --delete release/v1.1.0
```

### The Full Flow Diagram

```
feature/login ─────┐
                    │ PR (squash merge)
feature/dashboard ──┤
                    ▼
                 develop ─────────┐
                                  │ Create release branch
                                  ▼
                            release/v1.1.0
                                  │
                                  │ Deploy to STAGING
                                  │ QA Testing
                                  │ Bug fixes only
                                  │
                    ┌─────────────┤
                    │             │
                    ▼             ▼
                 develop        main ──── TAG v1.1.0 ──── Deploy to PRODUCTION
                 (gets bug      
                  fixes too)    
```

### Environment Mapping

```
Branch              →    Environment        →    Who Has Access
─────────────────────────────────────────────────────────────────
feature/*           →    Developer's local   →    Individual developer
develop             →    DEV environment     →    All developers
release/*           →    STAGING / QA        →    QA team + developers
main                →    PRODUCTION          →    End users
hotfix/*            →    (tested locally)    →    On-call engineer
```

### Trunk-Based Development (Alternative)

> **When to use instead of GitFlow:** If your team deploys multiple times per day (continuous deployment), GitFlow's multiple branches add overhead. Trunk-based is simpler.

```
Trunk-Based:
main ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━▶ Deploy continuously
  ╲          ╱    ╲          ╱    ╲          ╱
   feature/a       feature/b       feature/c
   (short-lived)   (short-lived)   (short-lived)
   1-2 days max    1-2 days max    1-2 days max

Rules:
- Feature branches live < 2 days
- Everyone merges to main frequently
- Feature flags hide incomplete work
- CI/CD tests everything automatically
```

---

## 14 — Hotfix Workflow

A hotfix is an emergency fix applied directly to production when something breaks and can't wait for the next release.

> **Think of it this way:** Your building's water pipe burst at 3 AM. You don't start a renovation project — you call the emergency plumber. They fix ONLY the pipe, nothing else. That's a hotfix.
>
> **Key rules:**
> - Hotfix branches are created from `main` (not develop)
> - They contain ONLY the fix — no features, no cleanup
> - They are merged back into BOTH `main` AND `develop`

### Hotfix Workflow — Step by Step

```bash
# 🚨 ALERT: Users can't log in! Production is down!

# Step 1: Create hotfix branch from main
git checkout main
git pull origin main
git checkout -b hotfix/login-crash

# Step 2: Find and fix the bug
# ... edit the code ...
git add src/auth/login.js
git commit -m "fix(auth): handle null session token causing login crash

Closes #256
Root cause: Missing null check on session.token
Impact: All users unable to login since 02:15 UTC"

# Step 3: Test locally
npm test                                    # Run tests to verify fix

# Step 4: Push and create PR to main
git push -u origin hotfix/login-crash
gh pr create --base main \
  --title "hotfix: fix login crash (null session token)" \
  --body "🚨 **URGENT** — Production login is broken.

  **Root cause:** Null check missing on session.token after Redis cache expiry.
  **Impact:** All users unable to login.
  **Fix:** Added null check + fallback to DB session lookup.
  **Testing:** Unit tests added, manual QA verified."

# Step 5: Get emergency review + merge to main
# (Fast-track review for hotfixes — 1 senior approval)
gh pr merge --merge

# Step 6: Tag the hotfix release
git checkout main
git pull origin main
git tag -a v1.1.1 -m "Hotfix: fix login crash"
git push origin --tags

# Step 7: CRITICAL — Merge hotfix back into develop too!
git checkout develop
git pull origin develop
git merge hotfix/login-crash
git push origin develop

# Step 8: Clean up
git branch -d hotfix/login-crash
git push origin --delete hotfix/login-crash
```

### Hotfix in the branch diagram

```
main:    ━━━━ v1.1.0 ━━━━━━━━━━━━━━ v1.1.1 ━━━━━━━▶
                          ╲              ╱  ╲
                     hotfix/login-crash     ╲
                                             ╲
develop: ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ merge ━▶
         (also gets the fix)
```

> **Never forget Step 7!** If you don't merge the hotfix back into `develop`, the bug will REAPPEAR in the next release.

---

## 15 — Conventional Commits

Conventional Commits is a standardized format for commit messages. It makes history readable, enables automated changelogs, and drives automatic versioning.

> **Why bother with a format?** Compare these commit histories:
>
> **Bad (common in real teams):**
> ```
> fixed stuff
> WIP
> update
> more changes
> final fix
> this should work now
> ```
>
> **Good (conventional commits):**
> ```
> feat(auth): add Google OAuth login
> fix(api): handle timeout on /users endpoint
> docs(readme): update installation instructions
> test(auth): add unit tests for token refresh
> chore(deps): update lodash to 4.17.21
> ```
>
> Which one would you rather read at 3 AM when debugging a production issue?

### The Format

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

### Commit Types

| Type | When to Use | Triggers Version Bump? |
|------|------------|----------------------|
| `feat` | New feature for the user | MINOR (1.0.0 → 1.1.0) |
| `fix` | Bug fix | PATCH (1.0.0 → 1.0.1) |
| `docs` | Documentation only | No |
| `style` | Formatting, semicolons, no code change | No |
| `refactor` | Code change that doesn't add feature or fix bug | No |
| `perf` | Performance improvement | PATCH |
| `test` | Adding or updating tests | No |
| `chore` | Maintenance tasks (deps, configs) | No |
| `ci` | CI/CD pipeline changes | No |
| `build` | Build system changes | No |
| `BREAKING CHANGE` | Incompatible API change (in footer) | MAJOR (1.0.0 → 2.0.0) |

### Examples

```bash
# Simple feature
git commit -m "feat: add password reset endpoint"

# Feature with scope (which module)
git commit -m "feat(auth): add Google OAuth login"

# Bug fix
git commit -m "fix(api): handle null response from payment gateway"

# Bug fix with body (more details)
git commit -m "fix(auth): resolve session timeout on mobile devices

Users on iOS were being logged out after 5 minutes due to
background app refresh clearing the session cookie.

Increased cookie maxAge from 300s to 86400s and added
session refresh logic on app foreground event.

Closes #189"

# Breaking change
git commit -m "feat(api): change authentication to OAuth2

BREAKING CHANGE: /api/login no longer accepts username/password.
All clients must migrate to OAuth2 flow by v3.0.
See migration guide: docs/migration-v3.md"

# Chore (no user-facing change)
git commit -m "chore(deps): update express from 4.18 to 4.19"

# CI/CD change
git commit -m "ci: add staging deployment to GitHub Actions pipeline"
```

### Enforcing Conventional Commits (Git Hooks)

```bash
# Install commitlint + husky (Node.js projects)
npm install --save-dev @commitlint/cli @commitlint/config-conventional husky

# Setup husky
npx husky init

# Create commit-msg hook
echo 'npx commitlint --edit $1' > .husky/commit-msg

# Create commitlint config
cat > .commitlintrc.json << 'EOF'
{
  "extends": ["@commitlint/config-conventional"]
}
EOF

# Now invalid commits are BLOCKED:
git commit -m "fixed stuff"
# ⧗   input: fixed stuff
# ✖   subject may not be empty [subject-empty]
# ✖   type may not be empty [type-empty]

git commit -m "feat: add login page"
# ✔   All good!
```

### For Non-Node.js Projects (Shell Script Hook)

```bash
#!/bin/bash
# .git/hooks/commit-msg

commit_msg=$(cat "$1")
pattern="^(feat|fix|docs|style|refactor|perf|test|chore|ci|build)(\(.+\))?: .{1,72}$"

if ! echo "$commit_msg" | head -1 | grep -qE "$pattern"; then
    echo "❌ Invalid commit message format!"
    echo ""
    echo "Expected: <type>(<scope>): <description>"
    echo "Example:  feat(auth): add login endpoint"
    echo ""
    echo "Types: feat, fix, docs, style, refactor, perf, test, chore, ci, build"
    exit 1
fi
```

---

## 16 — Tagging & Semantic Versioning

Tags mark specific points in history — typically releases. Semantic Versioning (SemVer) gives those tags a meaningful numbering system.

### Semantic Versioning Format

```
v MAJOR . MINOR . PATCH
  │       │       │
  │       │       └── Bug fixes (backward compatible)
  │       │            1.0.0 → 1.0.1
  │       │
  │       └──── New features (backward compatible)
  │              1.0.0 → 1.1.0
  │
  └──────── Breaking changes (NOT backward compatible)
             1.0.0 → 2.0.0
```

> **Simple rules:**
> - Fixed a bug? Bump PATCH: `v1.0.0` → `v1.0.1`
> - Added a feature (existing stuff still works)? Bump MINOR: `v1.0.0` → `v1.1.0`
> - Changed something that breaks existing users/APIs? Bump MAJOR: `v1.0.0` → `v2.0.0`

### Pre-Release Labels

```
v1.0.0-alpha.1     → Very early, unstable, internal testing only
v1.0.0-beta.1      → Feature-complete, external testers
v1.0.0-rc.1        → Release Candidate — final testing before go-live
v1.0.0             → Stable release
```

### Tag Commands

```bash
# Create tags
git tag v1.0.0                              # Lightweight tag (just a pointer)
git tag -a v1.0.0 -m "Release v1.0.0"      # Annotated tag (recommended — has message)
git tag -a v1.0.0 -m "Release v1.0.0

Features:
- User authentication
- Dashboard
- Payment integration

Bug fixes:
- Fixed session timeout (#189)
- Fixed pagination offset (#201)"

# List tags
git tag                                     # List all tags
git tag -l "v1.*"                           # List tags matching pattern

# Push tags to GitHub
git push origin v1.0.0                      # Push specific tag
git push origin --tags                      # Push ALL tags

# Delete a tag
git tag -d v1.0.0                           # Delete local tag
git push origin --delete v1.0.0             # Delete remote tag

# Tag an older commit (retroactively)
git tag -a v0.9.0 a1b2c3d -m "Retroactive tag for v0.9.0"

# See tag details
git show v1.0.0                             # Show tag info + the commit it points to
```

### Automated Releases with Release Please

```yaml
# .github/workflows/release.yml
name: Release
on:
  push:
    branches: [main]

permissions:
  contents: write
  pull-requests: write

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: google-github-actions/release-please-action@v4
        with:
          release-type: node
```

> Release Please reads your conventional commits and automatically:
> - Creates a release PR with changelog
> - Bumps the version based on commit types (`feat` → minor, `fix` → patch)
> - Creates a GitHub Release with release notes when merged

---

## 17 — Advanced Git Commands

### `git bisect` — Find Which Commit Introduced a Bug

> **Think of it this way:** "The app worked 2 weeks ago but it's broken now. There are 50 commits in between. Which one broke it?" Instead of checking all 50, `git bisect` uses binary search (check the middle first) to find the bad commit in about 6 steps.

```bash
git bisect start
git bisect bad                          # Current commit is broken
git bisect good v1.0.0                  # This older version was working

# Git checks out a middle commit — you test it
# If it works:
git bisect good
# If it's broken:
git bisect bad

# Git narrows down and checks out another commit...
# Repeat until it finds the EXACT commit that broke things

# When done:
# "abc1234 is the first bad commit"
git bisect reset                        # Go back to normal
```

### `git log` — Advanced History Exploration

```bash
# Pretty format
git log --oneline --graph --all --decorate
# Shows a visual branch tree with all branches

# Search commits
git log --grep="payment"                   # Find commits mentioning "payment"
git log -S "functionName"                  # Find commits that added/removed "functionName"
git log -- src/auth/                       # Commits affecting files in src/auth/
git log --author="John" --since="2 weeks ago" --oneline

# Show files changed in each commit
git log --stat                             # Files changed + lines added/removed
git log --name-only                        # Just file names
```

### `git diff` — Compare Anything

```bash
git diff                                   # Uncommitted changes
git diff --staged                          # Staged changes
git diff main feature/login                # Difference between two branches
git diff v1.0.0 v1.1.0                    # Difference between two tags
git diff HEAD~5                            # Changes in last 5 commits
git diff --stat main feature/login         # Summary (files + line counts)
```

### `git blame` — Find Who Changed What

```bash
git blame src/auth/login.js                # Who wrote each line
git blame -L 40,60 src/auth/login.js       # Blame only lines 40-60
git blame -w src/auth/login.js             # Ignore whitespace changes
```

### `git clean` — Remove Untracked Files

```bash
git clean -n                               # Preview what would be deleted (dry run)
git clean -f                               # Delete untracked files
git clean -fd                              # Delete untracked files AND directories
git clean -fX                              # Delete only ignored files (.gitignore entries)
```

### `git worktree` — Multiple Working Directories

```bash
# Work on a hotfix without switching branches (no stashing needed!)
git worktree add ../hotfix-workspace hotfix/critical-bug
cd ../hotfix-workspace
# Work on the hotfix here while your main work stays untouched
# When done:
git worktree remove ../hotfix-workspace
```

---

## 18 — .gitignore — Hiding Files from Git

`.gitignore` tells Git which files to ignore — things that shouldn't be tracked or pushed to GitHub.

> **What to ignore:** Build outputs, dependencies, secrets, OS files, IDE settings, logs.

### Common .gitignore Patterns

```gitignore
# --- Dependencies ---
node_modules/
vendor/
.venv/
__pycache__/

# --- Build outputs ---
dist/
build/
*.min.js
*.min.css

# --- Environment & Secrets (NEVER commit these!) ---
.env
.env.local
.env.production
*.pem
*.key
credentials.json
secrets.yml

# --- IDE & Editor ---
.vscode/
.idea/
*.swp
*.swo
*~

# --- OS files ---
.DS_Store
Thumbs.db
desktop.ini

# --- Logs ---
*.log
logs/
npm-debug.log*

# --- Terraform ---
.terraform/
*.tfstate
*.tfstate.backup
*.tfvars

# --- Docker ---
docker-compose.override.yml

# --- Coverage & Testing ---
coverage/
.nyc_output/
htmlcov/
```

### .gitignore Commands

```bash
# If a file is already tracked and you add it to .gitignore:
# .gitignore won't work until you remove it from tracking
git rm --cached filename.txt                # Stop tracking (keep the local file)
git rm --cached -r node_modules/            # Stop tracking a whole folder
git commit -m "chore: remove node_modules from tracking"

# Check what Git is ignoring
git status --ignored                        # Show ignored files
git check-ignore -v filename.txt            # Show WHICH .gitignore rule is ignoring a file
```

---

## 19 — Git Aliases — Time-Saving Shortcuts

Aliases let you create short commands for long Git commands you use frequently.

```bash
# Set up aliases
git config --global alias.st "status"
git config --global alias.co "checkout"
git config --global alias.br "branch"
git config --global alias.ci "commit"
git config --global alias.cm "commit -m"
git config --global alias.sw "switch"
git config --global alias.last "log -1 HEAD"
git config --global alias.lg "log --oneline --graph --all --decorate"
git config --global alias.unstage "restore --staged"
git config --global alias.undo "reset --soft HEAD~1"
git config --global alias.amend "commit --amend --no-edit"
git config --global alias.pushf "push --force-with-lease"
git config --global alias.please "push --force-with-lease"

# Now you can use:
git st                  # Instead of: git status
git co main             # Instead of: git checkout main
git cm "feat: login"    # Instead of: git commit -m "feat: login"
git lg                  # Beautiful visual log
git undo                # Undo last commit (keep changes)
git amend               # Add forgotten changes to last commit
```

---

## 20 — Real-World Workflow — Day in the Life

Here's what a typical day looks like for a DevOps / Software Engineer using Git:

### Morning — Start Your Day

```bash
# Pull latest changes from develop
git checkout develop
git pull origin develop

# Create a feature branch for today's task
git checkout -b feature/JIRA-456-user-profile-api

# Check your task on Jira/GitHub Issues
gh issue view 456
```

### Working — During the Day

```bash
# Make changes, commit frequently with good messages
git add src/api/profile.js
git commit -m "feat(api): add GET /user/profile endpoint"

git add src/api/profile.js src/middleware/auth.js
git commit -m "feat(api): add authentication to profile endpoint"

git add tests/profile.test.js
git commit -m "test(api): add unit tests for profile endpoint"

# Push your branch periodically (backup + visibility)
git push -u origin feature/JIRA-456-user-profile-api
```

### Interrupted — Urgent Request

```bash
# Stash your current work
git stash save "WIP: profile API validation"

# Switch to fix the urgent issue
git checkout main
git checkout -b hotfix/api-rate-limit
# ... fix it ...
git commit -m "fix(api): increase rate limit to 1000 req/min"
git push origin hotfix/api-rate-limit
gh pr create --base main --title "hotfix: API rate limit too low"

# Go back to your feature
git checkout feature/JIRA-456-user-profile-api
git stash pop
```

### Afternoon — Before Creating PR

```bash
# Update your branch with latest develop
git fetch origin
git rebase origin/develop

# If conflicts, resolve them
# ... fix files ...
git add .
git rebase --continue

# Clean up messy commits
git rebase -i HEAD~5                # Squash WIP commits into clean ones

# Push (force needed after rebase)
git push --force-with-lease origin feature/JIRA-456-user-profile-api
```

### Evening — Create PR and Go Home

```bash
# Create the Pull Request
gh pr create --base develop \
  --title "feat(api): add user profile endpoint" \
  --body "## Summary
Adds GET /user/profile endpoint with JWT authentication.

## Changes
- New profile endpoint with field selection
- Auth middleware integration
- 95% test coverage

## Testing
- Unit tests: ✅
- Integration tests: ✅
- Manual testing: ✅

Closes #456"

# Check CI/CD status
gh pr checks 789                    # See if CI passed
```

### Next Day — Address Review Feedback

```bash
# Reviewer left comments
git checkout feature/JIRA-456-user-profile-api
# ... make requested changes ...
git add .
git commit -m "refactor(api): address PR feedback — add input validation"
git push origin feature/JIRA-456-user-profile-api

# PR is approved → Squash merge into develop
gh pr merge --squash --delete-branch
```

---

## 21 — Quick Reference Cheat Sheet

### Setup & Config
| Command | Purpose |
|---------|---------|
| `git config --global user.name "Name"` | Set your name |
| `git config --global user.email "email"` | Set your email |
| `git init` | Create new repository |
| `git clone URL` | Clone existing repository |

### Daily Commands
| Command | Purpose |
|---------|---------|
| `git status` | Check what's changed |
| `git add .` | Stage all changes |
| `git commit -m "msg"` | Save a snapshot |
| `git push origin branch` | Send to GitHub |
| `git pull origin branch` | Get latest from GitHub |
| `git log --oneline` | View history |

### Branching
| Command | Purpose |
|---------|---------|
| `git branch` | List branches |
| `git checkout -b name` | Create + switch to branch |
| `git switch name` | Switch to branch |
| `git merge branch` | Merge branch into current |
| `git branch -d name` | Delete branch |

### Undoing
| Command | Purpose |
|---------|---------|
| `git restore file` | Discard uncommitted changes |
| `git restore --staged file` | Unstage a file |
| `git revert hash` | Safely undo a commit |
| `git reset --soft HEAD~1` | Undo commit, keep changes staged |
| `git reset --hard HEAD~1` | Undo commit + delete changes |
| `git stash` | Save work temporarily |
| `git stash pop` | Restore saved work |

### Advanced
| Command | Purpose |
|---------|---------|
| `git cherry-pick hash` | Copy a specific commit |
| `git rebase main` | Replay commits on top of main |
| `git rebase -i HEAD~N` | Interactive edit last N commits |
| `git bisect start` | Find bug-introducing commit |
| `git reflog` | Recover from any mistake |
| `git blame file` | See who changed each line |

### Collaboration
| Command | Purpose |
|---------|---------|
| `gh pr create --base develop` | Create pull request |
| `gh pr merge --squash` | Squash merge PR |
| `gh pr review N --approve` | Approve a PR |
| `git tag -a v1.0.0 -m "msg"` | Create release tag |
| `git push origin --tags` | Push tags to GitHub |

---

## GitFlow — Visual Summary

```
                    Feature branches                    Release              Production
                    (developers work)            (QA/Staging testing)     (users see this)
                    
feature/login ─────────┐
                        │  merge
feature/dashboard ──────┤  to
                        │  develop
feature/payments ───────┘
                        │
                        ▼
                     develop ──────────▶ release/v1.0 ──────────▶ main ─── v1.0.0
                                          │     ▲                  │
                                          │     │ bug fixes        │
                                          └─────┘                  │
                                                                   │
                     develop ◀──────── (merge back) ◀──────────────┘
                        │
                        │ (also receives hotfixes)
                        │
                        ▼
    hotfix/crash ─────────────────────────────────────────────────▶ main ─── v1.0.1
                                                                   │
                     develop ◀──────── (merge back) ◀──────────────┘
```

---

> **Learning path:**
> 1. **Beginner:** Sections 1-5 (setup, commits, branches, merging)
> 2. **Intermediate:** Sections 6-12 (rebase, cherry-pick, stash, PRs)
> 3. **Advanced:** Sections 13-17 (GitFlow, hotfix, conventional commits, bisect)
> 4. **Practice:** Follow Section 20 (Day in the Life) on a real project
