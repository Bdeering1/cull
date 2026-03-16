#!/usr/bin/env bash
INSTALL_DIR="$HOME/.local/bin"
SCRIPT_URL="https://raw.githubusercontent.com/Bdeering1/cull/main/cull"
SCRIPT_NAME="cull"

echo "This script will install $SCRIPT_NAME to $INSTALL_DIR."

read -p "Continue? [Y/n] " -r reply
reply="${reply:-"y"}"
[[ ! "$reply" =~ ^[Yy]$ ]] || exit 0
echo

mkdir -p "$INSTALL_DIR"

curl -fsSL "$SCRIPT_URL" -o "$INSTALL_DIR/$SCRIPT_NAME"
if ! curl -fsSL "$SCRIPT_URL" -o "$INSTALL_DIR/$SCRIPT_NAME"; then
    echo "Error: failed to download cull from $SCRIPT_URL" >&2
    exit 1
fi

chmod +x "$INSTALL_DIR/$SCRIPT_NAME"

# Add install directory to PATH if not present
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    case "$SHELL" in
        */zsh)  SHELL_CONFIG="$HOME/.zshrc" ;;
        */bash) SHELL_CONFIG="$HOME/.bashrc" ;;
        *)      SHELL_CONFIG="$HOME/.profile" ;;
    esac
    {
        echo ""
        echo "# Added by cull installer"
        echo "export PATH=\"$INSTALL_DIR:\$PATH\""
    } >> "$SHELL_CONFIG"

    echo "Added $INSTALL_DIR to PATH in $SHELL_CONFIG"
    echo "Restart your terminal or run: source $SHELL_CONFIG"
fi

echo "Installation complete. Run 'cull --help' to get started."
