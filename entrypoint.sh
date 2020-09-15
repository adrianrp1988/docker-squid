#!/bin/bash
set -e

parse_log_conf() {
if [[ -n ${SQUID_LOG_DIR} ]]; then
  sed -i 's+#Logs+access_log stdio:'${SQUID_LOG_DIR}'/access.log+g' /etc/squid/squid.conf
  if [[ -n ${SQUID_CACHE_DIR} ]]; then
    sed -i 's+#LogsCache+
    #Cache dir Logs:
    cache_log stdio:'${SQUID_LOG_DIR}'/cache.log
    cache_store_log stdio:'${SQUID_LOG_DIR}'/store.log
    +g' /etc/squid/squid.conf
  else
    sed -i 's+#LogsCache++g' /etc/squid/squid.conf
  fi
else
  sed -i 's+#LogsCache++g' /etc/squid/squid.conf
  sed -i 's+#Logs++g' /etc/squid/squid.conf
fi
}

parse_cache_conf() {
if [[ -n ${SQUID_CACHE_DIR} ]]; then
  sed -i 's+#Cache+
  cache_effective_user proxy
  cache_effective_group proxy

  # Leave coredumps in the first cache dir
  coredump_dir '${SQUID_CACHE_DIR}'
  +g' /etc/squid/squid.conf
else
  sed -i 's+#Cache++g' /etc/squid/squid.conf
fi
}

parse_basic_conf(){
  if [[ -n ${HTTP_PORT} ]]; then
    sed -i 's/{{HTTP_PORT}}/'${HTTP_PORT}'/g' /etc/squid/squid.conf
  else
    sed -i 's/{{HTTP_PORT}}/3128/g' /etc/squid/squid.conf
  fi

  if [[ -n ${VISIBLE_HOSTNAME} ]]; then
    sed -i 's/{{VISIBLE_HOSTNAME}}/'${VISIBLE_HOSTNAME}'/g' /etc/squid/squid.conf
  else
    sed -i 's/{{VISIBLE_HOSTNAME}}/squid5/g' /etc/squid/squid.conf
  fi
}

parse_custom_conf(){
if [[ -n ${CUSTOM_CONFIG_FILE} ]]; then
  sed -i 's+#Custom+include /etc/squid/conf.d/'${CUSTOM_CONFIG_FILE}'+g' /etc/squid/squid.conf
else
  sed -i 's/#Custom/http_access allow all/g' /etc/squid/squid.conf
fi
}

parse_log_conf
parse_cache_conf
parse_basic_conf
parse_custom_conf

# allow arguments to be passed to squid
if [[ ${1:0:1} = '-' ]]; then
  EXTRA_ARGS="$@"
  set --
elif [[ ${1} == squid || ${1} == $(which squid) ]]; then
  EXTRA_ARGS="${@:2}"
  set --
fi

# default behaviour is to launch squid
if [[ -z ${1} ]]; then
  if [[ ! -d ${SQUID_CACHE_DIR}/00 ]]; then
    echo "Initializing cache..."
    sudo $(which squid) -N -f /etc/squid/squid.conf -z
  fi
  echo "Starting squid..."
  exec sudo $(which squid) -f /etc/squid/squid.conf -NYCd 1 ${EXTRA_ARGS}
else
  exec "$@"
fi


