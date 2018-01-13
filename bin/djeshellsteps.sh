#!/bin/bash
#############################################################################
# djeshellsteps.sh - Write Shell Script with steps and possibility to rerun #
# them from where last problem occures                                      #
#############################################################################
# Author: Jerome DESMOULINS - http://www.desmoulins.fr                      #
# Version: 1.00 - March, 2007                                               #
# Build #$Revision-Id$                                                      #
# Mail: jerome@desmoulins.fr                                                #
#############################################################################



### Internal variables ###
DJSVersion="1.00"
DJSMustRestart=0
DJSRestartStep=0
DJSEndOfSteps=0
DJSStartTime=0
DJSEndTime=0
DJSScriptParams=$*
DJSDebugMode=0
DJSScriptPID=$$

# Check if optional variables has been set. If not, setting default values #
if [ -z "$DJSOption_SummaryInfosToStdout" ]
then
  DJSOption_SummaryInfosToStdout=1
fi
if [ -z "$DJSOption_StdoutEnabled" ]
then
	DJSOption_StdoutEnabled=1
fi


#############################################################################
# Function: ReadConfigFile                                                  #
#############################################################################
# Arguments: Configuration File (optional)                                  #
# This function read variable from configuration file and assign them as    #
# shell variable                                                            #
#############################################################################
ReadConfigFile()
{
  set +x
  if [ -z "$1" ]
  then
    DJSConfigFile="$CfgDir/$ShellName.cfg"
  else
    DJSConfigFile="$1"
  fi
  echo "Reading configuration file $DJSConfigFile..."
  if [ -f $DJSConfigFile ] 
  then
    . $DJSConfigFile
    echo "Configuration values loaded."
  else
    echo "[ERROR] $DJSConfigFile does not exist. Failed to read configuration file!"
  fi
}

#############################################################################
# Function: WriteSeparator                                                  #
#############################################################################
# Arguments: None                                                           #
# This function writes a separator line on LogFile                          #
#############################################################################
WriteSeparator()
{
  set +x
  echo "##############################################################################"
}


#############################################################################
# Function: TimeBanner                                                      #
#############################################################################
# Arguments: None                                                           #
# This function write a banner with YYYY/MM/DD HH:MM:SS                     #
#############################################################################
TimeBanner()
{
	set +x
	echo -n "[`date +%Y/%m/%d` `date +%H:%M:%S`]"
}


#############################################################################
# Function: CreateRstFile                                                   #
#############################################################################
# Arguments: Step, ErrorCode                                                #
# This function create rst file, with error step, and shell return code     #
#############################################################################
CreateRstFile()
{
	echo "STEP $1 - RETURN CODE $2" > $LogDir/$ShellName.rst
	if test $? -ne 0
	then
		echo "Failed to write restart file contents. (Error 501)"
		exit 501
	fi
}

#############################################################################
# Function: RemoveRstFile                                                   #
#############################################################################
# Arguments: None                                                           #
# This function remove rst file                                             #
#############################################################################
RemoveRstFile()
{
	if test -f $LogDir/$ShellName.rst
	then
		rm $LogDir/$ShellName.rst
		if test $? -ne 0
		then
  		  echo "Failed to remove restart file contents. (Error 502)"
		  exit 502
		fi
	fi
}

#############################################################################
# Function: RemovePidFile                                                   #
#############################################################################
# Arguments: None                                                           #
# This function remove pid file                                             #
#############################################################################
RemovePidFile()
{
	if test -f $LogDir/$ShellName.pid
	then
		rm $LogDir/$ShellName.pid
		if test $? -ne 0
		then
  		  echo "Failed to remove pid file. (Error 506)"
		  exit 506
		fi
	fi
}

#############################################################################
# Function: WriteSummaryInfo                                                #
#############################################################################
# Arguments: Information String                                             #
# This function writes summary information to stdout, if option enabled     #
#############################################################################
WriteSummaryInfo()
{
    if test $DJSOption_SummaryInfosToStdout -eq 1
    then
      echo "`TimeBanner` $1"
    fi
}

#############################################################################
# Function: BeginSteps                                                      #
#############################################################################
# Arguments: None                                                           #
# This function writes the begining of LogFile                              #
#############################################################################
BeginSteps()
{
  set +x
  DJSStartTime=`date +%s`
  ### Creating Log File ###
  touch $LogFile
  if test $? -ne 0
  then
    echo "Failed to write log file. (Error 503)"
    exit 503
  fi
  ### Checking if program is already running ###
  if [ -f $LogDir/$ShellName.pid ]
  then
    OldPID=`cat $LogDir/$ShellName.pid`
    echo "`TimeBanner` Failed to start $ShellName. Another instance of this script is already running with PID $OldPID (Error 504)"
	exit 504
  fi  
  ### Checking for rst file ###
  if [ -f $LogDir/$ShellName.rst ]
  then
    DJSRestartStep=`cat $LogDir/$ShellName.rst | awk '{ print $2}'`
	WriteSummaryInfo "Shell is restarting at step $DJSRestartStep"
	WriteSummaryInfo "Logfile is: ${LogFile}"
  else
    WriteSummaryInfo "Shell $ShellName is starting"
	WriteSummaryInfo "Logfile is: ${LogFile}"
  fi  
  exec 6>&1 # Redirect all outputs to logfile
  exec 3>&1
  # Copy log file to stdout, or not
  if test $DJSOption_StdoutEnabled -eq 1
  then
    exec > >(tee -a $LogFile)
  else	
    exec >> $LogFile
  fi	
  exec 2>&1
  WriteSeparator
  printf "# DjeShellSteps v%-5s                                                       #\n" ${DJSVersion}
  printf "# Begin of %-43s %-21s #\n" $ShellName "`TimeBanner`"
  printf "# Script launched by %-39s (PID: %-8s) #\n" "`whoami`@`hostname`" $DJSScriptPID
  printf "# Parameters: %-62s #\n" $DJSScriptParams
  if [ $DJSDebugMode -eq 1 ]
  then
    printf "#   -> DEBUG MODE activated.                                                 #\n"
  fi
  ### Writing PID File ###
  echo $DJSScriptPID > $LogDir/$ShellName.pid
  if test $? -ne 0
  then
    echo "Failed to write pid file. (Error 505)"
    exit 505
  fi
  WriteSeparator
  ### Search for rst file - If founded, restart shell on step from previous execution ###
  if [ -f $LogDir/$ShellName.rst ]
  then
    DJSRestartStep=`cat $LogDir/$ShellName.rst | awk '{ print $2}'`
    echo "
  ____          _             _   
 |  _ \\ ___ ___| |_ __ _ _ __| |_ 
 | |_) / _ \\ __| __/ _\` | '__| __|
 |  _ <  __\\__ \\ |_ (_| | |  | |_ 
 |_| \\_\\___|___/\\__\\__,_|_|   \\__|

"
    echo "Info: Restart file was found. Restarting shell from step $DJSRestartStep"
    DJSMustRestart=1
  fi
  # Launch ExitStep at the end of Shell Script
  trap 'ExitStep' 0
  set -e
}


#############################################################################
# Function: Step                                                            #
#############################################################################
# Arguments: 1: Step_Number, 2: Step_Description                            #
# This function is called for each new step                                 #
#############################################################################
Step()
{
  set +x
  Step=$1
  exec 1>&6 6>&-      # Restaure stdout and close File Descriptor #6.
  if [ $DJSMustRestart -eq 1 -a $Step -lt $DJSRestartStep ] 
  then
    WriteSummaryInfo "Skipping step $Step"
  else
    WriteSummaryInfo "Step $Step is starting ($2)"
  fi
  exec 6>&1 # Redirect all outputs to logfile
  exec 3>&1
  # Copy log file to stdout, or not
  if test $DJSOption_StdoutEnabled -eq 1
  then
    exec > >(tee -a $LogFile)
  else	
    exec >> $LogFile
  fi
  exec 2>&1 
  
  # Write Step informations on LogFile
  echo
  echo
  WriteSeparator
  printf "# Step %-47s %-21s #\n" $1 "`TimeBanner`"
  printf "# %-74s #\n" "$2"
  WriteSeparator
  echo "STEP $Step - WORK IN PROGRESS" > $LogDir/$ShellName.rst

  #Test if restart point exists and determine if this step must be run or not
  if [ $DJSMustRestart -eq 1 ]; then
    if [ $Step -ge $DJSRestartStep ]; then
      echo "Info: RESTART MODE - This step will be ReRun"
      RunThisStep=1
    else
      echo "Info: RESTART MODE - This step will be ignored"
      RunThisStep=0
    fi
  else
    #If no restart file, we return 1, to rnu the step
    RunThisStep=1 
  fi
  if [ $DJSDebugMode -eq 1 ]
  then
    set -x
  fi	
}


#############################################################################
# Function: EndSteps                                                        #
#############################################################################
# Arguments: None                                                           #
# This function writes the end of script                                    #
#############################################################################
EndSteps()
{
  set +x
  echo
  echo
  WriteSeparator
  printf "# End of %-45s %-21s #\n" $ShellName "`TimeBanner`"
  DJSEndTime=`date +%s`
  DjeExecTime=`expr $DJSEndTime - $DJSStartTime`
  printf "# Execution time: %-58s #\n" "$DjeExecTime second(s)."
  WriteSeparator
  echo
  DJSEndOfSteps=1
  exec 1>&6 6>&-      # Restaure stdout and close File Descriptor #6.
  WriteSummaryInfo "Shell $ShellName is SUCCESS."
  WriteSummaryInfo "Execution time: $DjeExecTime seconds."
}


#############################################################################
# Function: ExitStep                                                        #
#############################################################################
# Arguments: None                                                           #
# This function is called at the end of script, or when an error occures    #
#############################################################################
ExitStep()
{
  ReturnCode=$?
  set +x
  if [ $DJSEndOfSteps -ne 1 ]; then
    echo
    echo "
  _____                     
 | ____|_ __ _ __ ___  _ __ 
 |  _| | '__| '__/ _ \| '__|
 | |___| |  | | | (_) | |   
 |_____|_|  |_|  \___/|_|   

"
    WriteSeparator
    printf "# End of %-45s %-21s #\n" $ShellName "`TimeBanner`"
    printf "# PROBLEM ON THIS STEP - EXITING SHELL SCRIPT WITH RETURN CODE %-13s #\n" $ReturnCode
    DJSEndTime=`date +%s`
    printf "# Execution time: %-58s #\n" "`expr $DJSEndTime - $DJSStartTime` second(s)."
    WriteSeparator
    echo "STEP $Step - RETURN CODE $ReturnCode" > $LogDir/$ShellName.rst
    echo "Info: Restart file has been created, for step $Step"
    echo
    mv $LogFile ${LogFile}_E
    exec 1>&6 6>&-      # Restaure stdout and close File Descriptor #6.
	WriteSummaryInfo "New Logfile is: ${LogFile}_E"
	WriteSummaryInfo "Restart file is: $LogDir/$ShellName.rst"
    echo "Exit shell, aborted on step $Step (Returned code: $ReturnCode)"
	RemovePidFile
    exit $ReturnCode
  fi
  # If all is right, we delete the restart file
  RemoveRstFile 
  RemovePidFile
}


### Parsing configuration file to get config values ###
DJSScriptPath=`dirname $0`
if test -f "$DJSScriptPath/djeshellsteps.cfg"
then
	ReadConfigFile "$DJSScriptPath/djeshellsteps.cfg"
elif test -f "$DJSScriptPath/../cfg/djeshellsteps.cfg"
then
	ReadConfigFile "$DJSScriptPath/../cfg/djeshellsteps.cfg"
fi

### External variables ###
#If ShellName was not specified, determine it
if [ -z "$ShellName" ]
then
	DJSFullFilename=$(basename $0)
	ShellName=${DJSFullFilename%.*}
fi
#Setting LogFile, based on ShellName
LogFile=$LogDir/${ShellName}_`date +%Y%m%d_%H%M%S`.log


### Parsing Shell Script command line, to get internal parameters ###
for X in "$@"
do
    case "$X" in
	  ### Debug Mode ###
       --debug) 
	     DJSDebugMode=1
		 shift
		 ;;
      ### Restart from specific step ###		 
	   --fromstep)
	     RstStep=$2
		 echo Restarting from Step $RstStep
		 CreateRstFile $RstStep 0
	     shift
		 shift
	     ;;
      ### Restart from first step ###		 
	   --fromscratch)
	     RemoveRstFile
		 echo Restarting from first step
		 shift
		 ;;
      ### Display last execution log ###
       --lastlog)
	      shift
          more `ls -rt $LogDir/${ShellName}*.log* | tail -1`
		  if test -f $LogDir/$ShellName.rst
	      then
		    echo RstFile exists.
			cat $LogDir/$ShellName.rst
	      fi
          exit 0
          ;;
     ### Kill scrpit ###
      --kill)
	    shift
        if test -f $LogDir/$ShellName.pid
	    then
		  echo "`TimeBanner` Killing PID `cat $LogDir/$ShellName.pid`"
		  kill `cat $LogDir/$ShellName.pid`
		  RemovePidFile
		else
          echo "`TimeBanner` $ShellName is not running."		
        fi
		exit 0
		;;
     ### Force STDOUT output ###
      --stdout)
	    shift
        DJSOption_StdoutEnabled=1
		;;
     ### Force STDOUT Summary output ###
      --stdoutsummary)
	    shift
        DJSOption_SummaryInfosToStdout=1
		;;
    esac
done

BeginSteps
#############################################################################
#                              End of script                                #
#############################################################################
