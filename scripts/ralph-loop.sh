#!/bin/bash
#
# Ralph Loop for IBM Bob Shell
#
# Based on Geoffrey Huntley's Ralph Wiggum methodology:
# https://github.com/ghuntley/how-to-ralph-wiggum
#
# Adapted for IBM Bob Shell (bob CLI) instead of Claude Code.
#
# Key principles:
# - Each iteration picks ONE task/spec to work on
# - Bob works until acceptance criteria are met
# - Only outputs <promise>DONE</promise> when truly complete
# - Bash loop checks for magic phrase before continuing
# - Fresh context window each iteration
#
# Work sources (in priority order):
# 1. IMPLEMENTATION_PLAN.md (if exists) - pick highest priority task
# 2. specs/ folder - pick highest priority incomplete spec
#
# Usage:
#   ./scripts/ralph-loop.sh              # Build mode (unlimited)
#   ./scripts/ralph-loop.sh 20           # Build mode (max 20 iterations)
#   ./scripts/ralph-loop.sh plan         # Planning mode (creates IMPLEMENTATION_PLAN.md)
#
# Prerequisites:
#   - bob CLI installed and authenticated (run `bob` once interactively to accept license)
#   - API key authentication configured (required for non-interactive mode)
#   - Run from the project root directory
#

set -e
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LOG_DIR="$PROJECT_DIR/logs"
CONSTITUTION="$PROJECT_DIR/.specify/memory/constitution.md"

# Configuration
MAX_ITERATIONS=0  # 0 = unlimited
MODE="build"
BOB_CMD="${BOB_CMD:-bob}"
YOLO_FLAG="--yolo"
TAIL_LINES=5

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

mkdir -p "$LOG_DIR"

# Source spec queue helpers
source "$SCRIPT_DIR/lib/spec_queue.sh"

# Check constitution for YOLO setting
YOLO_ENABLED=true
if [[ -f "$CONSTITUTION" ]]; then
    if grep -q "YOLO Mode.*DISABLED" "$CONSTITUTION" 2>/dev/null; then
        YOLO_ENABLED=false
    fi
fi

show_help() {
    cat <<EOF
Ralph Loop for IBM Bob Shell

Based on Geoffrey Huntley's Ralph Wiggum methodology + SpecKit specs.
https://github.com/ghuntley/how-to-ralph-wiggum

Usage:
  ./scripts/ralph-loop.sh              # Build mode, unlimited iterations
  ./scripts/ralph-loop.sh 20           # Build mode, max 20 iterations
  ./scripts/ralph-loop.sh plan         # Planning mode (optional)

Modes:
  build (default)  Pick spec/task and implement
  plan             Create IMPLEMENTATION_PLAN.md from specs (OPTIONAL)

Work Sources (checked in order):
  1. IMPLEMENTATION_PLAN.md - If exists, pick highest priority task
  2. specs/ folder - Otherwise, pick highest priority incomplete spec

Bob CLI flags used:
  -p              Non-interactive prompt mode (required for automation)
  --yolo          Auto-approve all tool calls (enabled when YOLO Mode is on)

How it works:
  1. Each iteration pipes PROMPT_build.md into bob via stdin
  2. Bob picks the HIGHEST PRIORITY incomplete spec/task
  3. Bob implements, tests, and verifies acceptance criteria
  4. Bob outputs <promise>DONE</promise> ONLY if criteria are met
  5. Bash loop checks for the magic phrase
  6. If found, loop continues to next iteration (fresh context)
  7. If not found, loop retries

EOF
}

# stream_progress: watches the log as Bob writes it and prints clean status lines.
# - 🤔 <title>  when a <thinking> block opens (with its title)
# - ✓ done      when </thinking> closes
# - ⚙  <tool>   for each [using tool ...] line
# - ▶ <task>    for the active todo item (⊡)
# Runs as a background subshell; killed after Bob finishes.
stream_progress() {
    local log_file="$1"
    local waited=0
    while [ ! -f "$log_file" ] && [ "$waited" -lt 10 ]; do
        sleep 0.5; waited=$((waited + 1))
    done
    [ -f "$log_file" ] || return 0

    local last_line=0
    local in_thinking=false
    local thinking_title=""

    while true; do
        local total_lines
        total_lines=$(wc -l < "$log_file" 2>/dev/null || echo 0)

        if [ "$total_lines" -gt "$last_line" ]; then
            while IFS= read -r line; do

                # <thinking> opens
                if echo "$line" | grep -q "^<thinking>"; then
                    in_thinking=true
                    thinking_title=$(echo "$line" | sed 's|^<thinking>||;s|</thinking>.*||' | xargs)
                    if [ -n "$thinking_title" ]; then
                        printf "${CYAN}  🤔 %s${NC}\n" "$thinking_title" > /dev/tty
                        thinking_title="__shown__"
                    fi
                    continue
                fi

                # </thinking> closes
                if echo "$line" | grep -q "</thinking>"; then
                    if [ -n "$thinking_title" ] && [ "$thinking_title" != "__shown__" ]; then
                        printf "${CYAN}  🤔 %s${NC}\n" "$thinking_title" > /dev/tty
                    fi
                    printf "${GREEN}  ✓ done${NC}\n" > /dev/tty
                    in_thinking=false
                    thinking_title=""
                    continue
                fi

                # first non-empty line inside <thinking> becomes the title
                if [ "$in_thinking" = true ] && [ -z "$thinking_title" ]; then
                    local stripped
                    stripped=$(echo "$line" | sed 's/\*\*//g' | xargs)
                    if [ -n "$stripped" ]; then
                        printf "${CYAN}  🤔 %s${NC}\n" "$stripped" > /dev/tty
                        thinking_title="__shown__"
                    fi
                    continue
                fi

                # [using tool ...]
                if echo "$line" | grep -q "^\[using tool "; then
                    local tool_desc
                    tool_desc=$(echo "$line" | sed 's/^\[using tool //' | sed 's/\]$//')
                    printf "${YELLOW}  ⚙  %s${NC}\n" "$tool_desc" > /dev/tty
                fi

                # active todo item ( ⊡ )
                if echo "$line" | grep -qE "^ ⊡ "; then
                    local task
                    task=$(echo "$line" | sed 's/^ ⊡ //' | xargs)
                    printf "${PURPLE}  ▶ %s${NC}\n" "$task" > /dev/tty
                fi

            done < <(sed -n "$((last_line + 1)),${total_lines}p" "$log_file" 2>/dev/null)
            last_line=$total_lines
        fi

        sleep 0.3
    done
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        plan)
            MODE="plan"
            if [[ "${2:-}" =~ ^[0-9]+$ ]]; then
                MAX_ITERATIONS="$2"
                shift 2
            else
                MAX_ITERATIONS=1
                shift
            fi
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        [0-9]*)
            MODE="build"
            MAX_ITERATIONS="$1"
            shift
            ;;
        *)
            echo -e "${RED}Unknown argument: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

cd "$PROJECT_DIR"

# Session log (captures ALL output)
SESSION_LOG="$LOG_DIR/ralph_${MODE}_session_$(date '+%Y%m%d_%H%M%S').log"
exec > >(tee -a "$SESSION_LOG") 2>&1

# Check if Bob CLI is available
if ! command -v "$BOB_CMD" &> /dev/null; then
    echo -e "${RED}Error: bob CLI not found${NC}"
    echo ""
    echo "Install IBM Bob Shell and authenticate first."
    echo "On first run, accept the license:"
    echo "  bob --accept-license -p \"Hello\""
    exit 1
fi

# Determine prompt file based on mode
if [ "$MODE" = "plan" ]; then
    PROMPT_FILE="PROMPT_plan.md"
else
    PROMPT_FILE="PROMPT_build.md"
fi

# Generate PROMPT files — constitution.md contains the full workflow
cat > "PROMPT_build.md" << 'BUILDEOF'
# Ralph Loop — Build Mode

You are running inside a Ralph Wiggum autonomous loop.

Read `.specify/memory/constitution.md` — it contains all project principles, workflow
instructions, work sources, and completion signal requirements.

Find the highest-priority incomplete work item, implement it completely, verify all
acceptance criteria, commit and push, then output `<promise>DONE</promise>`.
BUILDEOF

cat > "PROMPT_plan.md" << 'PLANEOF'
# Ralph Loop — Planning Mode

You are running inside a Ralph Wiggum autonomous loop in planning mode.

Read `.specify/memory/constitution.md` for project principles.

Study `specs/` and compare against the current codebase (gap analysis).
Create or update `IMPLEMENTATION_PLAN.md` with a prioritized task breakdown.
Do NOT implement anything.

When the plan is complete, output `<promise>DONE</promise>`.
PLANEOF

# Check prompt file exists
if [ ! -f "$PROMPT_FILE" ]; then
    echo -e "${RED}Error: $PROMPT_FILE not found${NC}"
    exit 1
fi

# Build Bob flags
# bob -p reads prompt from argument; we pipe via stdin using `cat file | bob`
# --yolo auto-approves all tool calls (file writes, shell commands, etc.)
BOB_FLAGS=""
if [ "$YOLO_ENABLED" = true ]; then
    BOB_FLAGS="$YOLO_FLAG"
fi

# Get current branch
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "main")

# Check for work sources
HAS_PLAN=false
HAS_SPECS=false
SPEC_COUNT=0
INCOMPLETE_SPEC_COUNT=0
FIRST_INCOMPLETE_SPEC=""
[ -f "IMPLEMENTATION_PLAN.md" ] && HAS_PLAN=true
if [ -d "specs" ]; then
    SPEC_COUNT=$(count_root_specs "specs")
    INCOMPLETE_SPEC_COUNT=$(count_incomplete_root_specs "specs")
    [ "$SPEC_COUNT" -gt 0 ] && HAS_SPECS=true
    if [ "$INCOMPLETE_SPEC_COUNT" -gt 0 ]; then
        FIRST_INCOMPLETE_SPEC=$(get_first_incomplete_root_spec "specs")
    fi
fi

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}              RALPH LOOP (IBM Bob Shell) STARTING             ${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}Mode:${NC}     $MODE"
echo -e "${BLUE}Agent:${NC}    IBM Bob Shell (bob)"
echo -e "${BLUE}Prompt:${NC}   $PROMPT_FILE"
echo -e "${BLUE}Branch:${NC}   $CURRENT_BRANCH"
echo -e "${YELLOW}YOLO:${NC}     $([ "$YOLO_ENABLED" = true ] && echo "ENABLED (--yolo)" || echo "DISABLED")"
[ -n "$SESSION_LOG" ] && echo -e "${BLUE}Log:${NC}      $SESSION_LOG"
[ $MAX_ITERATIONS -gt 0 ] && echo -e "${BLUE}Max:${NC}      $MAX_ITERATIONS iterations"
echo ""
echo -e "${BLUE}Work source:${NC}"
if [ "$HAS_PLAN" = true ]; then
    echo -e "  ${GREEN}✓${NC} IMPLEMENTATION_PLAN.md (will use this)"
else
    echo -e "  ${YELLOW}○${NC} IMPLEMENTATION_PLAN.md (not found, that's OK)"
fi
if [ "$HAS_SPECS" = true ]; then
    echo -e "  ${GREEN}✓${NC} specs/ folder ($SPEC_COUNT specs, $INCOMPLETE_SPEC_COUNT incomplete)"
    if [ "$HAS_PLAN" = false ] && [ "$INCOMPLETE_SPEC_COUNT" -gt 0 ]; then
        echo -e "    ${CYAN}Next incomplete:${NC} $FIRST_INCOMPLETE_SPEC"
    fi
else
    echo -e "  ${RED}✗${NC} specs/ folder (no .md files found)"
fi
echo ""

# Exit early if all specs are complete and no plan
if [ "$MODE" = "build" ] && [ "$HAS_PLAN" = false ] && [ "$HAS_SPECS" = true ] && [ "$INCOMPLETE_SPEC_COUNT" -eq 0 ]; then
    echo -e "${GREEN}All $SPEC_COUNT specs are COMPLETE. Nothing to do.${NC}"
    echo -e "${CYAN}To add more work, create a new spec in specs/ without 'Status: COMPLETE'.${NC}"
    exit 0
fi

echo -e "${CYAN}The loop checks for <promise>DONE</promise> in each iteration.${NC}"
echo -e "${CYAN}Bob must verify acceptance criteria before outputting it.${NC}"
echo ""
echo -e "${YELLOW}Press Ctrl+C to stop the loop${NC}"
echo ""

ITERATION=0
CONSECUTIVE_FAILURES=0
MAX_CONSECUTIVE_FAILURES=3

while true; do
    # Check max iterations
    if [ $MAX_ITERATIONS -gt 0 ] && [ $ITERATION -ge $MAX_ITERATIONS ]; then
        echo -e "${GREEN}Reached max iterations: $MAX_ITERATIONS${NC}"
        break
    fi

    ITERATION=$((ITERATION + 1))
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

    echo ""
    echo -e "${PURPLE}════════════════════ LOOP $ITERATION ════════════════════${NC}"
    echo -e "${BLUE}[$TIMESTAMP]${NC} Starting iteration $ITERATION"
    echo ""

    # Log file for this iteration (full raw output from Bob)
    LOG_FILE="$LOG_DIR/ralph_${MODE}_iter_${ITERATION}_$(date '+%Y%m%d_%H%M%S').log"
    : > "$LOG_FILE"
    WATCH_PID=""

    # Start live progress watcher — reads log, prints clean status to /dev/tty
    if [ -w /dev/tty ]; then
        stream_progress "$LOG_FILE" &
        WATCH_PID=$!
    fi

    # Run Bob — all output goes to log file only (watcher shows status instead)
    set +e
    cat "$PROMPT_FILE" | "$BOB_CMD" $BOB_FLAGS > "$LOG_FILE" 2>&1
    BOB_EXIT=$?
    set -e

    # Stop the progress watcher
    if [ -n "$WATCH_PID" ]; then
        kill "$WATCH_PID" 2>/dev/null || true
        wait "$WATCH_PID" 2>/dev/null || true
        WATCH_PID=""
    fi

    BOB_OUTPUT=$(cat "$LOG_FILE")

    if [ "$BOB_EXIT" -eq 0 ]; then
        echo ""
        echo -e "${GREEN}✓ Bob execution completed${NC}"

        # Check if DONE promise was output (accept both DONE and ALL_DONE variants)
        if echo "$BOB_OUTPUT" | grep -qE "<promise>(ALL_)?DONE</promise>"; then
            DETECTED_SIGNAL=$(echo "$BOB_OUTPUT" | grep -oE "<promise>(ALL_)?DONE</promise>" | tail -1)
            echo -e "${GREEN}✓ Completion signal detected: ${DETECTED_SIGNAL}${NC}"
            echo -e "${GREEN}✓ Task completed successfully!${NC}"
            CONSECUTIVE_FAILURES=0

            # For planning mode, stop after one successful plan
            if [ "$MODE" = "plan" ]; then
                echo ""
                echo -e "${GREEN}Planning complete!${NC}"
                echo -e "${CYAN}Run './scripts/ralph-loop.sh' to start building.${NC}"
                echo -e "${CYAN}Or delete IMPLEMENTATION_PLAN.md to work directly from specs.${NC}"
                break
            fi
        else
            echo -e "${YELLOW}⚠ No completion signal found${NC}"
            echo -e "${YELLOW}  Bob did not output <promise>DONE</promise> or <promise>ALL_DONE</promise>${NC}"
            echo -e "${YELLOW}  This means acceptance criteria were not met.${NC}"
            echo -e "${YELLOW}  Retrying in next iteration...${NC}"
            CONSECUTIVE_FAILURES=$((CONSECUTIVE_FAILURES + 1))

            if [ $CONSECUTIVE_FAILURES -ge $MAX_CONSECUTIVE_FAILURES ]; then
                echo ""
                echo -e "${RED}⚠ $MAX_CONSECUTIVE_FAILURES consecutive iterations without completion.${NC}"
                echo -e "${RED}  Bob may be stuck. Consider:${NC}"
                echo -e "${RED}  - Checking the logs in $LOG_DIR${NC}"
                echo -e "${RED}  - Simplifying the current spec${NC}"
                echo -e "${RED}  - Manually fixing blocking issues${NC}"
                echo ""
                CONSECUTIVE_FAILURES=0
            fi
        fi
    else
        echo -e "${RED}✗ Bob execution failed (exit: $BOB_EXIT)${NC}"
        echo -e "${YELLOW}Check log: $LOG_FILE${NC}"
        CONSECUTIVE_FAILURES=$((CONSECUTIVE_FAILURES + 1))
    fi

    # Push changes after each iteration (if any)
    git push origin "$CURRENT_BRANCH" 2>/dev/null || {
        if git log origin/$CURRENT_BRANCH..HEAD --oneline 2>/dev/null | grep -q .; then
            echo -e "${YELLOW}Push failed, creating remote branch...${NC}"
            git push -u origin "$CURRENT_BRANCH" 2>/dev/null || true
        fi
    }

    # Brief pause between iterations
    echo ""
    echo -e "${BLUE}Waiting 2s before next iteration...${NC}"
    sleep 2
done

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}         RALPH LOOP FINISHED ($ITERATION iterations)         ${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
