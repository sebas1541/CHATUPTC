#!/usr/bin/env bash
# Descarga los pesos de mlx-community/gemma-4-e2b-it-4bit (~3.6 GB) en ./Model/
set -euo pipefail

DIR="$(cd "$(dirname "$0")/.." && pwd)/Model"
REPO="mlx-community/gemma-4-e2b-it-4bit"
BASE="https://huggingface.co/${REPO}/resolve/main"

mkdir -p "$DIR"
cd "$DIR"

FILES=(
    config.json
    generation_config.json
    tokenizer_config.json
    chat_template.jinja
    processor_config.json
    model.safetensors.index.json
    tokenizer.json
    model.safetensors
)

for f in "${FILES[@]}"; do
    if [[ -f "$f" ]]; then
        echo "✓ $f (ya existe)"
        continue
    fi
    echo "↓ $f"
    curl -L --progress-bar "$BASE/$f" -o "$f"
done

echo ""
echo "Modelo descargado en $DIR"
du -sh "$DIR"
