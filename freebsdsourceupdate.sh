#!/bin/sh -x

export logfile="/tmp/freebsdsourceupdate_$(date +%s).log"

if [ ! -e "$logfile" ]
then \
  touch "$logfile"
else \
  echo "ERROR: logfile exists already or can not create" >&2
  exit 1
fi

export numcpucores=$( sysctl -n hw.ncpu )

getFreeBSDsource() {
  [ -z "$logfile" ] && exit 1
  subversionbin=$(whereis svn | awk '{ print $2 }')
  if [ -z "$subversionbin" ]
  then \
    subversionbin=$(whereis svnlite | awk '{ print $2 }')
  fi
  if [ -z "$subversionbin" ] || [ ! -x "$subversionbin" ]
  then \
    echo "ERROR: no subversion found" >&2
    exit 1
  fi
  if cd /usr/src
  then \
    if "$subversionbin" up >> "$logfile"
    then \
      true
    else \
      "$subversionbin" checkout https://svn.FreeBSD.org/base/stable/12 /usr/src >> "$logfile"
    fi
  fi
}

buildNewSystem() {
  [ -z "$logfile" ] || [ -z "$numcpucores" ] && exit 1
  if cd /usr/src
  then \
    if make -j "$numcpucores" buildworld >> "$logfile"
    then \
      if make -j "$numcpucores" kernel >> "$logfile"
      then \
        make installworld >> "$logfile"
      else \
        echo "ERROR: kernel failed" >&2
        exit 1
      fi
    else \
      echo "ERROR: build failed" >&2
      exit 1
    fi
  fi
}

updateJails() {
  [ -z "$logfile" ] && exit 1
  jailpathlist="$(grep -E "^([a-z0-9]){2,} {[}]?\$" /etc/jail.conf | awk '{ print "/jail/" $1 }')"
  if cd /usr/src
  then \
    for jailpathinstance in $jailpathlist
    do \
      make DESTDIR="$jailpathinstance" installworld >> "$logfile"
    done
  fi
}

getFreeBSDsource && buildNewSystem && updateJails
