#!/usr/bin/env sh

[ $# -gt 0 ] && DEBUG_BUILD="TRUE"
. ./trinity.conf $DAY

which mapextractor vmap4extractor vmap4assembler mmaps_generator
mkdir -p ${WOWDATA}

cd ${CLIENT}
mapextractor
cp -r dbc maps ${WOWDATA}/

vmap4extractor
mkdir vmaps
vmap4assembler Buildings vmaps
cp -r vmaps ${WOWDATA}/

mkdir mmaps
mmaps_generator
cp -r mmaps ${WOWDATA}/

