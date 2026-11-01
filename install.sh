#!/usr/bin/env bash
# ====================================================================
# Universal AI Agent & Skill Installer (Linux & macOS)
# Configures PHP Upgrade Agent for GitHub Copilot, Claude Code, Cursor, and Gemini
# ====================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="${SCRIPT_DIR}/.agents/templates"

CYAN='\033[1;36m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RESET='\033[0m'

echo -e "${CYAN}====================================================================${RESET}"
echo -e "${CYAN}   🚀 PHP Upgrade Agent & Security Hardener - Multi-LLM Setup       ${RESET}"
echo -e "${CYAN}====================================================================${RESET}"
echo "Configures zero-breakage PHP modernization and php2shell fixes for:"
echo " • GitHub Copilot (Default)"
echo " • Claude Code"
echo " • Cursor"
echo " • Google Gemini / Antigravity"
echo ""

SELECTION="$1"

if [ -z "$SELECTION" ]; then
    echo -e "${YELLOW}Select your primary AI Coding Assistant:${RESET}"
    echo -e "  [1] GitHub Copilot ${GREEN}(Default - Press Enter)${RESET}"
    echo "  [2] Claude Code"
    echo "  [3] Cursor"
    echo "  [4] Google Gemini / Antigravity"
    echo "  [5] Universal Setup (Configure All Assistants)"
    echo ""
    read -p "Enter selection [1-5] (Default: 1): " USER_INPUT
    
    case "$USER_INPUT" in
        2) SELECTION="claude" ;;
        3) SELECTION="cursor" ;;
        4) SELECTION="gemini" ;;
        5) SELECTION="all" ;;
        *) SELECTION="copilot" ;;
    esac
fi

SELECTION=$(echo "$SELECTION" | tr '[:upper:]' '[:lower:]')

echo ""
echo -e "[*] Applying configuration for: ${GREEN}${SELECTION}${RESET}"

setup_copilot() {
    echo "[*] Setting up GitHub Copilot adapter..."
    mkdir -p "${SCRIPT_DIR}/.github/prompts"
    cp "${TEMPLATE_DIR}/copilot-instructions.md" "${SCRIPT_DIR}/.github/copilot-instructions.md"
    echo -e "  ${GREEN}[+] Configured .github/copilot-instructions.md${RESET}"
}

setup_claude() {
    echo "[*] Setting up Claude Code adapter..."
    cp "${TEMPLATE_DIR}/CLAUDE.md" "${SCRIPT_DIR}/CLAUDE.md"
    echo -e "  ${GREEN}[+] Configured CLAUDE.md${RESET}"
}

setup_cursor() {
    echo "[*] Setting up Cursor adapter..."
    mkdir -p "${SCRIPT_DIR}/.cursor/rules"
    cp "${TEMPLATE_DIR}/cursorrules" "${SCRIPT_DIR}/.cursorrules"
    cp "${TEMPLATE_DIR}/cursorrules" "${SCRIPT_DIR}/.cursor/rules/php-upgrade.mdc"
    echo -e "  ${GREEN}[+] Configured .cursorrules and .cursor/rules/php-upgrade.mdc${RESET}"
}

setup_gemini() {
    echo "[*] Setting up Google Gemini / Antigravity adapter..."
    cp "${TEMPLATE_DIR}/GEMINI.md" "${SCRIPT_DIR}/GEMINI.md"
    echo -e "  ${GREEN}[+] Configured GEMINI.md${RESET}"
}

case "$SELECTION" in
    copilot)
        setup_copilot
        ;;
    claude)
        setup_claude
        ;;
    cursor)
        setup_cursor
        ;;
    gemini)
        setup_gemini
        ;;
    all|*)
        setup_copilot
        setup_claude
        setup_cursor
        setup_gemini
        ;;
esac

echo ""
echo -e "${GREEN}[+] Installation Complete!${RESET}"
echo "AI Assistant configured successfully. Agents, rules, and skills reside in: .agents/"
echo ""
