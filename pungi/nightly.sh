#!/bin/sh


export LC_ALL=C

CONFIG="fedora.conf"
TARGET_DIR="/mnt/koji/compose/rawhide"
#OLD_COMPOSES_DIR="--old-composes=/mnt/fedora_koji/compose/f23 --old-composes=$TARGET_DIR"
NIGHTLY="--nightly"
SKIP_PHASES="--skip-phase=productimg"
DEST=$(pwd)
DATE=$(date "+%Y%m%d")
SHORT="Fedora"
RELEASE="rawhide"
RELEASE_TITLE="Rawhide"
COMPSFILE="comps-rawhide.xml"
TMPDIR=`mktemp -d /tmp/$RELEASE.$DATE.XXXX`
TOMAIL="devel@lists.fedoraproject.org test@lists.fedoraproject.org"
FROM="Fedora Rawhide Report <rawhide@fedoraproject.org>"
RSYNCPREFIX="sudo -u ftpsync"
RSYNCTARGET="/pub/fedora/linux/development/$RELEASE"
RSYNCALTTARGET="/pub/alt/development/$RELEASE"
RSYNCSECTARGET="/pub/fedora-secondary/development/$RELEASE"
OSTREESRCREPO="/mnt/koji/compose/ostree/repo/"
OSTREEDESTREPO="/mnt/koji/ostree/repo/"
OLDCOMPOSE_ID=$(cat $TARGET_DIR/latest-$SHORT-$RELEASE_TITLE/COMPOSE_ID)
# uncomment and edit for resuming a failed compose
#COMPOSE_ID="Fedora-23-20150530.n.0"

# assume a releng dir is a git checkout of the releng repo
# if it does not exist clone it
if [ -d releng ]; then
    pushd releng
    git pull --rebase
    popd
else
    git clone https://pagure.io/releng.git
fi

# Set up our fedmsg function, using the releng repo definition
FEDMSG_MODNAME="compose"
FEDMSG_CERTPREFIX="releng"
. ./releng/scripts/fedmsg-functions.sh

# Announce that we are starting, even though we don't know the compose_id yet..
fedmsg_json_start=$(printf '{"log": "start", "branch": "%s", "arch": "%s", "short": "%s"}' "$RELEASE" "$ARCH" "$SHORT")
send_fedmsg "${fedmsg_json_start}" ${RELEASE} start

#pushd $TMPDIR
#git clone https://pagure.io/fedora-comps.git && {
#    pushd fedora-comps
#    make "${COMPSFILE}"
#    cp "${COMPSFILE}" $DEST/
#    popd
#}
#popd

./releng/scripts/block_retired.py --profile compose_koji
./releng/scripts/block_retired.py --profile compose_koji --namespace=container

CMD="pungi-koji --notification-script=/usr/bin/pungi-fedmsg-notification --notification-script=pungi-wait-for-signed-ostree-handler --config=$CONFIG --old-composes=$TARGET_DIR $OLD_COMPOSES_DIR $NIGHTLY $SKIP_PHASES"

if [ -z "$COMPOSE_ID" ]; then
    CMD="$CMD --target-dir=$TARGET_DIR"
else
    CMD="$CMD --debug-mode --compose-dir=$TARGET_DIR/$COMPOSE_ID"
fi

time $CMD "$@"
if [ "$?" != "0" ]; then
    exit 1
fi

NEWCOMPOSE_ID=$(cat $TARGET_DIR/latest-$SHORT-$RELEASE_TITLE/COMPOSE_ID)
SHORTCOMPOSE_ID=$(echo $NEWCOMPOSE_ID|sed -e 's|Fedora-.*-||g')

# Set this to use later for a few items include depcheck
DESTDIR=$TARGET_DIR/$NEWCOMPOSE_ID
# Public URLs the synced compose will wind up at, we put them in fedmsgs
LOCATION="https://dl.fedoraproject.org$RSYNCTARGET"
ALT_LOCATION="https://dl.fedoraproject.org$RSYNCALTTARGET"
SECONDARY_LOCATION="https://dl.fedoraproject.org$RSYNCSECTARGET"
# Update fedmsg template
fedmsg_json_start=$(printf '{"log": "start", "branch": "%s", "arch": "%s", "short": "%s", "compose_id": "%s", "location": "%s", "alt_location": "%s", "secondary_location": "%s"}' "$RELEASE" "$ARCH" "$SHORT" "$NEWCOMPOSE_ID", "$LOCATION", "$ALT_LOCATION", "$SECONDARY_LOCATION")
fedmsg_json_done=$(printf '{"log": "done", "branch": "%s", "arch": "%s", "short": "%s", "compose_id": "%s", "location": "%s", "alt_location": "%s", "secondary_location": "%s"}' "$RELEASE" "$ARCH" "$SHORT" "$NEWCOMPOSE_ID", "$LOCATION", "$ALT_LOCATION", "$SECONDARY_LOCATION")

# Fix permissions on the grub efi files and fonts (they're 0600)
chmod -R go+r $DESTDIR/compose/*/*/os/EFI/

if ! compose-changelog -p "$DESTDIR/logs/" "$TARGET_DIR/$OLDCOMPOSE_ID/" "$DESTDIR/" 2>"$DESTDIR/logs/changelog.stderr"; then
    # Generating changelog failed. We should not send an empty announcement to
    # general public.
    TOMAIL=""
    VERSION="$(rpm -q compose-utils)"
    # Instead report it to rel-eng@ list.
    mutt -e "set from=\"$FROM\"" \
        -e 'set envelope_from=yes' \
        -s "Generating changelog for $NEWCOMPOSE_ID failed (with $VERSION)" \
        rel-eng@lists.fedoraproject.org \
        < "$DESTDIR/changelog.stderr"
fi

# Figure out a version for broken deps e-mail that goes to package maintainers.
# In Rawhide it's just rawhide, for branched versions we prepend F- to the number.
if [ "$RELEASE" = "rawhide" ]; then
    TREENAME="$RELEASE"
else
    TREENAME="F-$RELEASE"
fi
# disable sending email for now until we are sure we wont generating mass emails 
./releng/scripts/spam-o-matic --nomail --treename="$TREENAME" "$DESTDIR/compose/Everything/"  --only-arches i386 ppc64le s390x x86_64> "$DESTDIR/logs/depcheck"

[ -z "$ARCH" ] && {
./releng/scripts/critpath.py --url file://$DESTDIR/compose/Everything/ -o $DESTDIR/logs/critpath.txt rawhide &> $DESTDIR/logs/critpath.log
}

# Tell interested persons that the rsync is starting (zomg!)
send_fedmsg "${fedmsg_json_start}" ${RELEASE} rsync.start

# Sync the content to /pub/fedora
if [ ! -d "$RSYNCTARGET" ]; then
  mkdir "$RSYNCTARGET"
fi
$RSYNCPREFIX compose-partial-copy --arch=armhfp --arch=x86_64 --arch src \
    "$DESTDIR" "$RSYNCTARGET/" \
    --variant Everything --variant Cloud --variant Container \
    --variant Server --variant Spins --variant Workstation --variant Silverblue --variant Modular \
    --link-dest="$RSYNCTARGET/Everything" --exclude=repodata
$RSYNCPREFIX compose-partial-copy --arch=armhfp --arch=x86_64 --arch src \
    "$DESTDIR" "$RSYNCTARGET/" \
    --variant Everything --variant Cloud --variant Container \
    --variant Server --variant Spins --variant Workstation --variant Silverblue --variant Modular \
    --link-dest="$RSYNCTARGET/Everything" --delete-after
# aarch64 for Everything Server Cloud Container is primary
$RSYNCPREFIX compose-partial-copy --arch=aarch64 \
    "$DESTDIR" "$RSYNCTARGET/" \
    --variant Everything --variant Server --variant Cloud --variant Container \
    --variant Modular \
    --link-dest="$RSYNCTARGET/Everything" --exclude=repodata
$RSYNCPREFIX compose-partial-copy --arch=aarch64 \
    "$DESTDIR" "$RSYNCTARGET/" \
    --variant Everything --variant Server --variant Cloud --variant Container \
    --variant Modular \
    --link-dest="$RSYNCTARGET/Everything" --delete-after
$RSYNCPREFIX rm "$RSYNCTARGET/.composeinfo"
$RSYNCPREFIX ./releng/scripts/build_composeinfo "$RSYNCTARGET/" --name "$NEWCOMPOSE_ID"

# Sync the content to /pub/alt
if [ ! -d "$RSYNCALTTARGET" ]; then
  mkdir "$RSYNCALTTARGET"
fi
$RSYNCPREFIX compose-partial-copy --arch=armhfp --arch=x86_64 \
    "$DESTDIR" "$RSYNCALTTARGET/" \
    --variant Labs \
    --link-dest="$RSYNCTARGET/Everything/" --exclude=repodata
$RSYNCPREFIX compose-partial-copy --arch=armhfp --arch=x86_64 \
    "$DESTDIR" "$RSYNCALTTARGET/" \
    --variant Labs \
    --link-dest="$RSYNCTARGET/Everything/" --delete-after
$RSYNCPREFIX rm "$RSYNCALTTARGET/.composeinfo"
$RSYNCPREFIX ./releng/scripts/build_composeinfo "$RSYNCALTTARGET/" --name "$NEWCOMPOSE_ID"

# Sync the content to /pub/fedora-secondary
if [ ! -d "$RSYNCSECTARGET" ]; then
  mkdir "$RSYNCSECTARGET"
fi
$RSYNCPREFIX compose-partial-copy --arch=i386 --arch=ppc64le --arch=s390x \
    "$DESTDIR" "$RSYNCSECTARGET/" \
    --variant Everything --variant Cloud --variant Container \
    --variant Labs --variant Server --variant Spins --variant Workstation --variant Modular \
    --link-dest="$RSYNCTARGET/Everything/" --link-dest="$RSYNCSECTARGET/Everything/" --exclude=repodata
$RSYNCPREFIX compose-partial-copy --arch=i386 --arch=ppc64le --arch=s390x \
    "$DESTDIR" "$RSYNCSECTARGET/" \
    --variant Everything --variant Cloud --variant Container \
    --variant Labs --variant Server --variant Spins --variant Workstation --variant Modular \
    --link-dest="$RSYNCTARGET/Everything/" --link-dest="$RSYNCSECTARGET/Everything/" --delete-after
# aarch64 is alternative for Labs Spins Workstation
$RSYNCPREFIX compose-partial-copy --arch=aarch64 \
    "$DESTDIR" "$RSYNCSECTARGET/" \
    --variant Labs --variant Spins --variant Workstation \
    --link-dest="$RSYNCTARGET/Everything/" --exclude=repodata
$RSYNCPREFIX compose-partial-copy --arch=aarch64 \
    "$DESTDIR" "$RSYNCSECTARGET/" \
    --variant Labs --variant Spins --variant Workstation \
    --link-dest="$RSYNCTARGET/Everything/" --delete-after
$RSYNCPREFIX rm "$RSYNCSECTARGET/.composeinfo"
$RSYNCPREFIX ./releng/scripts/build_composeinfo "$RSYNCSECTARGET/" --name "$NEWCOMPOSE_ID"

# sync Silverblue to the unified ostree repo
for arch in x86_64 ppc64le aarch64; do
    ref="fedora/rawhide/${arch}/silverblue"
    if ! ostree --repo=$OSTREESRCREPO rev-parse "${ref}"; then continue; fi

    ostree pull-local --repo=$OSTREEDESTREPO $OSTREESRCREPO --depth=-1 "${ref}"
    ostree summary -u --repo=$OSTREEDESTREPO # update summary file
done

# Push rawhide base container image to fedora registry
pushd ./releng
pushd ./scripts
./sync-latest-container-base-image.sh 31
popd
popd

# Tell interested persons that the rsync is done.
send_fedmsg "${fedmsg_json_done}" ${RELEASE} rsync.complete

# Tell everyone by fedmsg about the compose
send_fedmsg "${fedmsg_json_done}" ${RELEASE} complete

# Tell everyone by email about the compose
# "$DESTDIR/logs/depcheck" lets not cat out depcheck for now as it does
# not understand rich dependencies
SUBJECT='Fedora '$RELEASE' compose report: '$SHORTCOMPOSE_ID' changes'
for tomail in $TOMAIL ; do
    cat $DESTDIR/logs/*verbose  | \
         mutt -e "set from=\"$FROM\"" -e 'set envelope_from=yes' -s "$SUBJECT" $tomail
done

# Removed all the older than 14 days composes
find $TARGET_DIR  -xdev -depth -maxdepth 2 -mtime +14  -exec rm -rf {} \;
send_fedmsg "${fedmsg_json_done}" ${RELEASE} cleanup.complete
