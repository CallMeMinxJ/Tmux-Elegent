#!/usr/bin/env bash
# Example Tmux Session Configuration
# ==================================
# This file defines a tmux session layout
# Source with: tmux source-file session.tmux

# Main development session
new-session -s dev -n workspace

# Window 1: Editor
split-window -h
select-pane -t 0
send-keys "echo 'Ready for development'" Enter

# Window 2: Terminal
new-window -n terminal
split-window -v
select-pane -t 0
send-keys "clear" Enter

# Window 3: Logs
new-window -n logs
send-keys "echo 'System logs here'" Enter

# Focus first window
select-window -t 0
