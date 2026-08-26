#!/bin/bash

# Variables
########################################
VVRS='10.8.4'
VPTS='phoronix-test-suite'
FDEB="$VPTS_${VVRS}_all.deb"
VREP="https://github.com/$VPTS/$VPTS"
VURL="$VREP/releases/download/v$VVRS/$FDEB"

# Functions
########################################

# Display help text
f_hlp () { echo "
DESCRIPTION:
  This script installs $VPTS

  Default version: $VVRS
  See: $VURL

OPTIONS:
  -h, --help  Displays this help text.
    $0 -h
  -r, --run   Executes this script.
    $0 -r
" ; exit ; }

# Print error message & help text
f_errr () { echo ;echo "!!! ERROR: $1 !!!" ;f_hlp ; }

# Display variables
f_display () { echo "
RUN=$RUN
VVRS=$VVRS
VPTS=$VPTS
FDEB=$FDEB
VREP=$VREP
VURL=$VURL
" ; }

# Input
########################################

# Filter options
case $1 in
  '-r'|'--run')  RUN='true' ;shift  ;;
  *)  HELP='true' ;shift  ;;
esac

# Check: help
if [[ $HELP == 'true' ]] ;then f_hlp ;fi

# Already installed?
if [[ `$VPTS version` ]] ;then f_errr "$VPTS already installed" ;fi

# Check: root privilege execution
if [[ `whoami` != 'root' ]] ;then f_errr 'use "sudo" for execution' ;fi

# Check: run flag
if [[ $RUN != 'true' ]] ;then exit ;fi

# Processing
########################################
clear

# place .deb file
cd /usr/local/src/
curl -LO $VURL

# install phoronix
apt -y install ./$FDEB

# Output
########################################
$VPTS version
