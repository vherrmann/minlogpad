#!/usr/bin/env bash

set -e

cd /home/guest
. /etc/profile

cp --reflink=auto --no-preserve=mode --update=none -rT @out@/skeleton-home .

echo -en "\033]0;$1 | Minlogpad\007"
exec tmux new-session -A -s fun -- minlogpad hello.scm
