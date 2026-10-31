#!/bin/zsh
set -e
PROJECT_DIR="${0:A:h}"
mkdir -p "$PROJECT_DIR/build"
exec "$PROJECT_DIR/.tools/Godot.app/Contents/MacOS/Godot" --headless --path "$PROJECT_DIR/game" --export-release macOS "$PROJECT_DIR/build/Panic at the Pantry.app"
