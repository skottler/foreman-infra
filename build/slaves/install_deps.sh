#!/bin/bash

set -e
set -x

if [ -e /etc/redhat-release ]; then
  pm="yum"
else
  pm="apt"
fi

bd="${pm}_packages.txt"

if [ -e "$bd.$SUITE" ]; then
  bd="$bd.$SUITE"
elif ! [ -e "$bd" ]; then
  echo >&2 "$bd does not exist."
  exit 1
fi

sudo $pm install -y $(cat "$bd")
