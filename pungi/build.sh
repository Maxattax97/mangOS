#!/bin/bash

CONFIG="basic.conf"
TARGET_DIR="./build/"
NIGHTLY="--nightly"
SKIP_PHASES="--skip-phase=productimg"

CMD="pungi-koji --config=$CONFIG --target-dir=$TARGET_DIR $NIGHTLY $SKIP_PHASES"

rm -rf "$TARGET_DIR"
mkdir -p "$TARGET_DIR"

time $CMD "$@"
if [ "$?" != "0" ]; then
    exit 1
fi
