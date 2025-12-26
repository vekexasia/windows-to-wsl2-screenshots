#!/bin/bash

# Windows-to-WSL2 Screenshot Automation Functions
# Auto-saves screenshots from Windows clipboard to WSL2 and manages clipboard sync

# Start the auto-screenshot monitor
start-screenshot-monitor() {
    echo "🚀 Starting Windows-to-WSL2 screenshot automation..."
    
    # Kill any existing monitors
    pkill -f "auto-clipboard-monitor" 2>/dev/null || true
    
    # Create screenshots directory in home
    mkdir -p "/tmp"
    
    # Get current directory to find the PowerShell script
    local script_dir="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
    local ps_script="$script_dir/auto-clipboard-monitor.ps1"
    
    if [ ! -f "$ps_script" ]; then
        echo "❌ PowerShell script not found at: $ps_script"
        echo "💡 Make sure auto-clipboard-monitor.ps1 is in the same directory as this script"
        return 1
    fi

    # Convert WSL path to Windows path for PowerShell
    local ps_script_win="$(wslpath -w "$ps_script")"

    # Start the monitor in background
    nohup powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File "$ps_script_win" > "/tmp/monitor.log" 2>&1 &
    
    echo "✅ SCREENSHOT AUTOMATION IS NOW RUNNING!"
    echo ""
    echo "🔥 MAGIC WORKFLOW:"
    echo "   1. Take screenshot (Win+Shift+S, Win+PrintScreen, etc.)"
    echo "   2. Image automatically saved to /tmp/"
    echo "   3. Path automatically copied to both Windows & WSL2 clipboards!"
    echo "   4. Just Ctrl+V in Claude Code or any application!"
    echo ""
    echo "📁 Images save to: /tmp/"
    echo "🔗 Latest always at: /tmp/latest.png"
    echo "📋 Drag & drop images to /tmp/ also works!"
}

# Stop the monitor
stop-screenshot-monitor() {
    echo "🛑 Stopping screenshot automation..."
    pkill -f "auto-clipboard-monitor" 2>/dev/null || true
    echo "✅ Screenshot automation stopped"
}

# Check if running
check-screenshot-monitor() {
    if pgrep -f "auto-clipboard-monitor" > /dev/null 2>&1; then
        echo "✅ Screenshot automation is running"
        echo "🔥 Just take screenshots - everything is automatic!"
        echo "📁 Saves to: /tmp/"
        echo "📋 Paths automatically copied to clipboard for easy pasting!"
    else
        echo "❌ Screenshot automation not running"
        echo "💡 Start with: start-screenshot-monitor"
    fi
}

# Quick access to latest image path
latest-screenshot() {
    echo "/tmp/latest.png"
}

# Copy latest image path to clipboard
copy-latest-screenshot() {
    if [ -f "/tmp/latest.png" ]; then
        echo "/tmp/latest.png" | clip.exe
        echo "✅ Copied to clipboard: /tmp/latest.png"
    else
        echo "❌ No latest screenshot found"
        echo "💡 Take a screenshot first (Win+Shift+S)"
    fi
}

# Copy specific image path to clipboard
copy-screenshot() {
    if [ -n "$1" ]; then
        local path="/tmp/$1"
        if [ -f "/tmp/$1" ]; then
            echo "$path" | clip.exe
            echo "✅ Copied to clipboard: $path"
        else
            echo "❌ File not found: $path"
            list-screenshots
        fi
    else
        echo "Usage: copy-screenshot <filename>"
        echo ""
        list-screenshots
    fi
}

# List available screenshots
list-screenshots() {
    echo "📸 Available screenshots:"
    if ls "/tmp/"*.png 2>/dev/null | grep -v latest; then
        echo ""
        echo "💡 Use 'copy-screenshot <filename>' to copy path to clipboard"
    else
        echo "   No screenshots found"
        echo "💡 Take a screenshot (Win+Shift+S) to get started!"
    fi
}

# Open screenshots directory
open-screenshots() {
    if command -v explorer.exe > /dev/null; then
        explorer.exe "$(wslpath -w "/tmp")"
    elif command -v nautilus > /dev/null; then
        nautilus "/tmp"
    else
        echo "📁 Screenshots directory: /tmp/"
        ls -la "/tmp/"
    fi
}

# Clean old screenshots (keep last N files)
clean-screenshots() {
    local keep=${1:-10}
    echo "🧹 Cleaning old screenshots, keeping latest $keep files..."
    
    cd "/tmp" || return 1
    
    # Count files (excluding latest.png)
    local count=$(ls -1 screenshot_*.png 2>/dev/null | wc -l)
    
    if [ "$count" -gt "$keep" ]; then
        ls -1t screenshot_*.png | tail -n +$((keep + 1)) | xargs rm -f
        echo "✅ Cleaned $((count - keep)) old screenshots"
    else
        echo "✅ No cleaning needed (only $count screenshots found)"
    fi
}

# Show help
screenshot-help() {
    echo "🚀 Windows-to-WSL2 Screenshot Automation"
    echo ""
    echo "📋 Available commands:"
    echo "  start-screenshot-monitor    - Start the automation"
    echo "  stop-screenshot-monitor     - Stop the automation"
    echo "  check-screenshot-monitor    - Check if running"
    echo "  latest-screenshot           - Get path to latest screenshot"
    echo "  copy-latest-screenshot      - Copy latest screenshot path to clipboard"
    echo "  copy-screenshot <file>      - Copy specific screenshot path to clipboard"
    echo "  list-screenshots            - List all available screenshots"
    echo "  open-screenshots            - Open screenshots directory"
    echo "  clean-screenshots [count]   - Clean old screenshots (default: keep 10)"
    echo "  screenshot-help             - Show this help"
    echo ""
    echo "🔥 Quick start:"
    echo "  1. Run: start-screenshot-monitor"
    echo "  2. Take screenshots with Win+Shift+S"
    echo "  3. Paths are automatically copied to clipboard!"
    echo "  4. Just Ctrl+V in Claude Code!"
}

# Aliases for convenience
alias screenshots='list-screenshots'
alias latest='latest-screenshot'
alias copy-latest='copy-latest-screenshot'
alias start-screenshots='start-screenshot-monitor'
alias stop-screenshots='stop-screenshot-monitor'
alias check-screenshots='check-screenshot-monitor'