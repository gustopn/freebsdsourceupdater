#!/bin/sh -x
# by Lars Schotte (c) 2018

# define general variables to be used
export updateFreeBSDfoundCPUs=$( sysctl -n hw.ncpu )
export updateFreeBSDparallelJobs=$( expr "$updateFreeBSDfoundCPUs" + 1 )

# define functions first
# IMPORTANT: all of these functions assume that we are in /usr/src/ directory already!
find_kernelConfFileName() {
  kernelConfIdent=$(uname -i)
  if [ "$kernelConfIdent" == "GENERIC" ]
  then \
    return 1
  else \
    echo "$kernelConfIdent"
    return 0
  fi
}
print_updateFreeBSD_scriptUsage() {
  echo "
  usage:
    source -> update source only
    kernel -> update host kernel
    host -> update host userland
    jails -> update jails userland
    all (default) -> update sources, host kernel, userland and its jails userland
  "
}
updateFreeBSD_sourceOnly() {
  svnlite up >/dev/null
}
updateFreeBSD_kernel() {
  # we need to update build tools anyway, so doing world build here
  make -j"$updateFreeBSDparallelJobs" buildworld >/dev/null && if find_kernelConfFileName >/dev/null
  then \
    make -j"$updateFreeBSDparallelJobs" KERNCONF=$(find_kernelConfFileName) buildkernel >/dev/null
  else \
    make -j"$updateFreeBSDparallelJobs" buildkernel >/dev/null
  fi && make installkernel >/dev/null
}
updateFreeBSD_host() {
  make installworld >/dev/null
}
updateFreeBSD_jails() {
  updateFreeBSD_jailPaths=$( jls -N path )
  if [ -n "$updateFreeBSD_jailPaths" ]
  then \
    for jailDirInstance in $updateFreeBSD_jailPaths
    do \
      if [ -d "$jailDirInstance" ] && [ -f "${jailDirInstance}/etc/rc.conf" ] && [ "$jailDirInstance" != "/" ] && ! ( echo "$jailDirInstance" | grep "//" >/dev/null )
      then \
        make DESTDIR="$jailDirInstance" installworld >/dev/null
      fi
    done
  fi
}
do_all_updateFreeBSD_fromSourceActions() {
  updateFreeBSD_sourceOnly && updateFreeBSD_kernel && updateFreeBSD_host && updateFreeBSD_jails
}

# look if we have a parameter given
# IMPORTANT: We have to move into /usr/src directory first, without it all further processing would be useless!
cd /usr/src && if [ -n "$1" ]
then \
  case "$1" in 
    "source") updateFreeBSD_sourceOnly ;;
    "kernel") updateFreeBSD_kernel ;;
    "jails")  updateFreeBSD_jails ;;
    "host")   updateFreeBSD_host ;;
    "-?")     print_updateFreeBSD_scriptUsage ;;
    "-h")     print_updateFreeBSD_scriptUsage ;;
    "--help") print_updateFreeBSD_scriptUsage ;;
    "all")    do_all_updateFreeBSD_fromSourceActions ;;
    *)        do_all_updateFreeBSD_fromSourceActions ;;
  esac
else \
  do_all_updateFreeBSD_fromSourceActions
fi
