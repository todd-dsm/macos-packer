#!/usr/bin/env bash
# shellcheck disable=SC1091,SC2154
#  PURPOSE: A trivial wrapper to ease the building of the ISO (DMG) macOS
#           installer. I'm getting too old to remember the options. This script
#           only takes a minute or so to run.
# -----------------------------------------------------------------------------
#  PREREQS: a)
#           b)
#           c)
# -----------------------------------------------------------------------------
#  EXECUTE:
# -----------------------------------------------------------------------------
#     TODO: 1)
#           2)
#           3)
# -----------------------------------------------------------------------------
#   AUTHOR: Todd E Thomas
# -----------------------------------------------------------------------------
#  CREATED: 2017/02/17
# -----------------------------------------------------------------------------
#set -x


###----------------------------------------------------------------------------
### VARIABLES
###----------------------------------------------------------------------------
# Pull in Variable common to both scripts
source vars-build
###----------------------------------------------------------------------------
declare -a buildDirs=("$inst_source" "$isoDir")


###----------------------------------------------------------------------------
### FUNCTIONS
###----------------------------------------------------------------------------
checkDir() {
    bldDir="$1"
    printf '\n%s\n' "Checking directory: $bldDir"
    if [[ ! -d "$bldDir" ]]; then
        printf '%s\n' "  Directory does not exist; creating it."
        mkdir "$bldDir"
    else
        printf '%s\n' "  Directory exists; all clear."
    fi
}


###----------------------------------------------------------------------------
### MAIN PROGRAM
###----------------------------------------------------------------------------
### Verify things exist
###---
for dir in "${!buildDirs[@]}"; do
    checkDir "${buildDirs[$dir]}"
done


###---
### Remove any previous .dmg file if it exists
###---
if [[ -f "$isoURL" ]]; then
    rm -f "$isoURL"
    printf '\n%s\n\n' "Removing current installer: $isoURL"
    rm -f "$isoURL"
fi


###---
### Build the macOS Install DMG
###   * Disable Remote Management; it slows response times for everything.
###   * Pull from the install source.
###   * Drop the DMG where the other ISOs go
###---
sudo scripts/prep/iso_prep.sh \
    -D DISABLE_REMOTE_MANAGEMENT  \
    "$inst_source" \
    "$isoDir"


###---
### REQ
###---


###---
### fin~
###---
exit 0
