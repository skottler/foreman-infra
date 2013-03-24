#!/bin/bash

set -u
set -e

check_arg() {
  name="$1"; shift
  arg="$1"; shift

  if [ -z "${arg:-}" ]; then
    echo >&2 "No $name given."
    exit 1
  fi
  if [[ "$arg" =~ [^A-Za-z0-9-] ]]; then
    echo >&2 "Invalid $name: $arg."
    exit 1
  fi
}
cleanup() {
  if ! [ -z "{$chroot:-}" ]; then
    echo "Clean up build environment."
    schroot --end-session --chroot "$chroot"
  fi
}

check_arg "suite" "${SUITE:-}"
check_arg "architecture" "${ARCHITECTURE:-}"
jobname=${JOB_NAME%%/*}
check_arg "job's name" "${jobname:-}"


# Check if we have an schroot by that name
base_chroot="$SUITE-$ARCHITECTURE-sbuild"
if ! schroot -l -c "$base_chroot" > /dev/null 2>&1; then
  echo >&2 "Invalid chroot: $base_chroot."
  exit 1
fi

fullpath=$(readlink -f "$0")
basedir=$(dirname "$fullpath")
jobdir="$basedir/$jobname"

# And check if we have build scripts
if ! [ -d "$jobdir" ]; then
  echo >&2 "$jobdir does not exist or is not a directory."
  exit 1
fi


# Setting up the build environment
trap 'cleanup' EXIT
echo "Prepare build environment."
chroot=$(schroot --chroot "$base_chroot" --begin-session)
if [ -z "$chroot" ]; then
  echo >&2 "Setting up chroot failed."
  exit 1
fi

echo "Setup:"
f="$jobdir/setup"
if [ -d "$f" ]; then schroot --run-session --chroot "$chroot" -u root -- env SUITE="$SUITE" run-parts "$f";
                else schroot --run-session --chroot "$chroot" -u root -- env SUITE="$SUITE" "$f"; fi
echo "Build:"
f="$jobdir/build"
if [ -d "$f" ]; then schroot --run-session --chroot "$chroot"         -- env SUITE="$SUITE" run-parts "$f";
                else schroot --run-session --chroot "$chroot"         -- env SUITE="$SUITE" "$f"; fi
