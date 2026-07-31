#!/bin/bash
# Generate -> render -> preview loop.
#   ./preview.sh                          ZCL_PDF_DEMO run_base64
#   ./preview.sh ZCL_MY_DOC run_base64    build, render, rasterize to preview/
set -e

CLAS="${1:-ZCL_PDF_DEMO}"
METH="${2:-run_base64}"
PDF="${3:-preview.pdf}"
DIR="${4:-preview}"

cd "$(dirname "$0")"

echo "--- transpile"
rm -rf output
npx abap_transpile >/dev/null

echo "--- render"
node test/render.mjs "$CLAS" "$METH" "$PDF"

echo "--- rasterize"
python3 tools/pdf_preview.py "$PDF" --out "$DIR"
