#!/usr/bin/env sh


Rebuild() {
  ARGS=""
  ARGS="${ARGS} -DCMAKE_INSTALL_PREFIX=${WOWDIR}"
  ARGS="${ARGS} -DSCRIPTS='dynamic'"
  ARGS="${ARGS} -DTOOLS=1"

  ARGS="${ARGS} -DWITH_WARNINGS=1"
  ARGS="${ARGS} -DWITH_COREDEBUG=0"
  ARGS="${ARGS} -DUSE_COREPCH=1"
  ARGS="${ARGS} -DUSE_SCRIPTPCH=1"
  ARGS="${ARGS} -DSERVERS=1"
  ARGS="${ARGS} -DNOJEM=0"
  ARGS="${ARGS} -DCMAKE_BUILD_TYPE=RelWithDebInfo"
  ARGS="${ARGS} -DCMAKE_C_FLAGS='-Werror' -O0"
  ARGS="${ARGS} -DCMAKE_CXX_FLAGS='-Werror' -O0"
  ARGS="${ARGS} -DASAN=1"

  mkdir -p ${TRINITY_BASE}/build
  cd ${TRINITY_BASE}/build
  cmake ../
  make -j 20
}

################################################################################
Install() {
  if [ -d ${TRINITY_BASE}/build ]
  then
    cd ${TRINITY_BASE}/build 
    make install

    [ ! -d ${WOWETC} ] && mkdir ${WOWETC}
    [ ! -d ${WOWSQL} ] && mkdir ${WOWSQL}
    [ ! -d ${WOWLOGS} ] && mkdir ${WOWLOGS}
    [ ! -d ${WOWDATA} ] && mkdir ${WOWDATA}

  fi
}
################################################################################
# main part of script
################################################################################
DAY=$(date +'%A')
echo "Which Day: ${DAY} ? \c"
read REPLY
[ ! -z ${REPLY} ] && DAY=${REPLY}

. ./trinity.conf 

Rebuild
Install
echo "Wowdir ${WOWDIR}"
