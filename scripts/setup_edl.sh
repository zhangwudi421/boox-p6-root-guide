#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EDL_DIR="$ROOT_DIR/edl"

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "missing command: $1" >&2
    exit 1
  fi
}

need_cmd git
need_cmd python

if [ ! -d "$EDL_DIR/.git" ]; then
  git clone https://github.com/bkerler/edl.git "$EDL_DIR"
else
  git -C "$EDL_DIR" pull --ff-only
fi

python -m pip install -r "$EDL_DIR/requirements.txt"

echo "EDL is ready: $EDL_DIR"

