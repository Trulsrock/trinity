#!/usr/bin/env sh

# Clone only runs once per day

Clone() {
  [ -f ${TAR} ] && rm -f ${TAR} 
  cd ${CLONE_DIR}
  git clone -b 3.3.5 git://github.com/TrinityCore/TrinityCore.git && tar czf ${TAR} TrinityCore && rm -rf TrinityCore
} 

################################################################################
# main part of script
################################################################################
DAY=$(date +'%A')
TAR=/trinity/backup/TrinityCore-${DAY}.tgz

. ./trinity.conf 

Clone

echo "TAR File: ${TAR}"
