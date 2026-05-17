#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="/c/Users/leoZblack/.godot-ai-builder"

cd "$PROJECT_DIR"

if ! command -v claude >/dev/null 2>&1; then
    echo "Error: claude CLI not found in PATH."
    exit 1
fi

echo "Starting Claude with AI Game Builder plugin..."
echo "Project: $PROJECT_DIR"
echo "Plugin: $PLUGIN_DIR"
exec claude --plugin-dir "$PLUGIN_DIR" "$@"
