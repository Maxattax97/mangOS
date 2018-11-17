#! /bin/bash

HERE="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
EDITION="$1"
FLAGS="--verbose --cache=/var/cache/live --fslabel=mangOS --title=mangOS-$(date -u "+%y-%m-%dUT%H-%M-%S")"

if [ "$EDITION" == "libre" ]; then
    echo "Building mangOS Libre edition ..."
    sudo livecd-creator $FLAGS --config="${HERE}/../mangos-libre.ks" --releasever="libre"
elif [ "$EDITION" == "nonlibre" ]; then
    echo "Building mangOS non-Libre edition ..."
    sudo livecd-creator $FLAGS --config="${HERE}/../mangos-nonlibre.ks" --releasever="nonlibre"
else
    echo "You must select an edition of mangOS to build."
fi
