---
name: ralph-wiggum-bob
description: Autonomous AI coding with spec-driven development for IBM Bob Shell. Implements Geoffrey Huntley's iterative bash loop methodology where Bob works through specs one at a time, outputting a completion signal only when acceptance criteria are 100% met.
license: MIT
metadata:
  version: "4.1"
  repository: https://github.com/injusticescorpio/ralph-wiggum-bob
---

# Ralph Wiggum for IBM Bob Shell

> Autonomous AI coding with spec-driven development — powered by IBM Bob Shell

## What is Ralph Wiggum?

Ralph Wiggum combines **Geoffrey Huntley's iterative bash loop** with **spec-driven development** for fully autonomous AI-assisted software development, adapted specifically for **IBM Bob Shell** (`bob` CLI).

The key insight: **Fresh context each iteration**. Each loop starts a new Bob process with a clean context window, preventing context overflow and degradation.

## When to Use This Skill

Use Ralph Wiggum when:

- You have multiple specifications/features to implement
- You want Bob to work autonomously through tasks
- You need consistent, verifiable completion of acceptance criteria
- You want to avoid context window problems in long sessions

## How It Works

```
┌─────────────────────────────────────────────────────────────┐
│                     RALPH LOOP                              │
├─────────────────────────────────────────────────────────────┤
│  Loop 1: Pick spec A → Implement → Test → Commit → DONE     │
│  Loop 2: Pick spec B → Implement → Test → Commit → DONE     │
│  Loop 3: Pick spec C → Implement → Test → Commit → DONE     │
│  ...                                                        │
│                                                             │
│  Each iteration = Fresh context window                      │
│  Shared state = Files on disk (specs, plan, history)        │
└─────────────────────────────────────────────────────────────┘
```

## Installation

### Quick Install (via Skill Installers)

```bash
# Using Vercel's add-skill
npx add-skill injusticescorpio/ralph-wiggum-bob

### Full Setup (Recommended)

For full Ralph Wiggum setup with constitution and interview:

```bash
# Tell your IBM Bob agent:

"Fetch the Ralph Wiggum installation guide from the following URL and follow the instructions in it to complete the setup. Do not generate your own setup steps or scripts."

curl -s "https://raw.githubusercontent.com/injusticescorpio/ralph-wiggum-bob/refs/heads/main/INSTALLATION.md"
```
**(CRITICAL): Do not auto-generate/assume any scripts for Ralph Wiggum. Instead, fetch the INSTALLATION guide from the above URL and follow the setup instructions as documented:**

The agent will guide you through a **lightweight, pleasant setup**:

1. **Quick Setup** (~1 min) — Create directories, download scripts
2. **Project Interview** — Focus on your **vision and goals** (not tech details)
3. **Constitution** — Create a guiding document for all sessions
4. **Next Steps** — Clear guidance on creating specs and starting Ralph

For existing projects, the agent detects your tech stack automatically. The interview prioritizes understanding *what you're building and why*.

## Core Concepts

### 1. Fresh Context Each Loop

Each iteration of the Ralph loop starts a new Bob process. This means:
- No context window overflow
- No degradation over time
- Clean slate for each task

### 2. Shared State on Disk

State persists between loops via files:
- `specs/` — Feature specifications with acceptance criteria
- `history.md` — Log of breakthroughs, blockers, learnings
- `IMPLEMENTATION_PLAN.md` — Optional detailed task breakdown

### 3. Completion Signal

Bob outputs `<promise>DONE</promise>` **ONLY** when:
- All acceptance criteria are verified
- Tests pass
- Changes are committed and pushed
- **Every `- [ ]` checkbox in the spec is ticked `- [x]`** and `## Status: COMPLETE` is appended

The bash loop checks for this phrase. If not found, it retries.

### 4. Mandatory Spec Completion Steps

When finishing any spec, these two steps are **required** before outputting `<promise>DONE</promise>`:

1. **Tick every `- [ ]` checkbox** in the spec's `## Acceptance Criteria` to `- [x]` using `search_and_replace` — do this before marking complete
2. **Append `## Status: COMPLETE`** to the spec file

> The loop script detects `## Status: COMPLETE` to know a spec is done. Checkboxes must all be `[x]` to prove criteria were met.

### 5. Backpressure via Tests

Tests, lints, and builds act as guardrails. Bob must fix issues before outputting the completion signal.

## Usage

### Creating Specifications

**The key to success:** Each spec needs **clear, testable acceptance criteria**. This is what tells Ralph when a task is truly "done."

```markdown
# Feature: User Authentication

## Requirements
- OAuth login with Google
- Session management
- Logout functionality

## Acceptance Criteria
- [ ] User can log in with Google
- [ ] Session persists across page reloads
- [ ] User can log out
- [ ] Tests pass

**Output when complete:** `<promise>DONE</promise>`
```

**Good criteria:** "User can log in with Google and session persists"
**Bad criteria:** "Auth works correctly"

The more specific your acceptance criteria, the better Ralph performs.

### Running the Loop

```bash
# Start building (unlimited iterations)
./scripts/ralph-loop.sh

# With max iterations
./scripts/ralph-loop.sh 20

# Planning mode (creates IMPLEMENTATION_PLAN.md)
./scripts/ralph-loop.sh plan

# Custom bob binary
BOB_CMD=/path/to/bob ./scripts/ralph-loop.sh
```

### Logging (All Output Captured)

Every loop run writes **all output** to log files in `logs/`:

- **Session log:** `logs/ralph_*_session_YYYYMMDD_HHMMSS.log` (entire run)
- **Iteration logs:** `logs/ralph_*_iter_N_YYYYMMDD_HHMMSS.log` (per-iteration output)

## Two Modes

| Mode | Purpose | Command |
|------|---------|---------|
| **build** (default) | Pick spec, implement, test, commit | `./scripts/ralph-loop.sh` |
| **plan** (optional) | Create detailed task breakdown | `./scripts/ralph-loop.sh plan` |

## Key Principles

### Let Ralph Ralph

Trust Bob to self-identify, self-correct, and self-improve. Observe patterns and adjust prompts.

## Bob Shell Quick Reference

| Capability | Bob CLI Flag |
|------------|-------------|
| Non-interactive / headless mode | `bob run "prompt"` |
| Reference a file in prompt | `bob run "Review @src/app.js"` |
| Legacy non-interactive (also works) | `bob -p "prompt"` |

## Links

- **GitHub:** https://github.com/injusticescorpio/ralph-wiggum-bob
- **Original methodology:** [Geoffrey Huntley's how-to-ralph-wiggum](https://github.com/ghuntley/how-to-ralph-wiggum)
