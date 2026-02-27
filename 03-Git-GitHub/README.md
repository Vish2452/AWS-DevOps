# Module 3 — Git & GitHub (1 Week)

> **Objective:** Master Git workflows, branching strategies, semantic versioning, and collaborative development patterns used in production teams.

---

## 🌍 Real-World Analogy: Git is Like Google Docs + Time Machine

```
📝 WITHOUT GIT (The Old Way):
   project_final.zip
   project_final_v2.zip
   project_final_v2_FIXED.zip
   project_final_v2_FIXED_ACTUALLY_FINAL.zip   ← Sound familiar? 😅

📂 WITH GIT:
   One folder. Clean history. Every change tracked.
   "Who changed this line?" → git blame → "Bob, on Jan 15, because of bug #42"
   "I broke everything!" → git revert → Back to working version in 5 seconds
```

### Git Explained Like a Notebook

| Git Concept | Real-World Analogy |
|------------|-------------------|
| **Repository** | A notebook with all your project's pages |
| **Commit** | Taking a **photo** of your notebook page (snapshot in time) |
| **Branch** | **Sticky note** experiments — try ideas without messing up the main notebook |
| **Merge** | Taking the good ideas from sticky notes and writing them in the main notebook |
| **Pull Request** | Asking your **teacher to review** before you write in the main notebook |
| **Clone** | **Photocopying** someone's entire notebook to work on your own copy |
| **Push** | Sending your updated pages back to the shared notebook |
| **Conflict** | Two people edited the **same sentence** differently — someone must decide which version to keep |
| **Stash** | Putting your current work in a **drawer** temporarily to do something urgent |
| **Revert** | Using **white-out** to undo a specific change (but keeping the history) |
| **Reset** | **Ripping out pages** — careful, this can lose work! |

### Branching = Highway System

```
main (Highway)     ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━▶ Production
                        ╲                    ╱
feature/login            ╲──── Exit ────────╱  ← Merge back after review
(Side Road)               Build the feature

                              ╲          ╱
hotfix/crash-fix               ╲── Emergency repair ──╱  ← Quick fix
(Emergency Lane)                Goes directly to main
```

> **Real Example:** At Netflix, thousands of engineers work on the same codebase. Without Git branches, they'd overwrite each other's code constantly. Each engineer works on their own branch (side road), and only merges to main (highway) after peer review.

---

## Topics

### Git Fundamentals
- Distributed vs Centralized VCS
- Git internals: objects (blob, tree, commit, tag), refs, HEAD, index
- Core commands: `init, clone, add, commit, push, pull, fetch, log, diff, status, branch, checkout, switch`

### Branching Strategies
- **Git Flow** — `main`, `develop`, `feature/*`, `release/*`, `hotfix/*`
- **Trunk-based development** — modern alternative for CI/CD
- When to use each approach

### Advanced Git
- `git stash` — save, pop, list, drop, apply
- `git revert` vs `git reset` (soft/mixed/hard)
- `git merge` vs `git rebase` — when to use each
- `git cherry-pick`
- `git bisect` — find which commit introduced a bug
- `git reflog` — recovery from mistakes

### GitHub Collaboration
- Pull Requests — code review, approval rules, branch protection
- Resolving merge conflicts — manual and with VS Code
- Forking workflow for open-source contributions
- GitHub CLI (`gh`) — PR creation, issue management
- Signed commits with GPG
- `.gitignore`, `.gitattributes`
- Git hooks — pre-commit, pre-push, commit-msg (with Husky)

### Semantic Versioning (SemVer)
- **Format:** `MAJOR.MINOR.PATCH` → e.g., `v2.4.1`
- Pre-release labels: `v1.0.0-alpha.1`, `v1.0.0-beta.2`, `v1.0.0-rc.1`
- Conventional Commits → automated version bumps
- Tools: semantic-release, Release Please, GitVersion

---

## Real-Time Project: Team GitFlow Simulation

**[📁 Project Folder →](project-team-gitflow/)**

### What You Build
- GitHub organization with 3 repos (frontend, backend, infra)
- Branch protection rules, required reviews, status checks
- Feature development → PR → code review → merge → release tagging
- Semantic versioning with conventional commits + Release Please
- Auto-generated changelogs and GitHub Releases
- Conflict resolution and hotfix flow practice

### Deliverables
- Documented branching strategy
- Working repo with SemVer releases and auto-changelogs
- Git hooks configured for commit message enforcement

---

## Interview Questions
1. Explain the difference between `git merge` and `git rebase`
2. What is Git Flow? When would you use trunk-based development instead?
3. How do you resolve a merge conflict?
4. What does `git reset --hard HEAD~3` do? How to recover?
5. Explain semantic versioning. When do you bump MAJOR?
6. What are conventional commits and how do they drive releases?
7. How do you set up branch protection rules?
8. What is `git cherry-pick` and when to use it?
9. Difference between `^1.2.3`, `~1.2.3`, and `>=1.2.3 <2.0.0`?
10. How would you implement a release pipeline with automatic changelog?
