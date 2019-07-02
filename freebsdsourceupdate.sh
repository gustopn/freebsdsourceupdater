#!/bin/sh -x

updateJails() {
  jailpathlist="$(grep -e "{\$" /etc/jail.conf | awk '{ print "/jail/" $1 }')"

  for jailpathinstance in $jailpathlist
  do \
    export DESTDIR="$jailpathinstance"
    echo $DESTDIR
    unset DESTDIR
  done
}

updateJails
