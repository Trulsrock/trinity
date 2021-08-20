#!/usr/bin/env sh

[ $# -gt 0 ] && DEBUG_BUILD="TRUE"
. ./trinity.conf $DAY

mkdir -p ${WOWDATA}

cd ${CLIENTMAPS}
cp -r dbc maps vmaps mmaps ${WOWDATA}/

