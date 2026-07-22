# Ralph Wiggum for IBM Bob Shell

> **You are an AI coding agent running inside IBM Bob Shell.**
> Follow these instructions to set up Ralph Wiggum for this project.
>
> **Actually execute these steps** — don't just describe them.

---

## Overview: What You'll Do

1. **Quick Setup** — Create directories and copy scripts (1 minute)
2. **Project Interview** — Learn about the user's project vision (3–5 minutes)
3. **Constitution** — Create the project's guiding document
4. **Next Steps** — Explain how to create specs and start Ralph

The goal: make setup feel **lightweight and professional**. Focus on understanding the *project*, not interrogating about technical minutiae.

---

## Phase 1: Create Directory Structure

```bash
mkdir -p .specify/memory specs scripts/lib logs history completion_log
```

---

## Phase 2: Download Scripts

Fetch the scripts directly from GitHub:

```bash
curl -fsSL https://raw.githubusercontent.com/injusticescorpio/ralph-wiggum-bob/refs/heads/main/scripts/ralph-loop.sh \
  -o scripts/ralph-loop.sh

curl -fsSL https://raw.githubusercontent.com/injusticescorpio/ralph-wiggum-bob/refs/heads/main/scripts/lib/spec_queue.sh \
  -o scripts/lib/spec_queue.sh

chmod +x scripts/ralph-loop.sh
```

> **Why only one loop script?**
> The original Ralph Wiggum had separate scripts per AI agent (Claude, Codex, Gemini, Copilot).
> This repo is Bob-specific — `ralph-loop.sh` is pre-configured to call `bob`.
> You can override the binary with `BOB_CMD=/path/to/bob ./scripts/ralph-loop.sh`.

---

## Phase 3: Accept the IBM Bob License (First Run Only)

Bob Shell requires license acceptance before it can run non-interactively.
If this has not been done yet, run:

```bash
bob --accept-license -p "Hello"
```

> **Note:** Non-interactive mode (used by the loop) requires **API key authentication**.
> Interactive IBMid login is not supported for scripted use.
> Confirm that `~/.bob/settings.json` or the environment has a valid API key configured.

---

## Phase 4: Project Interview

### Introduction

Start with a brief, warm introduction:

> "I'll ask a few quick questions to understand your project. This creates a **constitution** — a short document that keeps me aligned with your goals across every future session.
>
> Don't worry about getting everything perfect — we can always refine it later."

### The Questions

Present these conversationally, one at a time.

---

#### 1. Project Name
> "What's the name of your project?"

---

#### 2. Project Vision *(most important)*

> "Tell me about your project — what is it, what problem does it solve, who is it for?
>
> This is the most important question. The more context you share, the better I can help build it."

A few sentences to a paragraph is ideal. Encourage the user to be expansive here.

---

#### 3. Core Principles

> "What 2–3 principles should guide development?
>
> Examples: 'User experience first', 'Keep it simple', 'Security above all', 'Move fast', 'Quality over speed'"

If the user is unsure, offer to suggest principles based on what they described.

---

#### 4. Technical Stack *(optional)*

> "What's the tech stack? Or should I figure it out from the codebase?"

For existing projects, inspect the codebase yourself — don't pressure the user.

---

#### 5. Autonomy Settings

> "Two quick settings:
>
> **YOLO Mode** *(recommended)*: Bob executes commands and modifies files without asking each time. Maps to `bob --yolo`.
>
> **Git Autonomy** *(recommended)*: Commit and push automatically after each completed spec.
>
> Enable both? (yes/no)"

Default to YES if the user seems agreeable.

---

#### 6. Completion Logs

> "Should I keep a log of every completed spec in `completion_log/`? (yes/no)"

Default to YES — it costs nothing and gives a useful audit trail.

---

### Interview Complete

> "That's all I need. Setting up your project now..."

---

## Phase 5: Create the Constitution

Create `.specify/memory/constitution.md` using the answers from the interview.

Keep it **concise** — Bob reads this at the start of every iteration.

**Template** (fill in bracketed values; include optional sections only if the user opted in):

```markdown
# {PROJECT_NAME} Constitution

> {PROJECT_VISION}

---

## Context Detection

**Ralph Loop Mode** (started by `./scripts/ralph-loop.sh`):
- Pick highest priority incomplete spec from `specs/`
- Implement, test, commit, push
- Output `<promise>DONE</promise>` only when 100% complete
- Output `<promise>ALL_DONE</promise>` when no work remains

**Interactive Mode** (normal Bob Shell session):
- Be helpful, guide decisions, create specs

---

## Core Principles

{List the user's principles, one per line}

---

## Technical Stack

{List or "Detected from codebase"}

---

## Autonomy

YOLO Mode: {ENABLED/DISABLED}
Git Autonomy: {ENABLED/DISABLED}

---

## Specs

Specs live in `specs/` as markdown files. Pick the highest priority incomplete spec
(lower number = higher priority). A spec is incomplete if it lacks `## Status: COMPLETE`.

Spec template: https://raw.githubusercontent.com/github/spec-kit/refs/heads/main/templates/spec-template.md

When all specs are complete, re-verify a random one before signaling done.

---

## NR_OF_TRIES

Track attempts per spec via `<!-- NR_OF_TRIES: N -->` at the bottom of the spec file.
Increment each attempt. At 10+, the spec is too hard — split it into smaller specs.

---

## History

Append a 1-line summary to `history.md` after each spec completion. For details, create
`history/YYYY-MM-DD--spec-name.md` with lessons learned, decisions made, and issues
encountered. Check history before starting work on any spec.

---

## Completion Signal

All acceptance criteria verified, tests pass, changes committed and pushed →
output `<promise>DONE</promise>`. Never output this until truly complete.
```

### Optional Constitution Section

#### If Completion Logs: YES

Add this section to the constitution:

```markdown
---

## Completion Logs

After each spec, create `completion_log/YYYY-MM-DD--HH-MM-SS--spec-name.md`
with a brief summary of what was done.
```

---

## Phase 6: Create Agent Entry Files

### AGENTS.md (project root)

Bob Shell loads `AGENTS.md` automatically at startup (both interactive and non-interactive).
This file simply points Bob at the constitution.

```markdown
# Agent Instructions

**Read:** `.specify/memory/constitution.md`

That file is your source of truth for this project.
```

Create it:

```bash
cat > AGENTS.md << 'EOF'
# Agent Instructions

**Read:** `.specify/memory/constitution.md`

That file is your source of truth for this project.
EOF
```

> **Bob Shell context file hierarchy:**
> 1. `~/.bob/AGENTS.md` — global instructions (all projects)
> 2. `AGENTS.md` in the project root — picked up automatically
> 3. `AGENTS.md` in subdirectories — for component-specific instructions
>
> You can also configure a custom context filename in `.bob/settings.json`:
> ```json
> { "context": { "fileName": ["AGENTS.md", "CONTEXT.md"] } }
> ```

---

## Phase 7: Explain Next Steps

> **Ralph Wiggum is ready for IBM Bob Shell!**
>
> **To create a spec:** Describe what you want built. I'll create a spec file in `specs/` with acceptance criteria.
>
> **To start the loop:** `./scripts/ralph-loop.sh`
>
> Bob picks the highest-priority incomplete spec, implements it, verifies acceptance criteria, commits, pushes, and moves to the next — all autonomously.

### Commands

| Task | Command |
|------|---------|
| Start building (unlimited) | `./scripts/ralph-loop.sh` |
| Start building (max 20 loops) | `./scripts/ralph-loop.sh 20` |
| Planning mode (creates IMPLEMENTATION_PLAN.md) | `./scripts/ralph-loop.sh plan` |
| Custom bob binary | `BOB_CMD=/path/to/bob ./scripts/ralph-loop.sh` |

### How the loop works under the hood

```
┌─────────────────────────────────────────────┐
│  ralph-loop.sh                              │
│                                             │
│  while true:                                │
│    cat PROMPT_build.md | bob -p --yolo      │  ← non-interactive Bob call
│    if output contains <promise>DONE</promise>│
│      → continue to next spec                │
│    else                                     │
│      → retry (acceptance criteria not met)  │
└─────────────────────────────────────────────┘
```

Bob reads `AGENTS.md` → loads `constitution.md` → knows the full workflow.
The loop script never needs updating; all project logic lives in the constitution.

---

## Bob Shell Quick Reference

| Capability | Bob CLI Flag |
|------------|-------------|
| Non-interactive mode | `bob -p "prompt"` or `cat prompt.txt \| bob` |
| Auto-approve all tools | `bob --yolo` |
| Accept license (first run) | `bob --accept-license -p "Hello"` |
| Reference a file in prompt | `bob -p "Review @src/app.js"` |
| Hide intermediary output | `bob --hide-intermediary-output` |

> **Note:** `--yolo` in Bob Shell auto-approves file writes and shell commands but **never** operates outside the directory where Bob was started.

Ready to create your first specification?
