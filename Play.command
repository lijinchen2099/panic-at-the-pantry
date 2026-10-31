#!/bin/zsh
set -e
PROJECT_DIR="${0:A:h}"
if [[ -d "$PROJECT_DIR/build/Panic at the Pantry.app" ]]; then
    open "$PROJECT_DIR/build/Panic at the Pantry.app"
else
    exec "$PROJECT_DIR/.tools/Godot.app/Contents/MacOS/Godot" --path "$PROJECT_DIR/game"
fi
