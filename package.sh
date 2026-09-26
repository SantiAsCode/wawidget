#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

version=$(python3 -c "import json; print(json.load(open('metadata.json'))['KPlugin']['Version'])")
id=$(python3 -c "import json; print(json.load(open('metadata.json'))['KPlugin']['Id'])")
name=${id##*.}

rm -rf dist
mkdir -p dist
zip -qr "dist/${name}-${version}.plasmoid" metadata.json contents

echo "Generado: dist/${name}-${version}.plasmoid"
