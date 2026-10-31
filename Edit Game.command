#!/bin/zsh
set -e
PROJECT_DIR="${0:A:h}"
exec "$PROJECT_DIR/.tools/Godot.app/Contents/MacOS/Godot" --editor --path "$PROJECT_DIR/game"
