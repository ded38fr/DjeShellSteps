#!/bin/bash
###########################################################
# File: example1.sh                                       #
# Author: Jerome DESMOULINS - djeshellsteps@desmoulins.fr #
# Description:                                            #
#   DjeShellSteps example 1: sample shell script          #
#   with 3 steps.                                         #
###########################################################

### Calling DjeShellSteps ###
. `dirname $0`/djeshellsteps.sh
BeginSteps

###########################################################
Step 10 "List all files on current directory"
###########################################################
if [ $RunThisStep -eq 1 ]; then
  ls
fi

###########################################################
Step 20 "Sleep for two seconds"
###########################################################
if [ $RunThisStep -eq 1 ]; then
  sleep 2
fi

###########################################################
Step 30 "Display kernel version"
###########################################################
if [ $RunThisStep -eq 1 ]; then
  uname -a
fi

### End of Shell Script ###
EndSteps