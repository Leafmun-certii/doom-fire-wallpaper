#!/bin/bash

set -e
COMMAND="$1"

setup() {
    # Create config directory if it doesn't exist
    CONFIG_DIR="$HOME/.config/doom-fire-wallpaper"
    mkdir -p "$CONFIG_DIR"
    if [ ! -f "$CONFIG_DIR/config.toml" ]; then
        cat > "$CONFIG_DIR/config.toml" <<EOF
# Example config.toml for doom-fire-wallpaper
screen_width = 1920
screen_height = 1080
scale = 4
fps = 23
fire_type = "Original"
background = [0, 0, 0]
restart_on_pause = true
EOF
        echo "Created example config at $CONFIG_DIR/config.toml"
    fi
    # Create systemd user service
    SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
    mkdir -p "$SYSTEMD_USER_DIR"
    cat > "$SYSTEMD_USER_DIR/doom-fire-wallpaper.service" <<EOF
[Unit]
Description=DOOM Fire Wallpaper for Hyprpaper
After=graphical-session.target hyprpaper.service

[Service]
Type=simple
ExecStart=/usr/bin/doom-fire-wallpaper
Restart=on-failure
Nice=10

[Install]
WantedBy=default.target
EOF
    echo "Created systemd user service at $SYSTEMD_USER_DIR/doom-fire-wallpaper.service"
    if ! command -v hyprpaper >/dev/null 2>&1; then
        echo "Error: Hyprpaper is not installed or not in your PATH."
        echo "Please install Hyprpaper: https://github.com/hyprwm/hyprpaper"
        echo "Remeber to enable and start it's service"
    else
        echo "Hyprpaper is installed. You make sure it's service is enabled."
        echo "Enabling and starting the wallpaper service now..."
        systemctl --user daemon-reload
        systemctl --user enable --now doom-fire-wallpaper.service
        systemctl --user start --now doom-fire-wallpaper.service
        echo
    fi
}

refresh() {
    echo "Force-restarting doom-fire-wallpaper..."
    systemctl --user daemon-reload

    echo "Stopping service..."
    systemctl --user stop doom-fire-wallpaper.service

    # Explicitly kill the process to ensure it's gone.
    if pkill -f "/usr/bin/doom-fire-wallpaper"; then
        echo "Killed running doom-fire-wallpaper process."
        # Give it a moment to terminate.
        sleep 0.2
    fi

    echo "Starting new instance..."
    systemctl --user start doom-fire-wallpaper.service
    echo "Wallpaper restarted."
}

stop() {
    echo "Stopping and disabling doom-fire-wallpaper systemd user service..."
    systemctl --user stop doom-fire-wallpaper.service
    systemctl --user disable doom-fire-wallpaper.service
    echo "Service stopped and disabled."
}

case "$COMMAND" in
    setup)
        setup
    ;;
    refresh)
        refresh
    ;;
    stop)
        stop
    ;;
    ""|help|-h|--help)
        echo "Usage: $0 <command>"
        echo "Commands:"
        echo "  setup     Sets up the doom-fire-wallpaper and its service."
        echo "  refresh   Reload the wallpaper service after config changes."
        echo "  stop      Stop and disable the wallpaper service."
    ;;
    *)
        echo "Unknown command: $COMMAND"
        echo "Run '$0 help' for usage."
        exit 1
    ;;
esac
