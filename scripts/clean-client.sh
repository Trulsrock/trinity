#!/usr/bin/env sh

[ $# -gt 0 ] && DEBUG_BUILD="TRUE"
. ./trinity.conf $1

cd ${CLIENT}

for DIR in Buildings Cameras dbc maps mmaps vmaps
do
  [ -d ${DIR} ] && rm -r ${DIR}
done

