#!/bin/sh -x

updateJails() {
  jailpathlist="$(grep -E "^([a-z0-9]){2,} {[}]?\$" /etc/jail.conf | awk '{ print "/jail/" $1 }')"

  for jailpathinstance in $jailpathlist
  do \
    export DESTDIR="$jailpathinstance"
    echo $DESTDIR
    unset DESTDIR
  done
}

updateJails
