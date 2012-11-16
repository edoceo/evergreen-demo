#!/bin/bash

set -o errexit

# Force Kills OpenSRF and OpenILS Processes

if [[ $# == 0 ]]
then
   arg="stop start"
else
   arg=$@
fi

function stack_stop()
{
  # Kill Apache
  /etc/init.d/apache2 stop
  /etc/init.d/opensrf stop
  /etc/init.d/ejabberd stop
  /etc/init.d/memcached stop
  /etc/init.d/postgresql-9.1 stop

  while pidof apache2
  do
    echo "kill: Apache"
    kill -INT $(pidof apache2)
    /etc/init.d/apache2 zap
    sleep 1
  done

  x=$(ps -eo cmd | grep OpenSRF | wc -l )
  if [[ $x > 1 ]]
  then
    echo "There are loads of OpenSRF processes running"
    kill $(ps -eo pid,cmd |awk '/OpenSRF/ { print $1 }')
  fi
  rm -f /openils/var/log/*log
  rm -f /openils/var/run/opensrf/*pid

  while pidof ejabberd
  do
    echo "eJabberd is running"
    # /etc/init.d/ejabberd stop
    # kill -INT $(pidof beam.smp)
    exit
  done
  # beam core process
  while pidof epmd >/dev/null
  do
    echo "Killing empd"
    kill $(pidof epmd)
  done

  # Kill Memcached
  if pidof memcached >/dev/null
  then
    echo "Memcache Still Running"
    # /etc/init.d/memcached stop
    # kill -INT $(pidof memcached)
    exit
  fi

  # Kill PostgreSQL
  if pidof postmaster >/dev/null
  then
    echo "postgresql still running?"
    exit
  fi
}

function stack_start()
{
    /etc/init.d/postgresql-9.1 start
    /etc/init.d/memcached start
    /etc/init.d/ejabberd start
    sleep 4
    /etc/init.d/opensrf start
    sleep 4
    /etc/init.d/apache2 start
}

#
#
for x in $arg
do
  case $x in
  start)
    stack_start
    ;;
  stop)
    stack_stop
    ;;
  esac
done
