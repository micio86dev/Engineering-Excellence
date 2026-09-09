#!/usr/bin/env bash
# ==============================================================================
# Engineering Excellence — universal skill installer
#
# Installs the "engineering-excellence" skill into every AI coding agent found
# on this machine (Claude Code, Gemini CLI, Cursor, pi.dev, Antigravity, and a
# generic ~/.config fallback). Idempotent: re-running refreshes each copy.
#
# Usage:
#   ./install.sh                 # install into all detected agents
#   ./install.sh --list          # show target paths without installing
#   ./install.sh --agents claude,pi   # only the named agents
#   SKILL_SRC=/path/to/skill ./install.sh   # override source dir
#
# Source of the skill (in priority order):
#   1. $SKILL_SRC if set
#   2. ./skills/engineering-excellence   (this repo's layout)
#   3. ./engineering-excellence
# ==============================================================================

set -Eeuo pipefail

SKILL_NAME="engineering-excellence"

# ------------------------------------------------------------------------------
# Locate the skill source directory
# ------------------------------------------------------------------------------

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

resolve_src() {
    if [[ -n "${SKILL_SRC:-}" ]]; then
        printf '%s' "${SKILL_SRC}"
        return
    fi
    if [[ -d "${SCRIPT_DIR}/skills/${SKILL_NAME}" ]]; then
        printf '%s' "${SCRIPT_DIR}/skills/${SKILL_NAME}"
        return
    fi
    if [[ -d "${SCRIPT_DIR}/${SKILL_NAME}" ]]; then
        printf '%s' "${SCRIPT_DIR}/${SKILL_NAME}"
        return
    fi
    printf ''
}

SRC="$(resolve_src)"

# ------------------------------------------------------------------------------
# Target table: agent -> skills directory
#
# These follow each agent's documented skills location. A target is only used
# if its parent config dir already exists (i.e. the agent is installed),
# unless --force-all is given.
# ------------------------------------------------------------------------------

declare -A TARGETS=(
    [claude]="${HOME}/.claude/skills"
    [pi]="${HOME}/.pi/agent/skills"
    [gemini]="${HOME}/.gemini/skills"
    [cursor]="${HOME}/.cursor/skills"
    [antigravity]="${HOME}/.antigravity/skills"
    [generic]="${HOME}/.config/agent-skills"
)

# Parent dir that must exist for the agent to be considered "present".
declare -A PRESENCE=(
    [claude]="${HOME}/.claude"
    [pi]="${HOME}/.pi"
    [gemini]="${HOME}/.gemini"
    [cursor]="${HOME}/.cursor"
    [antigravity]="${HOME}/.antigravity"
    [generic]="${HOME}/.config"
)

# ------------------------------------------------------------------------------
# Args
# ------------------------------------------------------------------------------

LIST_ONLY=0
FORCE_ALL=0
SELECTED=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --list) LIST_ONLY=1; shift ;;
        --force-all) FORCE_ALL=1; shift ;;
        --agents) SELECTED="$2"; shift 2 ;;
        --agents=*) SELECTED="${1#*=}"; shift ;;
        -h|--help)
            grep '^#' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *) printf 'Unknown argument: %s\n' "$1" >&2; exit 2 ;;
    esac
done

# ------------------------------------------------------------------------------
# Which agents to process
# ------------------------------------------------------------------------------

agents_to_process() {
    if [[ -n "${SELECTED}" ]]; then
        printf '%s\n' "${SELECTED//,/ }"
        return
    fi
    printf '%s\n' "${!TARGETS[@]}"
}

# ------------------------------------------------------------------------------
# List mode
# ------------------------------------------------------------------------------

if [[ "${LIST_ONLY}" -eq 1 ]]; then
    printf 'Skill source: %s\n\n' "${SRC:-<not found>}"
    printf '%-14s %-40s %s\n' "AGENT" "TARGET" "PRESENT"
    for agent in $(agents_to_process); do
        tgt="${TARGETS[$agent]:-<unknown agent>}"
        present="no"
        [[ -d "${PRESENCE[$agent]:-/nonexistent}" ]] && present="yes"
        printf '%-14s %-40s %s\n' "${agent}" "${tgt}/${SKILL_NAME}" "${present}"
    done
    exit 0
fi

# ------------------------------------------------------------------------------
# Validate source before doing anything destructive
# ------------------------------------------------------------------------------

if [[ -z "${SRC}" || ! -d "${SRC}" ]]; then
    printf 'ERROR: skill source not found.\n' >&2
    printf 'Set SKILL_SRC=/path/to/%s or run from the repo root.\n' "${SKILL_NAME}" >&2
    exit 1
fi

if [[ ! -f "${SRC}/SKILL.md" ]]; then
    printf 'ERROR: %s has no SKILL.md — is this really the skill dir?\n' "${SRC}" >&2
    exit 1
fi

# ------------------------------------------------------------------------------
# Install
# ------------------------------------------------------------------------------

install_one() {
    local agent="$1"
    local base="${TARGETS[$agent]:-}"

    if [[ -z "${base}" ]]; then
        printf 'skip   %-12s (unknown agent)\n' "${agent}"
        return
    fi

    if [[ "${FORCE_ALL}" -ne 1 && ! -d "${PRESENCE[$agent]:-/nonexistent}" ]]; then
        printf 'skip   %-12s (agent not detected; use --force-all to install anyway)\n' "${agent}"
        return
    fi

    local dest="${base}/${SKILL_NAME}"
    mkdir -p "${base}"

    # Prefer rsync for a clean mirror; fall back to cp -a.
    if command -v rsync >/dev/null 2>&1; then
        rsync -a --delete "${SRC}/" "${dest}/"
    else
        rm -rf "${dest}"
        mkdir -p "${dest}"
        cp -a "${SRC}/." "${dest}/"
    fi

    printf 'ok     %-12s -> %s\n' "${agent}" "${dest}"
}

printf 'Installing "%s" from %s\n\n' "${SKILL_NAME}" "${SRC}"

for agent in $(agents_to_process); do
    install_one "${agent}"
done

printf '\nDone. Re-run any time to refresh; already-installed copies are overwritten in place.\n'
