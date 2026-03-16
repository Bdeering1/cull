#!/usr/bin/env bash
INSTALL_DIR="$HOME/.local/bin"
SCRIPT_URL="https://raw.githubusercontent.com/Bdeering1/cull/main/cull"
SCRIPT_NAME="cull"

# Create install directory and download script
mkdir -p "$INSTALL_DIR"
if ! curl -fsSL "$SCRIPT_URL" -o "$INSTALL_DIR/$SCRIPT_NAME"; then
    echo "Error: failed to download $SCRIPT_NAME from $SCRIPT_URL" >&2
    exit 1
fi
chmod +x "$INSTALL_DIR/$SCRIPT_NAME"

add_to_shell_config() {
    local shell_cfg="$1"
    local line="$2"

    if grep -qF "$INSTALL_DIR" "$shell_cfg" 2>/dev/null; then return 1; fi
    {
        echo ""
        echo "# Added by $SCRIPT_NAME installer"
        echo "$line"
    } >> "$shell_cfg"
}

# Add install directory to PATH if required
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    SHELL_NAME=$(basename "$SHELL")
    DEFAULT_LINE="export PATH=\"$INSTALL_DIR:\$PATH\""
    NUSHELL_LINE="\$env.PATH = (\$env.PATH | split row (char esep) | prepend '$INSTALL_DIR')"

    case "$SHELL_NAME" in
        fish) fish -c "fish_add_path $INSTALL_DIR" ;;
        nu)   add_to_shell_config "$HOME/.config/nushell/env.nu" "$NUSHELL_LINE" ;;
        zsh)  add_to_shell_config "$HOME/.zshrc" "$DEFAULT_LINE" ;;
        bash) add_to_shell_config "$HOME/.bashrc" "$DEFAULT_LINE" ;;
        *)      add_to_shell_config "$HOME/.profile" "$DEFAULT_LINE" ;;
    esac && {
        echo "Added $INSTALL_DIR to \$PATH in $SHELL_NAME config."
        echo "Restart your terminal or source your shell config to use cull."
        echo
    }
fi

echo "Installation complete. Run 'cull --help' to get started."
