#!/usr/bin/env bash

. /etc/profile
cd

if [ -e .wait ]; then
  echo "* Am cold spare; waiting for provisioning..." >&2
  tempdir=$(mktemp -d)
  cp .Xauthority .ICEauthority $tempdir/
  read < .wait
  echo "  Am being provisioned." >&2
  cd
  cp $tempdir/.* .
fi

cp --reflink=auto --no-preserve=mode -nrT @out@/skeleton-home .

while :; do
  numberOfClients=$(ps xua | grep "nc localhos[t]" | wc -l)
  if [ "$numberOfClients" -ge 2 ]; then
    echo "$numberOfClients"
  fi
  sleep 1
done | osd_cat -l 1 -d 1 -c purple -A right -p top &

[ -x .xstartup ] && . .xstartup

dwm &
exec emacs --fullscreen hello.scm
