#!/usr/bin/env sh

Clean() {
  [ -d ${WOWDIR} ] && rm -rf ${WOWDIR}
  [ -d ${TRINITY_BASE} ] && rm -rf ${TRINITY_BASE}
  [ -d ${TRINITY_LOG} ] && rm -rf ${TRINITY_LOG}

  cd ${CLIENT}

  for DIR in Buildings Cameras dbc maps mmaps vmaps
  do
    [ -d ${DIR} ] && rm -r ${DIR}
  done
}

Clone() {
  TAR=/trinity/backup/TrinityCore-${DAY}.tgz
  mkdir -p ${BASE_DIR}
  cd ${BASE_DIR}
  [ -d ${TRINITY_BASE} ] && rm -r ${TRINITY_BASE}
  [ ! -d TrinityCore ] && [ -f ${TAR} ] && tar xzf ${TAR}
} 

Build() {
  ARGS=""
  ARGS="${ARGS} -DCMAKE_INSTALL_PREFIX=${WOWDIR}"
  ARGS="${ARGS} -DSCRIPTS='dynamic'"
  ARGS="${ARGS} -DTOOLS=1"

  ARGS="${ARGS} -DWITH_WARNINGS=1"
#  ARGS="${ARGS} -DWITH_COREDEBUG=0"
  ARGS="${ARGS} -DUSE_COREPCH=1"
  ARGS="${ARGS} -DUSE_SCRIPTPCH=1"
  ARGS="${ARGS} -DSERVERS=1"
  ARGS="${ARGS} -DNOJEM=0"
  ARGS="${ARGS} -DCMAKE_BUILD_TYPE=Debug"
#  ARGS="${ARGS} -DCMAKE_BUILD_TYPE=RelWithDebInfo"
  ARGS="${ARGS} -DCMAKE_C_FLAGS='-Werror'"
  ARGS="${ARGS} -DCMAKE_CXX_FLAGS='-Werror'"
  ARGS="${ARGS} -DASAN=1"

  echo "================= BUILD COMMAND =============" 
  echo "cmake ../ ${ARGS}"

  mkdir -p ${TRINITY_BASE}/build
  cd ${TRINITY_BASE}/build
  cmake ../ ${ARGS}
  make -j 20
}

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
Maps() {
mkdir -p ${WOWDATA}

cd ${CLIENTMAPS}
cp -r dbc maps vmaps mmaps ${WOWDATA}/

}
################################################################################
TrinityDatabases() {
cat <<- eoCAT
-- DROP DATABASE IF EXISTS world;
-- DROP DATABASE IF EXISTS auth;
-- DROP DATABASE IF EXISTS characters;

CREATE USER IF NOT EXISTS 'trinity'@'localhost' IDENTIFIED BY '${TRINITY_PASS}' WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0;
CREATE USER IF NOT EXISTS 'trinity'@'192.168.%' IDENTIFIED BY '${TRINITY_PASS}' WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0;

GRANT USAGE ON * . * TO 'trinity'@'localhost';
GRANT USAGE ON * . * TO 'trinity'@'${WORLDHOST}';

CREATE DATABASE IF NOT EXISTS world      DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
CREATE DATABASE IF NOT EXISTS characters DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
CREATE DATABASE IF NOT EXISTS auth       DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;

GRANT ALL PRIVILEGES ON world      . * TO 'trinity'@'localhost'    WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON auth       . * TO 'trinity'@'localhost'    WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON characters . * TO 'trinity'@'localhost'    WITH GRANT OPTION;

GRANT ALL PRIVILEGES ON world      . * TO 'trinity'@'${WORLDHOST}' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON auth       . * TO 'trinity'@'${WORLDHOST}' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON characters . * TO 'trinity'@'${WORLDHOST}' WITH GRANT OPTION;
eoCAT
}
################################################################################
DatabaseRefresh() {
  [ ! -d ${WOWSQL} ] && mkdir ${WOWSQL}
  
  TrinityDatabases > ${WOWSQL}/trinity_databases.sql
  ls -l ${WOWSQL}/trinity_databases.sql
  
  cat ${WOWSQL}/trinity_databases.sql | sshpass -p "${TRINITY_PASS}" ssh ${MYSQL_HOST} mysql --user=trinity --password="${TRINITY_PASS}"
}
################################################################################
GetSql() {
  DATA_URL=$(/trinity/scripts/dblatest.py)
  
  [ ! -d ${WOWSQL} ] && mkdir ${WOWSQL}

  LATEST_7Z=$(basename $(echo ${DATA_URL} | cut -d':' -f2-))
  LATEST_SQL="${LATEST_7Z%.7z}.sql"

  echo "Compressed: ${LATEST_7Z}"
  echo "Unzipped  : ${LATEST_SQL}"
  echo "Output    : ${WOWSQL}/${LATEST_7Z}"
  
  [ -f ${LATEST_SQL} ] && rm ${LATEST_SQL}
  [ -f ${LATEST_7Z} ] && rm ${LATEST_7Z}
  [ -f ${WOWSQL}/${LATEST_7Z} ] && rm ${WOWSQL}/${LATEST_7Z}

  find ${WOWBIN} -type f -name \*.sql -exec rm {} \;
  
  wget --quiet ${DATA_URL}
  p7zip --decompress --keep --force ${LATEST_7Z} 
  
  mv ${LATEST_SQL} ${WOWBIN}/
  mv ${LATEST_7Z} ${WOWSQL}/
  
  ls -l ${WOWBIN}/*.sql
}
################################################################################
DebugRun() {
cat <<- eoDebugRun
# gdb -x crashreport.gdb ./worldserver
cd ${WOWBIN}
mkdir -p worldasan
ASAN_OPTIONS=halt_on_error=0:verbosity=1:log_path=worldasan/worldasan:detect_stack_use_after_return=1 LSAN_OPTIONS=verbosity=1:log_threads=1 gdb ./worldserver
eoDebugRun
}
################################################################################
Configure() {
set -x
  DebugRun > ${WOWBIN}/debug-run.sh
  chmod u+rwx ${WOWBIN}/debug-run.sh

  cp ${WOWETC}/authserver.conf.dist ${WOWETC}/authserver.conf
  cp ${WOWETC}/worldserver.conf.dist ${WOWETC}/worldserver.conf

  sed --in-place "s/127.0.0.1;3306;trinity;trinity;/${MYSQL_HOST};3306;trinity;${TRINITY_PASS};/" ${WOWETC}/authserver.conf
  sed --in-place "s/127.0.0.1;3306;trinity;trinity;/${MYSQL_HOST};3306;trinity;${TRINITY_PASS};/" ${WOWETC}/worldserver.conf
  sed --in-place "s/Metric.Enable = 0/Metric.Enable = 1/"         ${WOWETC}/worldserver.conf
  sed --in-place 's@DataDir\ =\ "."@DataDir = "../data"@g'        ${WOWETC}/worldserver.conf
  sed --in-place 's@LogsDir\ =\ ""@LogsDir = "../logs"@g'         ${WOWETC}/worldserver.conf
  sed --in-place "s/Ra.Enable = 0/Ra.Enable = 1/"                 ${WOWETC}/worldserver.conf
  sed --in-place "s/SOAP.Enabled = 0/SOAP.Enabled = 1/"           ${WOWETC}/worldserver.conf
  sed --in-place "s/MaxCoreStuckTime\ =\ 60/MaxCoreStuckTime = 0/" ${WOWETC}/worldserver.conf

  ls -l ${WOWETC}/worldserver.conf
  ls -l ${WOWETC}/authserver.conf
}
################################################################################
# main part of script
################################################################################
DAY=$(date +'%A')

. ./trinity.conf 

Clean
Clone
Build
Install
Maps
GetSql
Configure
DatabaseRefresh

echo "Wowdir ${WOWDIR}"
