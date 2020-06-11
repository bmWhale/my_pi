################################################################################
# 2017 Q2 RayLin @Actions-Micro Co.
#	This script is used to save config in shared memory via am_config.app.
#	It's used to access and modify pjm config file by am_projector.app
#		Only am_projector.app can call this script to modify file in general.
#
#		lock file store in /tmp/
# Usage:
#	1. save config from shared memory to file:
#		a. save config according to whole file. script will query config inst in file, and save corresponding config to file.  
#			argument 1 should be "save"
#			amPjmConfigAccess.sh save <filepath>
#				ex. ./amPjmConfigAccess.sh save /mnt/vram/projector_mgr/pjm_status_system.cfg
#		b. save config according to one config inst in file. sciprt will find specific config inst, then save it to file
#			amPjmConfigAccess.sh save <filepath> <configInst>
#				ex. ./amPjmConfigAccess.sh save /mnt/vram/projector_mgr/pjm_status_picture.cfg PJM_PIC_HUE
#
#	2. load config from file to shared memory:
#		load config file from file system to shared memory for system used. if argument 3 exist, check file with reference file.
#		if any config inst lost, copy from ref file to user file.
#			argument 1 should be "load"
#			amPjmConfigAccess.sh load <filepath> <reffilepath>
#				ex. ./amPjmConfigAccess.sh load /mnt/vram/projector_mgr/pjm_status_picture.cfg /am7x/case/data/projector_mgr/pjm_status_picture.cfg
################################################################################

# global define
def_amConfigSaveSingleCmd="am_config.app"
def_amPjmCfgPrePattern="/tmp/"
def_amPjmCfgPostPattern=".lock"
def_checkTimeSecUS=5000000			# us
def_checkTimeIntervalUS=200000		# us

# global variable
g_amPjmCfgLock=""


# func, check $1 filepath is exist or not, 
#	return 0, file exist
#	return 1, file doesn't exist
func_checkFileExist () 
{
	if ! [ -f $1 ]
	then
		return 1
	fi
	return 0
}

# func, lock corresponding file according to input filepath
#	argument1, lockfile path
#	return 0, lock success
#	return 1, lock failed
func_lockFile()
{
	tmpFileName=$(basename $1)
	#echo -e "tmpFileName=$tmpFileName"
	g_amPjmCfgLock=$def_amPjmCfgPrePattern$tmpFileName$def_amPjmCfgPostPattern
	#echo -e "am_PjmCfgLock=$g_amPjmCfgLock"
	
	# lock filelock
	i=0
	while [ $i -le $def_checkTimeSecUS ]
	do
		func_checkFileExist $g_amPjmCfgLock
		returnValue=$?
		if [ $returnValue -ne 0 ]
		then
			#echo -e "amPjmConfigAccess.sh: saveScript no lockFile, create it!"
			touch $g_amPjmCfgLock
			break
		fi
		
		usleep $def_checkTimeIntervalUS
		i=$(($i + $def_checkTimeIntervalUS))
	done

	if [ $i -gt $def_checkTimeSecUS ]
	then
		echo -e "amPjmConfigAccess.sh: lockFile failed."
		return 1
	fi

	func_checkFileExist $g_amPjmCfgLock
	returnValue=$?
	if [ $returnValue -ne 0 ]
	then
		echo -e "amPjmConfigAccess.sh: create lock File failed."
		return 1
	fi
	
	return 0
}

#-------------------------------------------------------------------------------------------
# functions used in main

# func, load file to shared memory
#	func_saveConfigFile <filepath> [<configInst>]
#	return 0: success
#	return 1: failed
func_saveConfigFile()
{
	# check numbers of input arguments
	funcArgNum=$#
	if [ $funcArgNum -lt 1 ];then
		echo -e "amPjmConfigAccess.sh: save func failed, invalid argument numbers"
		return 1
	fi
	
	filepath=$1
	
	# check file is exist or not
	func_checkFileExist $filepath
	returnValue=$?
	if [ $returnValue -ne 0 ];then
		echo -e "amPjmConfigAccess.sh: save func failed, file is not exist $filepath"
		return 1
	fi
	
	# lock file
	func_lockFile $filepath
	returnValue=$?
	if [ $returnValue -ne 0 ];then
		echo -e "amPjmConfigAccess.sh: save func failed, lock file $g_amPjmCfgLock failed"
		return 1
	fi
	
	# compose am_config -u/-s cmd	
	cmd="$def_amConfigSaveSingleCmd -s $filepath -u "
	
	# if argc is 2, save specific config to file
	if [ $funcArgNum -eq 2 ];then
		lineDelim="\n"
		pattern=$2
		
		grepContent=$(grep $pattern $filepath)
		
		for word in $grepContent
		do
			substring=$(echo "$word"| cut -d '=' -f 1)
			if [ $substring == $pattern ];then
				cmd="$cmd$substring"
				$cmd
				#echo -e "amPjmConfigAccess.sh: remove lockFile $g_amPjmCfgLock"
				rm $g_amPjmCfgLock
				return 0
			fi
		done

		echo -e "pjm save config script failed : can't find $pattern in file[$filepath]"

	# if argc == 1, check file and save with file
	elif [ $# -eq 1 ];then
		# get line string from config file
		i=0

		while read line
		do
			lineContent="$line"
			if ! [[ ${lineContent:0:1} == "#" ]];then
				substring=$(echo "$lineContent"|cut -d '=' -f 1)
				if [ i == 0 ];then
						cmd="$cmd$substring"
						i=i+1
				else
						cmd="$cmd,$substring"

				fi
			fi
		done < "$filepath"
		
		$cmd

	else
		echo "amPjmConfigAccess.sh: save func failed, wrong usage should input 1 or 2 arguments"
	fi

	#echo -e "amPjmConfigAccess.sh: remove lockFile $g_amPjmCfgLock"
	rm $g_amPjmCfgLock
	
	return 0
}

# func, load file to shared memory
#	func_loadConfigFile <filepath> [<refFilepath>]
#	return 0: success
#	return 1: failed
func_loadConfigFile()
{
	# check numbers of input arguments
	funcArgNum=$#
	if [ $funcArgNum -lt 1 ];then
		echo -e "amPjmConfigAccess.sh: load func failed, invalid argument numbers"
		return 1
	fi

	filepath=$1
	
	# lock file
	func_lockFile $filepath
	returnValue=$?
	if [ $returnValue -ne 0 ];then
		echo -e "amPjmConfigAccess.sh: load func failed, lock file $g_amPjmCfgLock failed"
		return 1
	fi
	
	if [ $funcArgNum -eq 1 ];then
		func_checkFileExist $filepath
		funcRet=$?
		if [ $funcRet -ne 0 ];then
			echo -e "amPjmConfigAccess.sh: load func failed, $filepath not exist"
			rm $g_amPjmCfgLock
			return 1
		fi
		
		cmd="$def_amConfigSaveSingleCmd -l $filepath"
		$cmd
		
	elif [ $funcArgNum -eq 2 ];then
		refFilepath=$2
		
		# check reference file exist or not
		func_checkFileExist $refFilepath
		funcRet=$?
		if [ $funcRet -ne 0 ];then
			echo -e "amPjmConfigAccess.sh: load func failed, $refFilepath not exist"
			rm $g_amPjmCfgLock
			return 1
		fi
		
		func_checkFileExist $filepath
		funcRet=$?
		# if filepath not exist, should copy from reference file
		if [ $funcRet -ne 0 ];then
			cmd="cp $refFilepath $filepath"
			echo -e "amPjmConfigAccess.sh: can't find $filepath, copy from $refFilepath"
			$cmd
		else
			# if filepath exist, check line with reference file
			while read line
			do
				refLineContent=$line
				# if first char is not #
				if ! [[ ${refLineContent:0:1} == "#" ]];then
					substring=$(echo "$refLineContent" | cut -d '=' -f 1)
					grep -q $substring $filepath
					if [[ $? -ne 0 ]];then
						echo -e "amPjmConfigAccess.sh: $filepath lose config inst $substring, copy it"
						copyLine=$(grep $substring $refFilepath)
						echo "$copyLine" >> $filepath
					fi
				fi
			done < "$refFilepath"
		fi
		
		cmd="$def_amConfigSaveSingleCmd -l $filepath"
		$cmd
		
	else
		echo "amPjmConfigAccess.sh: load func failed, wrong usage should input 1 or 2 arguments"
	fi
	
	rm $g_amPjmCfgLock
	return 0
}

# /functions used in main
#-------------------------------------------------------------------------------------------

######## main ########
funcRet=0

case $1 in
	"save")
		filepath=$2
		scriptArgNum=$#
		
		# if number of argument = 2
		if [ $scriptArgNum -eq 2 ];then
			func_saveConfigFile $filepath
			funcRet=$?
			
		# if number of argument = 3
		elif [ $scriptArgNum -eq 3 ];then
			configInst=$3
			func_saveConfigFile $filepath $configInst
			funcRet=$?
		
		else
			echo -e "amPjmConfigAccess.sh: main failed, invalid input save function should input 2~3 arugments."
			exit 1
		fi

		# judge function's return
		if [ $funcRet -ne 0 ]
		then
			echo -e "amPjmConfigAccess.sh: main failed, save file $filepath failed"
		fi
	;;
	
	"load")
		filepath=$2
		scriptArgNum=$#
		
		# if number of argument = 2
		if [ $scriptArgNum -eq 2 ];then
			func_loadConfigFile $filepath
			funcRet=$?
			
		# if number of argument = 3
		elif [ $scriptArgNum -eq 3 ];then
			refFilepath=$3
			func_loadConfigFile $filepath $refFilepath
			funcRet=$?
			
		else
			echo -e "amPjmConfigAccess.sh: main failed, invalid input, load function should input 2~3 arugments."
			exit 1
		fi
		
		# judge function's return
		if [ $funcRet -ne 0 ];then
			echo -e "amPjmConfigAccess.sh: main failed, load file $filepath failed"
		fi
	;;
	
	*)
		echo -e "amPjmConfigAccess.sh: main failed, invalid input [$1]."
	;;
	
esac








