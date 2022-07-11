#!/usr/bin/env bash
# Made by mH (https://github.com/matthmr)

#*****************************************************
# change anything that is followed by "#change this" #
#*****************************************************

# td: a framework for working with the linux tmpfs

if [[ -z "$TMP" ]]
then
	TMP=/tmp # change this
fi

TMP_ROOT=/tmp # change this
LOCKFILE=$TMP_ROOT/td.lock # change this
DIFF=/bin/diff # change this

VERSION="v0.4.1"

### BEGIN ABOUT ###
function about {
		printf "\nMade by mH (https://github.com/matthmr)
	td\t\t\t => A framework for tmpfs usage\n
Usage:\ttd sync [file] -a [name] => Instantiates a file to the tmpfs
\ttd wrap [CMD]    @[name] => Wraps an instance with a command
\ttd diff @[name]\t\t => Diffs against an instance
\ttd new  @[name]\t\t => Diffs against the original file
\ttd rm   @[name]\t\t => Removes an instance from the tmpfs
\ttd rs   @[name]\t\t => Restores an instance from the tmpfs
\ttd up   @[name]\t\t => Updates an instance to the tmpfs
\ttd or   @[name]\t\t => Ovewrites an instance from the tmpfs

\ttd kill\t\t\t => Kills all instances
\ttd ls\t\t\t => Lists all instances

Info:\ttd status\t\t => Displays whether there is a lockfile
	td [--help/-h]\t\t => Displays this message and exits
	td [--version/-v]\t => Displays the version and exits

Note:\tNot scriptsd compliant yet, default tmpfs is $TMP
\n"
}
### END ABOUT ###

case $1 in
	'--help'|'-h')
		about
		exit 0;;

	'--version'|'-v')
		printf "td $VERSION\n"
		exit 0;;
esac

### BEGIN UTILITIES ###
function usage {
	printf "[ !! ] Bad usage. See td --help\n"
	exit 1
}

function ensure-lock {
	if [ ! -f $LOCKFILE ]; then
		touch $LOCKFILE
	fi
}

function check-lockfile {
	if [ ! -f $LOCKFILE ]; then
		printf "[ !! ] No lockfile found. Did you run 'td sync'?\n"
		exit 1
	fi
}

function prevent-under {
	if [[ $2 -lt  $1 ]]; then
		usage
		exit 1
	fi
}

function prevent-over {
	if [[ $2 -gt  $1 ]]; then
		usage
		exit 1
	fi
}

function resolute {
	ENTRY=$1
	ENTRYBASE=$(echo $ENTRY | cut -f 1 -d '/')

	if [[ "$ENTRY" == "$ENTRYBASE" ]]; then
		FROM=$(grep -w "$ENTRY\$" $LOCKFILE | awk '{print $1}')
	else
		FROM=$(grep -w "$ENTRYBASE\$" $LOCKFILE | awk '{print $1}')
		COMPLEMENT=$(echo $ENTRY | sed "s/$ENTRYBASE//g")
	fi

	if [[ -z "$FROM" ]]; then
		if [[ "$ENTRY" == "$ENTRYBASE" ]]; then
			printf "[ !! ] No origin file for '$ENTRY'\n" >&2
			exit 1
		else
			printf "[ !! ] No origin file for '$ENTRYBASE'\n" >&2
			exit 1
		fi

	else
		echo $FROM$COMPLEMENT
	fi
}

function lock {

	case $1 in

		'add') # [origfile] [entry]

			ensure-lock

			ORIGFILE=$2
			ENTRY=$3
			ENTRYBASE=$(echo $ENTRY | cut -f 1 -d '/')

			EXISTING=$(awk '{print $2}' $LOCKFILE | grep "$ENTRYBASE")
			EXISTINGBASE=$(grep "$ENTRYBASE" $LOCKFILE | awk '{print $1}')

			if [[ -n "$EXISTING" ]]; then
				if [[ ! "$ORIGFILE" =~ "$EXISTINGBASE" ]]; then
					printf "[ !! ] '$ENTRY' already exists with a different origin file\n"
					exit 1
				else
					printf "[ ** ] Updating existing '$ENTRY'\n"
					return
				fi
			fi

			echo "$ORIGFILE $ENTRY" >> $LOCKFILE;;

		'rm') # [entry]
			ENTRY=$2
			ENTRYBASE=$(echo $ENTRY | cut -f 1 -d '/')

			if [[ "$ENTRY" == "$ENTRYBASE" ]]; then

				LINE=$(cat $LOCKFILE | awk '{print $2}' | grep -nw "$ENTRY\$" | cut -f1 -d:)

				if [[ -z $LINE ]]; then
					printf "[ !! ] No instance '$ENTRY' found in '$TMP'\n"
					exit 1

				else
					sed -i "$LINE"d $LOCKFILE
				fi
			else
				local file=$(cat $LOCKFILE | awk '{print $2}' | grep -nw "$ENTRYBASE\$" | cut -f1 -d:)

				[[ -z "$file" ]] &&
					printf "[ !! ] No sub-instance '$ENTRY' found in '$ENTRYBASE'\n"

			fi;;

		'del') # []
			[ ! -f $LOCKFILE ] && {
				echo [ !! ] No lockfile found
				exit 1
			}

			while read line; do
				ENTRIES="$ENTRIES $(echo $line | awk '{print $2}')"
			done < $LOCKFILE

			pushd $TMP &>/dev/null

			rm -vrf $ENTRIES  2>/dev/null
			rm -vf  $LOCKFILE;;

	esac
}
### END UTILITIES ###

[[ $# = 0 ]] && usage && exit 1

### BEGIN FUNCTIONALITY ###
# td sync [path] -a [name]
function sync {

	prevent-over  5 $#

	case $# in
		'3'|'2')

			[[ $# == 2 ]] && {
				FILE=$PWD
				FLAG=$1
				VALUE=$2
			} || {
				FILE=$1
				FLAG=$2
				VALUE=$3
			}

			if [[ ${VALUE::1} == '@' ]]; then
				printf "[ !! ] Wrong format. See td --help\n"
				exit 1
			fi

			if [[ $FLAG == '-a' ]]; then
				ORIGFILE=$(readlink --canonicalize $FILE 2>/dev/null)
				ENTRY="@$VALUE"

			elif [[ $VALUE == '-a' ]]; then
				ORIGFILE="$(readlink --canonicalize $FILE 2>/dev/null)/$FLAG"
				ENTRY="@$(basename $PWD)/$FLAG"

			else
				usage
				exit 1
			fi;;

		'1'|'0')
			[[ $# == 1 ]] && FILE=$1 || FILE=$PWD

			ORIGFILE=$(readlink --canonicalize "$FILE" 2>/dev/null)
			ENTRY="@$(basename $ORIGFILE)";;

		*)
			usage
			exit 1;;
	esac

	lock add $ORIGFILE $ENTRY

	cp -Truv --preserve=all $ORIGFILE $TMP/$ENTRY && {
		echo [ OK ] Instantiated \'$ORIGFILE\' in \'$TMP\' as \'$ENTRY\' ||
		echo [ !! ] Couldn\'t instantiate \'$ORIGFILE\'
	}
}

# td { rm [@name], rs [@name] }
function overwrite { # { remove [@name], restore [@name] }

	prevent-over  2 $#
	prevent-under 1 $#

	check-lockfile

	ENTRY=$2

	[[ -z $ENTRY ]] &&
		ENTRY=@$(basename $PWD)

	[[ ${ENTRY::1} != '@' ]] &&
		ENTRY=@$(basename $PWD)/$ENTRY

	if [[ $1 == 'remove' ]]; then
		rm -vrf $TMP/$ENTRY
		if [[ $? = 0 ]]; then
			echo [ OK ] Removed \'$ENTRY\' from \'$TMP\'
		else
			echo [ !! ] Couldn\'t remove \'$ENTRY\'
			exit 1
		fi
		lock rm $ENTRY

	elif [[ $1 == 'restore' ]]; then
		cp -Trufv --preserve=all $TMP/$ENTRY $(resolute $ENTRY)
		if [[ $? = 0 ]]; then
			echo [ OK ] Restored \'$ENTRY\' from \'$TMP\'
		else
			echo [ !! ] Couldn\'t restore \'$ENTRY\'
			exit 1
		fi

		lock rm $ENTRY
		rm -rvf $TMP/$ENTRY

	elif [[ $1 == 'overwrite' ]]; then
		cp -Trufv --preserve=all $TMP/$ENTRY $(resolute $ENTRY)
		if [[ $? = 0 ]]; then
			echo [ OK ] Overwrite \'$ENTRY\' from \'$TMP\'
		else
			echo [ !! ] Couldn\'t overwrite \'$ENTRY\'
			exit 1
		fi

	elif [[ $1 == 'update' ]]; then
		cp -Trufv --preserve=all $(resolute $ENTRY) $TMP/$ENTRY
		if [[ $? = 0 ]]; then
			echo [ OK ] Update \'$TMP\' from \'$ENTRY\'
		else
			echo [ !! ] Couldn\'t update \'$TMP\'s
			exit 1
		fi
	fi

}

# td ls
function list {

	prevent-over 0 $#

	check-lockfile
	cat $LOCKFILE | sed 's/ / -> /g' | sed "s/\-> $/\-> ${TMP//\//\\/}/g"
}

# td wrap [CMD] [@name]
function wrap {
	check-lockfile

	ENTRY=${@:(-1)}
	COMMAND=${@//$ENTRY/}

	if [[ ${ENTRY::1} != '@' ]]; then
		printf "[ !! ] Wrong format. See td --help\n"
		exit 1
	fi

	if [[ -z $ENTRY || -z $COMMAND ]]; then
		usage
		exit 1
	fi

	$COMMAND $TMP/$ENTRY
}

# td diff [@name]
function diff {

	prevent-over 2 $#

	check-lockfile
	
	ENTRY=$2

	[[ -z $ENTRY ]] &&
		ENTRY=@$(basename $PWD)

	[[ ${ENTRY::1} != '@' ]] &&
		ENTRY=@$(basename $PWD)/$ENTRY

	if [[ -z $ENTRY ]]; then
		usage
		exit 1
	fi

	ORIGFILE=$(resolute $ENTRY)

	[[ -z $ORIGFILE ]] && exit 1

	if [[ $1 = 'orig' ]]; then
		$DIFF --color -u $TMP/$ENTRY $ORIGFILE && echo [ !! ] Files are the same
	else
		$DIFF --color -u $ORIGFILE $TMP/$ENTRY && echo [ !! ] Files are the same
	fi
}
### END FUNCTIONALITY ###

case $1 in

	'status')
		[ -f $LOCKFILE ] &&
		echo [ OK ] lockfile found || {
			echo [ !! ] No lockfile found
			exit 1
		};;

	'kill')
		lock del && echo [ OK ] Cleaned \'$TMP\', removed lockfile
		popd &>/dev/null
		exit 0;;

	'sync')
		sync ${@:2};;

	'diff')
		diff orig ${@:2};;

	'new')
		diff new ${@:2};;

	'wrap')
		wrap ${@:2};;

	'ls')
		list ${@:2};;

	'rm')
		overwrite remove ${@:2};;

	'rs')
		overwrite restore ${@:2};;

	'up')
		overwrite update ${@:2};;

	'or')
		overwrite overwrite ${@:2};;

	*)
		usage
		exit 1;;

esac

[[ -z "$(cat $LOCKFILE)" ]] && rm -rvf $LOCKFILE
