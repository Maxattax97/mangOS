#! /bin/bash

EDITION="$1"
FLAGS="--verbose --cache=/var/cache/live --releasever=30 --product=mangOS"
KICKSTARTS="./kickstarts"

if [ "$EDITION" == "libre" ]; then
    echo "Building mangOS Libre edition ..."
    livecd-creator $FLAGS --config="${KICKSTARTS}/mangOS-libre.ks" --fslabel=mangOS-libre --title=mangOS-libre-$(date -u "+%y-%m-%dUT%H-%M-%S")
elif [ "$EDITION" == "nonlibre" ]; then
    echo "Building mangOS non-Libre edition ..."
    livecd-creator $FLAGS --config="${KICKSTARTS}/mangOS-nonlibre.ks" --fslabel=mangOS-nonlibre --title=mangOS-nonlibre-$(date -u "+%y-%m-%dUT%H-%M-%S")
elif [ "$EDITION" == "minimal" ]; then
    echo "Building mangOS minimal edition ..."
    livecd-creator $FLAGS --config="${KICKSTARTS}/mangOS-live-base.ks" --fslabel=mangOS-minimal --title=mangOS-minimal-$(date -u "+%y-%m-%dUT%H-%M-%S")
else
    echo "You must select an edition of mangOS to build."
fi
