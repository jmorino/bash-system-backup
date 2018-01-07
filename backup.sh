#!/bin/bash

# ##################################################
# My Generic BASH script template
#
version="1.0.0"               # Sets version variable
#
# HISTORY:
#
# * 2017-08-27 - 1.0.0 - First Creation
#
# ##################################################

# Provide a variable with the location of this script.
scriptPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scriptName="backup"
logFile=/dev/stdout
errFile=/dev/stderr
today=$(date +%Y-%m-%d)

ARCHIVED_ROOT_DIR="/"
BACKUP_DIR="/backup"



# Scripting Utilities
# -----------------------------------
# These shared utilities provide many functions which are needed to provide
# the functionality in this boilerplate. This script will fail if they can
# not be found.
# -----------------------------------
function initLogger() {
	local filename="$BACKUP_DIR/backup.$today.log"

	touch $filename 2>/dev/null
	if [ -f $filename ]; then
		logFile=$filename
		errFile=$filename
		log "------------------------------ `date` --------------------------------------"
	else
		die "Unable to create log file $filename"
	fi
}
function log() {
	echo -e "${*}" >> $logFile
}
function err() {
	echo -e "${*}" >> $errFile
}
function die() {
	err "${*}"
	err 'Exiting'
	safeExit
}
function cleanup() {
	# Delete temp files, if any
	if [ -d "${tmpDir}" ]; then
		rm -r "${tmpDir}"
	fi
}
function safeExit() {
	cleanup
	trap - INT TERM EXIT
	exit
}


# trapCleanup Function
# -----------------------------------
# Any actions that should be taken if the script is prematurely
# exited.  Always call this function at the top of your script.
# -----------------------------------
function trapCleanup() {
	err ""
	cleanup
	die "Exit trapped."
}


# Set Flags
# -----------------------------------
# Flags which can be overridden by user input.
# Default values are below
# -----------------------------------
backup=0
backupFull=0
backupIncr=0
restore=0
restorationPoint=0
reset=0
log2file=0
showUsage=0
showVersion=0

quiet=0
verbose=0
force=0
strict=0
debug=0
args=()

# Set Temp Directory
# -----------------------------------
# Create temp directory with three random numbers and the process ID
# in the name.  This directory is removed automatically at exit.
# -----------------------------------
tmpDir="/tmp/${scriptName}.$RANDOM.$RANDOM.$RANDOM.$$"
(umask 077 && mkdir "${tmpDir}") || {
	die "Could not create temporary directory! Exiting."
}


####################################################
############## Begin Script Here ###################
####################################################

function mainScript() {
	if [ $reset != 0 ]; then
		reset
		safeExit
	fi
	if [ $backupFull != 0 ]; then
		backup
		safeExit
	fi
	if [ $backupIncr != 0 ]; then
		backup
		safeExit
	fi
	if [ $restore != 0 ]; then
		restore
		safeExit
	fi
	if [ $showUsage != 0 ]; then
		usage
		safeExit
	fi
	if [ $showVersion != 0 ]; then
		log "$(basename $0) ${version}"
		safeExit
	fi

	die 'Nothing to do.'
}

function reset() {
	local archiveRoot=$BACKUP_DIR
	find $archiveRoot -regex '.*/[0-9].*' -delete >> $logFile 2>> $errFile
	ls -l $archiveRoot >> $logFile 2>> $errFile
}

function restore() {
	local archiveRoot=$BACKUP_DIR
	local target="$restorationPoint.tar.gz"
	local candidates=($(find $archiveRoot -name $target))
	local count=$(echo $candidates | wc -l)


	# Ensure we have at least one candidate for the restoration
	if [ ${#candidates[*]} -eq 0 ]; then
		err ''
		err "No matching restoration point found."
		err "  Candidates are:"
		find $archiveRoot -regex '.*\.tar\.gz' | sort -V >> $errFile
		die
	# Ensure we have only one candidate for the restoration
	elif [ ${#candidates[*]} -ne 1 ]; then
		err ''
		err 'Ambiguous restoration point.'
		err '  Candidates are:'
		printf '%s\n' "${candidates[@]}" >> $errFile
		die 
	fi

	local dir=$(dirname ${candidates[0]})

	# restore all archives from the full backup to the target restoration point
	cd $ARCHIVED_ROOT_DIR
	for f in $(ls $dir | tr ' ' "\n"| grep '.tar.gz'); do
		log "  *** restoring $dir/$f"
		tar -xvpzf "$dir/$f" --numeric-owner >> $logFile 2>> $errFile

		# check if reached the target restoration point
		if [ $f == $target ]; then break; fi
	done

	log 'Done.'
}

function backup() {
	local filename="$today.tar.gz"
	local archiveRoot=$BACKUP_DIR
	local dest

	if [ $backupFull != 0 ]; then
		# full backup: create a new directory
		log 'creating new full backup...'
		dest="$archiveRoot/$today"
		mkdir -p "$dest" >> $logFile 2>> $errFile
	else
		# incremental backup: find the latest directory
		log 'creating new incremental backup...'
		dest=$(ls -d $archiveRoot/*/ | sort -V | tail -n 1)
		log $dest
	fi

	# remove any existing backup of this day to avoid confusion
	find $archiveRoot -name $filename -delete >> $logFile 2>> $errFile

	# get dynamic list of all socket files to exclude from backup
	local excludes=($(find / -type s 2>/dev/null))
	# add all excluded directories/files manually
	excludes+=($archiveRoot)
	excludes+=('/bin')
	excludes+=('/lib/modules')
	excludes+=('/lib64')
	excludes+=('/proc')
	excludes+=('/tmp')
	excludes+=('/mnt')
	excludes+=('/dev')
	excludes+=('/sys')
	excludes+=('/run')
	excludes+=('/media')
	excludes+=('/sbin')
	excludes+=('/usr/src/linux-headers*')
	excludes+=('/var/cache')
	excludes+=('/var/lib')
	excludes+=('/var/log')
	excludes+=('/home/*/.gvfs')
	excludes+=('/home/*/.cache')

	# build exclude options dynamically
	excludeOptions=()
	for x in "${excludes[@]}"; do
		excludeOptions+=(--exclude="$x")
	done

	# create archive
	cd $ARCHIVED_ROOT_DIR
	tar -czvpf $dest/$filename --listed-incremental=$dest/MANIFEST "${excludeOptions[@]}" $ARCHIVED_ROOT_DIR >> $logFile 2>> $errFile

	log 'Done.'
	safeExit

	#tar -czvpf $dest/$filename --listed-incremental=$dest/MANIFEST --exclude=$^excludes $ARCHIVED_ROOT_DIR >> $logFile 2>> $errFile
	tar -czvpf $dest/$filename --listed-incremental=$dest/MANIFEST \
		--exclude=$^excludes \
		--exclude=$archiveRoot \
		--exclude=/bin \
		--exclude=/lib/modules \
		--exclude=/lib64 \
		--exclude=/proc \
		--exclude=/tmp \
		--exclude=/mnt \
		--exclude=/dev \
		--exclude=/sys \
		--exclude=/run \
		--exclude=/media \
		--exclude=/sbin \
		--exclude=/usr/src/linux-headers* \
		--exclude=/var/cache \
		--exclude=/var/lib \
		--exclude=/var/log \
		--exclude=/home/*/.gvfs \
		--exclude=/home/*/.cache $ARCHIVED_ROOT_DIR >> $logFile 2>> $errFile
}

####################################################
############### End Script Here ####################
####################################################



############## Begin Options and Usage ###################


# Print usage
usage() {
	echo -n "
Usage: 
 * backup:  ${scriptName} --full
            ${scriptName} --incr
 * restore: ${scriptName} --restore [DATE]
           

Backup/restoration script.

Options:
      --full        Create a new full backup
      --incr        Create a new incremental backup
      --restore     Restore a backup. Specify date as only parameter or defaults to latest
      --reset       Reset all backup files (DEBUG only)
  -l, --log         Log output to ${logFile}

  -q, --quiet       Quiet (no output)
  -v, --verbose     Output more information. (Items echoed to 'verbose')
  -s, --strict      Exit script with null variables.  i.e 'set -o nounset'
  -d, --debug       Runs script in BASH debug mode (set -x)
  -h, --help        Display this help and exit
      --version     Output version information and exit

" >> $errFile
}

# Iterate over options breaking -ab into -a -b when needed and --foo=bar into
# --foo bar
optstring=h
unset options
while (($#)); do
	case $1 in
		# If option is of type -ab
		-[!-]?*)
			# Loop over each character starting with the second
			for ((i=1; i < ${#1}; i++)); do
				c=${1:i:1}

				# Add current char to options
				options+=("-$c")

				# If option takes a required argument, and it's not the last char make
				# the rest of the string its argument
				if [[ $optstring = *"$c:"* && ${1:i+1} ]]; then
					options+=("${1:i+1}")
					break
				fi
			done
			;;

		# If option is of type --foo=bar
		--?*=*) options+=("${1%%=*}" "${1#*=}") ;;
		# add --endopts for --
		--) options+=(--endopts) ;;
		# Otherwise, nothing special
		*) options+=("$1") ;;
	esac
	shift
done
set -- "${options[@]}"
unset options

# Print help if no arguments were passed.
# Uncomment to force arguments when invoking the script
[[ $# -eq 0 ]] && set -- "--help"

# Read the options and set stuff
while [[ $1 = -?* ]]; do
	case $1 in
		-h|--help) showUsage=1 ;;
		--version) showVersion=1 ;;
		--full) backupFull=1 ;;
		--incr) backupIncr=1 ;;
		--restore) restore=1; shift; restorationPoint=${1:-$today} ;;
		--reset) reset=1 ;;

		-l|--log) log2file=1 ;;
		-v|--verbose) verbose=1 ;;
		-q|--quiet) quiet=1 ;;
		-s|--strict) strict=1;;
		-d|--debug) debug=1;;
		--force) force=1 ;;
		--endopts) shift; break ;;
		#*) die "invalid option: '$1'." ;;
	esac
	shift
done

# Store the remaining part as arguments.
args+=("$@")

############## End Options and Usage ###################




# ############# ############# #############
# ##       TIME TO RUN THE SCRIPT        ##
# ##                                     ##
# ## You shouldn't need to edit anything ##
# ## beneath this line                   ##
# ##                                     ##
# ############# ############# #############

# Trap bad exits with your leanup function
trap trapCleanup EXIT INT TERM

# Exit on error. Append '||true' when you run the script if you expect an error.
set -o errexit

# Run in debug mode, if set
if [ "${debug}" == "1" ]; then
	set -x
fi

# Exit on empty variable
if [ "${strict}" == "1" ]; then
	set -o nounset
fi

# Bash will remember & return the highest exitcode in a chain of pipes.
# This way you can catch the error in case mysqldump fails in `mysqldump |gzip`, for example.
set -o pipefail


# Initialize log file
# if not run via terminal, log everything into a log file
if [ -z $TERM ] || [ $log2file != 0 ]; then
	initLogger
fi


# Run your script
mainScript

# Exit cleanly
safeExit
