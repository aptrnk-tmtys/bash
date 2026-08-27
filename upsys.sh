#!/bin/bash

# input
########################################

# variables
LOG='/var/log/upsys.log'

# functions
f_append_log () { echo "`date` $1" >> $LOG ; }

f_update_apt () {
	apt -y update ;f_append_log "Update Complete"
	apt -y upgrade ;f_append_log "Upgrade Complete"
	apt -y autoclean ;f_append_log "Autoclean Complete"
	apt -y autoremove ;f_append_log "Autoremove Complete" ; }

f_update_dnf () {
	dnf -y check-update ;f_append_log "Update Complete"
	dnf -y upgrade ;f_append_log "Upgrade Complete"
	dnf -y clean packages ;f_append_log "Autoclean Complete"
	dnf -y autoremove ;f_append_log "Autoremove Complete" ; }

# process
########################################

echo "`date` Script Start" > $LOG
f_append_log "Reference: `readlink -f $0`"

# filter package manager
if [[ `apt --version` ]] ;then
	f_update_apt
elif [[ `dnf --version` ]] ;then
	f_update_dnf
else
	echo "Error: Acceptable package manager not found." ;exit
fi

# output
########################################
echo '' ;cat $LOG
