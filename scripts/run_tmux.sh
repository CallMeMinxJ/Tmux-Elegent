#!/usr/bin/env bash
#
# PORTABLE TMUX LAUNCHER - Minimal Version
# ==========================================
# Simple, portable tmux launcher with essential features
#

# Default paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TMUX_BINARY="${PROJECT_ROOT}/bin/tmux"
TMUX_CONFIG="${PROJECT_ROOT}/config/tmux.conf"
SESSIONS_DIR="${PROJECT_ROOT}/sessions"

# Display help message
show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] [TMUX_ARGS...]

Options:
  -h, --help              Display this help message
  -v, --verbose           Enable verbose output
  -d, --debug             Enable debug mode
  -s, --session NAME      Start with specific session
  -a, --attach            Attach to existing session
  -n, --new               Force new session creation
  -l, --list              List available sessions

Examples:
  $0                    # Start tmux normally
  $0 -s dev             # Start with session 'dev'
  $0 -a                 # Attach to existing session
  $0 -n -s workspace    # Force new session named 'workspace'
  $0 -l                 # List available sessions
  $0 new-session -s ws  # Pass arguments to tmux
EOF
    exit 0
}

# Verbose output function
verbose() {
    if [ "$VERBOSE" = true ]; then
        echo "[INFO] $1" >&2
    fi
}

# List available sessions
list_sessions() {
    echo "Available sessions:"
    if [ -d "$SESSIONS_DIR" ]; then
        for session_file in "$SESSIONS_DIR"/*.tmux; do
            if [ -f "$session_file" ]; then
                session_name=$(basename "$session_file" .tmux)
                echo "  $session_name"
            fi
        done
    else
        echo "  No session files found in $SESSIONS_DIR/"
    fi
    exit 0
}

# Parse command line arguments
parse_args() {
    SESSION_NAME=""
    ATTACH_FLAG=false
    NEW_SESSION=false
    VERBOSE=false
    DEBUG=false
    
    # Parse options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -d|--debug)
                DEBUG=true
                VERBOSE=true
                shift
                ;;
            -s|--session)
                SESSION_NAME="$2"
                shift 2
                ;;
            -a|--attach)
                ATTACH_FLAG=true
                shift
                ;;
            -n|--new)
                NEW_SESSION=true
                shift
                ;;
            -l|--list)
                list_sessions
                ;;
            --)
                shift
                TMUX_ARGS=("$@")
                break
                ;;
            -*)
                echo "Error: Unknown option $1"
                show_help
                exit 1
                ;;
            *)
                TMUX_ARGS+=("$1")
                shift
                ;;
        esac
    done
    
    # Enable debug mode if requested
    if [ "$DEBUG" = true ]; then
        set -x
    fi
}

# Validate environment
validate_environment() {
    # Check tmux binary exists
    if [ ! -f "$TMUX_BINARY" ]; then
        echo "Error: Tmux binary not found at $TMUX_BINARY"
        echo "Please place tmux binary in $PROJECT_ROOT/app/"
        exit 1
    fi
    
    # Make tmux executable if needed
    if [ ! -x "$TMUX_BINARY" ]; then
        verbose "Making tmux binary executable..."
        chmod +x "$TMUX_BINARY"
    fi
    
    # Check config file
    if [ ! -f "$TMUX_CONFIG" ]; then
        echo "Warning: Config file not found at $TMUX_CONFIG"
    fi
}

# Build tmux command
build_tmux_command() {
    # Base command
    CMD="$TMUX_BINARY -f $TMUX_CONFIG"
    
    # Add session arguments
    if [ -n "$SESSION_NAME" ]; then
        if [ "$ATTACH_FLAG" = true ]; then
            CMD="$CMD attach-session -t $SESSION_NAME"
        elif [ "$NEW_SESSION" = true ]; then
            CMD="$CMD new-session -s $SESSION_NAME"
        else
            # Try to attach, or create new if doesn't exist
            CMD="$CMD new-session -A -s $SESSION_NAME"
        fi
    else
        if [ "$ATTACH_FLAG" = true ]; then
            CMD="$CMD attach-session"
        elif [ "$NEW_SESSION" = true ]; then
            CMD="$CMD new-session"
        fi
    fi
    
    # Add additional arguments
    if [ ${#TMUX_ARGS[@]} -gt 0 ]; then
        CMD="$CMD ${TMUX_ARGS[@]}"
    fi
    
    verbose "Command: $CMD"
    echo "$CMD"
}

# Main function
main() {
    parse_args "$@"
    validate_environment
    
    # Export for tmux config
	export TMUX_PLUGIN_MANAGER_PATH="${PROJECT_ROOT}/plugins"
    export TMUX_CONFIG_FILE="$TMUX_CONFIG"
    export TMUX_PORTABLE_ROOT="$PROJECT_ROOT"
    
    CMD=$(build_tmux_command)
    
    if [ "$DEBUG" = true ]; then
        echo "Debug: Command to execute:" >&2
        echo "$CMD" >&2
        echo "Debug: Environment:" >&2
        echo "  PROJECT_ROOT: $PROJECT_ROOT" >&2
        echo "  TMUX_BINARY: $TMUX_BINARY" >&2
        echo "  TMUX_CONFIG: $TMUX_CONFIG" >&2
        read -p "Press Enter to execute or Ctrl+C to cancel..."
    fi
    
    # Execute tmux
    eval "exec $CMD"
}

# Run main
main "$@"
