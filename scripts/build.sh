#! /bin/bash

HERE="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
EDITION="$1"
FLAGS="--verbose --cache=/var/cache/live --fslabel=mangOS"

if [ "$EDITION" == "libre" ]; then
    echo "Building mangOS Libre edition ..."
    sudo livecd-creator $FLAGS --config="${HERE}/../mangOS-libre.ks" --title=mangOS-libre-$(date -u "+%y-%m-%dUT%H-%M-%S")
elif [ "$EDITION" == "nonlibre" ]; then
    echo "Building mangOS non-Libre edition ..."
    sudo livecd-creator $FLAGS --config="${HERE}/../mangOS-nonlibre.ks" --title=mangOS-nonlibre-$(date -u "+%y-%m-%dUT%H-%M-%S")
else
    echo "You must select an edition of mangOS to build."
fi
