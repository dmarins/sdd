#!/bin/bash
set -e

# Este script ajuda a inicializar o diretorio de ideias da skill idea-refine.

IDEAS_DIR="docs/ideas"

if [ ! -d "$IDEAS_DIR" ]; then
  mkdir -p "$IDEAS_DIR"
  echo "Diretorio criado: $IDEAS_DIR" >&2
else
  echo "Diretorio ja existe: $IDEAS_DIR" >&2
fi

echo "{\"status\": \"ready\", \"directory\": \"$IDEAS_DIR\"}"
