#!/bin/bash
#############################################################################
# djeshellsteps.sh - Write Shell Script with steps and possibility to rerun #
# them from where last problem occures                                      #
#############################################################################
# Author: Jerome DESMOULINS - http://www.desmoulins.fr                      #
# Version: 1.01 - December, 2015                                            #
# Mail: jerome@desmoulins.fr                                                #
#############################################################################


### Internal variables ###
DJSVersion="1.01"
DJSMustRestart=0
DJSRestartStep=0
DJSEndOfSteps=0
DJSStartTime=0
DJSEndTime=0
DJSScriptParams=$*
DJSDebugMode=0
DJSScriptPID=$$
DJSInternalDebug=0


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
  InternalDebug "IN"
  if [ -z "$1" ]
  then
    DJSConfigFile="$CfgDir/$ShellName.cfg"
  else
    DJSConfigFile="$1"
  fi
  InternalDebug "Config file $DJSConfigFile"
  echo "Reading configuration file $DJSConfigFile..."
  if [ -f $DJSConfigFile ] 
  then
    . $DJSConfigFile
    echo "Configuration values loaded."
  else
    echo "[ERROR] $DJSConfigFile does not exist. Failed to read configuration file!"
  fi
  InternalDebug "OUT"
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
# Function: InternalDebug                                                   #
#############################################################################
# Arguments: DebugText                                                      #
# This internal function is used for debugging purpose                      #
#############################################################################
InternalDebug()
{
  set +x
  bleuclair='\e[1;34m'
  neutre='\e[0;m'
  if [ $DJSInternalDebug -eq 1 ]
  then
    echo -e "`TimeBanner`[DEBUG][${FUNCNAME[ 1 ]}] $1"
  fi
  if [ $DJSDebugMode -eq 1 ]
  then
    set -x
  fi
}


#############################################################################
# Function: CreateRstFile                                                   #
#############################################################################
# Arguments: Step, ErrorCode                                                #
# This function create rst file, with error step, and shell return code     #
#############################################################################
CreateRstFile()
{
	InternalDebug "IN"
	echo "STEP $1 - RETURN CODE $2" > $LogDir/$ShellName.rst
	if test $? -ne 0
	then
		echo "Failed to write restart file contents. (Error 501)"
		exit 501
	fi
	InternalDebug "OUT"
}


#############################################################################
# Function: RemoveRstFile                                                   #
#############################################################################
# Arguments: None                                                           #
# This function remove rst file                                             #
#############################################################################
RemoveRstFile()
{
	InternalDebug "IN"
	if test -f $LogDir/$ShellName.rst
	then
		rm $LogDir/$ShellName.rst
		if test $? -ne 0
		then
  		  echo "Failed to remove restart file contents. (Error 502)"
		  exit 502
		fi
	fi
	InternalDebug "OUT"
}


#############################################################################
# Function: RemovePidFile                                                   #
#############################################################################
# Arguments: None                                                           #
# This function remove pid file                                             #
#############################################################################
RemovePidFile()
{
	InternalDebug "IN"
	if test -f $LogDir/$ShellName.pid
	then
		rm $LogDir/$ShellName.pid
		if test $? -ne 0
		then
  		  echo "Failed to remove pid file. (Error 506)"
		  exit 506
		fi
	fi
	InternalDebug "OUT"
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
# Function: DJSDisplayStatus                                                #
#############################################################################
# Arguments: Display script status                                          #
# This function check script status (Running, or not)                       #
#############################################################################
DJSDisplayStatus()
{
	if test -f $LogDir/$ShellName.pid
	then
		DJSPID=`cat $LogDir/$ShellName.pid`
		if kill -0 $DJSPID > /dev/null 2>&1; then
			DJSStatus="RUNNING"
		else	
			DJSStatus="FAILED "
		fi
	else
		DJSStatus="STOPPED"
	fi
	printf "$ShellName status   [%7s]\n" $DJSStatus
	exit 0
}

#############################################################################
# Function: DJSShowSteps                                                    #
#############################################################################
# Arguments:                                                                #
# Display all steps for the current script                                  #
#############################################################################
DJShowSteps()
{
	echo "Steps for $ShellName:"
	sed -e 's/^[ \t]*//' $0 | grep "^Step" | awk '{ printf("  -Step %s: ",$2); $1=""; $2=""; gsub("\"","",$0); print $0;}'
	exit 0
}


#############################################################################
# Function: DJSShowHelp                                                     #
#############################################################################
# Arguments: Show help message, for DJS script                              #
# This function show script command line help, and exit                     #
#############################################################################
ShowHelp()
{
	printf "%-45s (powered by DjeShellSteps v%s)\n" $0 $DJSVersion
	echo "                                              (c) Jerome DESMOULINS"
	echo "Usage:"
	
	OIFS=$IFS; IFS="|";
	HelpArray=($Help);

	Options=""
	for ((i=0; i<${#HelpArray[@]}; ++i));
	do
		myOpt="$(echo ${HelpArray[$i]} | cut -d';'  -f1)"
		Options=$Options" "$myOpt
	done

	echo "  $0$Options"

	if [ ! -z "$Help" ]
	then
		echo "Where:"
	fi	
	for ((i=0; i<${#HelpArray[@]}; ++i));
	do
		myOpt="$(echo ${HelpArray[$i]} | cut -d';'  -f1)"
		myDesc="$(echo ${HelpArray[$i]} | cut -d';'  -f2)"
		printf "     %-20s %-57s\n" $myOpt $myDesc
	done
	IFS=$OIFS;

	echo ""
	echo "Common parameters:"
	echo "  --fromstep X     to restart from step X"
	echo "  --fromscratch    to restart from begining (ignore previous error)"
	echo "  --help           to display this help message"
	echo "  --debug          to enable debug mode"
	
	echo "  --stdout         to force output to stdout (logfile still exist)"
	echo "  --stdoutsummary  to write summary informations to stdout"

	echo "  --status         to display your script status (running or not)"
	echo "  --kill           to kill running script"
    echo "  --lastlog        to display last log file"
	echo "  --liststeps      to list all steps"
	
	exit 0
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
  InternalDebug "IN"
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
    WiteSummaryInfo "Shell is restarting at step $DJSRestartStep"
    WriteSummaryInfo "Logfile is: ${LogFile}"
	Step=$DJSRestartStep
  else
    WriteSummaryInfo "Shell $ShellName is starting"
    WriteSummaryInfo "Logfile is: ${LogFile}"
    Step=0
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
  InternalDebug "OUT"
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
  InternalDebug "IN ($1)"
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
  InternalDebug "OUT ($Step)"  
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
  InternalDebug "IN"
  echo
  echo
  WriteSeparator
  printf "# End of %-45s %-21s #\n" $ShellName "`TimeBanner`"
  DJSEndTime=`date +%s`
  InternalDebug "Computing Execution Time ($DJSEndTime - $DJSStartTime)"
  DjeExecTime=`expr $DJSEndTime - $DJSStartTime|cat`
  printf "# Execution time: %-58s #\n" "$DjeExecTime second(s)"
  WriteSeparator
  echo
  DJSEndOfSteps=1
  InternalDebug "DJSEndOfSteps=$DJSEndOfSteps"
  exec 1>&6 6>&-      # Restaure stdout and close File Descriptor #6.
  WriteSummaryInfo "Shell $ShellName is SUCCESS."
  WriteSummaryInfo "Execution time: $DjeExecTime seconds."
  InternalDebug "OUT"
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
  InternalDebug "IN"
  InternalDebug "ReturnCode=$ReturnCode DJSEndOfSteps=$DJSEndOfSteps"
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
    printf "# Execution time: %-58s #\n" "`expr $DJSEndTime - $DJSStartTime|cat` second(s)."
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
  InternalDebug "OUT"
}


### Parsing configuration file to get config values ###
DJSScriptPath=`dirname $0`
if test -f "$DJSScriptPath/djeshellsteps.cfg"
then
	InternalDebug "Reading Config file $DJSScriptPath/djeshellsteps.cfg"
	ReadConfigFile "$DJSScriptPath/djeshellsteps.cfg" > /dev/null
elif test -f "$DJSScriptPath/../cfg/djeshellsteps.cfg"
then
	InternalDebug "Reading Config file $DJSScriptPath/../cfg/djeshellsteps.cfg"
	ReadConfigFile "$DJSScriptPath/../cfg/djeshellsteps.cfg" > /dev/null
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
	  ### Debug Mode ###
       --internaldebug) 
	     DJSDebugMode=1
             DJSInternalDebug=1
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
	### Get script status ###
	 --status)
		shift
		DJSDisplayStatus
		;;
	### Show script steps ###
	 --liststeps)
		shift
		DJShowSteps
		;;
	### Show help ###
     --help)
       shift
       ShowHelp
       ;;	   
    esac
done

#############################################################################
#                              End of script                                #
#############################################################################

