#!/usr/bin/env bash
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
# ENV Stuff
declare inst_source='/Applications/Install macOS Sierra.app'
declare isoDir="$HOME/Downloads/isos/osx"
declare -a buildDirs=("$inst_source" "$isoDir")
# Data Files


###----------------------------------------------------------------------------
### FUNCTIONS
###----------------------------------------------------------------------------
checkDir() {
    bldDir="$1"
    printf '%s\n' "Checking directory: $bldDir"
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
