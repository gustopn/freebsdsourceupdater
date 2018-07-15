#!/bin/sh -x
# by Lars Schotte (c) 2018

# define general variables to be used
export updateFreeBSDfoundCPUs=$( sysctl -n hw.ncpu )
export updateFreeBSDparallelJobs=$( expr "$updateFreeBSDfoundCPUs" + 1 )

# define functions first
# IMPORTANT: all of these functions assume that we are in /usr/src/ directory already!
find_kernelConfFileName() {
  kernelConfIdent=$(uname -i)
  if [ -n "$kernelConfIdent" ]
  then \
    echo "$kernelConfIdent"
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
  subversionbinfile="/usr/local/bin/svn"
  if [ -f $subversionbinfile ] && [ -x $subversionbinfile ]
  then \
    svn up >/dev/null
  else \
    svnlite up >/dev/null
  fi
}
updateFreeBSD_kernel() {
  # we need to update build tools anyway, so doing world build here
  export KERNCONF=$(find_kernelConfFileName)
  # what this lacks now is possibility for the user to force building a GENERIC kernel, skipping KERNCONF variable.
  # that however would also need a warning, because that can break things on boot (for example PF firewall with ALTQ)
  make -j"$updateFreeBSDparallelJobs" buildworld >/dev/null \
    && make -j"$updateFreeBSDparallelJobs" buildkernel >/dev/null \
    && make installkernel >/dev/null
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
