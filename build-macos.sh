#!/usr/bin/env bash
# shellcheck disable=SC1091,SC2086
#  PURPOSE: A QnD scipt to build new macOS systems in VMware Fusion with packer.
#           This is where https://github.com/todd-dsm/mac-ops gets tested.
# -----------------------------------------------------------------------------
#  PREREQS: a) A current version of VMware Fusion
#           b)
# -----------------------------------------------------------------------------
#  EXECUTE:
# -----------------------------------------------------------------------------
#     TODO: 1)
#           2)
#           3)
# -----------------------------------------------------------------------------
#   AUTHOR: Todd E Thomas
# -----------------------------------------------------------------------------
#  CREATED: 2016/09/00
# -----------------------------------------------------------------------------
set -x


###----------------------------------------------------------------------------
### Variables
###----------------------------------------------------------------------------
source vars-build
###----------------------------------------------------------------------------
declare statusCount='0'
#export  PACKER_NO_COLOR='false'
declare packerFile='macos-sierra-10.12.json'
declare vmDir="$VMWARE_STORAGE/osx/sierra"
declare vagrantBox="$HOME/vms/vagrant/boxes/mac_osx/sierra.box"
declare isoDir="$HOME/Downloads/isos/osx"
declare osxISO='OSX_InstallESD_10.12.3_16D32.dmg'
declare isoURL="$isoDir/$osxISO"
declare defsValBld="-only=vmware-iso -var iso_url=$isoURL $packerFile"
# Packer may grow to include more testing in the future; form the arrays:
declare -A pSubsActions;                declare -a subCMDs;
pSubsActions["validate"]="$defsValBld"; subCMDs+=( "validate" )
pSubsActions["inspect"]="$packerFile";  subCMDs+=( "inspect" )


###----------------------------------------------------------------------------
### Functions
###----------------------------------------------------------------------------
### if a step fails there's no need to go any further
failMsg()   {
    echo -e "\n\n    Abort! Abort!    \n\n"
    exit 1
}

# Increase statusCount by 1
passJob() {
    statusCount="$((statusCount+1))"
    #printf '%s\n' "  \$statusCount: $statusCount"
}

# Decrease statusCount by 1
failJob() {
    statusCount="$((statusCount-1))"
    failMsg
    #printf '%s\n' "  \$statusCount: $statusCount"
}


###----------------------------------------------------------------------------
### MAIN PROGRAM
###----------------------------------------------------------------------------
### Esure the old build is gone
###---
if [[ -d "$vmDir" ]]; then
    if ! rm -rf "$vmDir"; then
        printf '\n%s\n' """
        Can't seem to remove: $vmDir
        See what's up. Maybe shut down the old VM first?
        """
    else
        printf '\n%s\n' """
        The vm directory has been removed:
          $vmDir
          Moving on...
        """
    fi
fi

###---
### TEST the build
###---
#set -x
for i in "${!subCMDs[@]}"; do
    # Leverage array index to order associative array params/values
    printf '\n%s\n' "${subCMDs[$i]^}..."
    # Take advantage of word-splitting; do NOT quote the variables
    if ! packer ${subCMDs[$i]} ${pSubsActions[${subCMDs[$i]}]}; then
        printf '%s\n' "  The packer ${subCMDs[$i]} step failed."
        failJob
    else
        printf '%s\n' "  The packer ${subCMDs[$i]} step passed."
        passJob
    fi
done


###---
### If we made it this far, we're ready; build the VM.
###---
if [[ "$statusCount" -ne '2' ]]; then
    failMsg
else
    printf '\n%s\n' "Building the VM..."
    #printf '%s\n' "packer build $defsValBld"
    # Take advantage of word-splitting; do NOT quote the variable
    if ! packer build $defsValBld; then
        printf '\n%s\n' "  The packer build step failed."
    else
        printf '\n%s\n' "  The packer build step passed."
        # Remove the vagrant box
        if [[ -f "$vagrantBox" ]]; then
            printf '%s\n' "  Dumping the Vagrant box..."
            if ! rm -f "$vagrantBox"; then
                printf '%s\n' "  The Vagrant box persists."
            else
                # All clear
                printf '\n%s\n\n' "Ready for Testing!"
            fi
        fi
    fi
fi


###---
### fin~
###---
exit 0
