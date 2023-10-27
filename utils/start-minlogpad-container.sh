#!/usr/bin/env bash

set -e

hostip="$1"
containerip="$2"
home="$3"

if [ -z "$hostip" ] || [ -z "$containerip" ] || [ -z "$home" ]; then
  echo "usage: $0 hostip containerip /home/dir/for/the/container" >&2
  exit 1
fi

cd backend

[ -e container.nix ] || {
  echo "not found: ./container.nix" >&2
  exit 1
}

[ -d "$home/.skeleton" ] || {
  echo "not found: $home/.skeleton (should be a directory)" >&2
  exit 1
}

system=$(nix-build "<nixpkgs/nixos>" -I nixos-config=./container.nix -A system)
bash=$(nix-build "<nixpkgs/nixos>" -I nixos-config=./container.nix -A pkgs.bash)
iproute2=$(nix-build "<nixpkgs/nixos>" -I nixos-config=./container.nix -A pkgs.iproute2)

dir="$(mktemp -d)"

function cleanup {
    rm -rf -- "$dir"
}

trap cleanup EXIT

cd -- "$dir"
mkdir -p sbin usr/lib
touch usr/lib/os-release

cat > sbin/init <<EOF
#!$bash/bin/bash
$iproute2/bin/ip link set dev host0 up
$iproute2/bin/ip addr add $containerip dev host0
$iproute2/bin/ip route add $hostip dev host0
exec $system/init
EOF

chmod +x sbin/init

systemd-nspawn -n --bind-ro=/nix/store --bind-ro=/nix/var/nix/db --bind="$home":/home --boot -M minlogpad -xD "$dir" &

# uff, not very nice
sleep 1
ifconfig ve-minlogpad $hostip up
