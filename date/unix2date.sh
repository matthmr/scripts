#!/usr/bin/bash

DATE=$1

if [[ -z $DATE || $DATE = --help ]]; then
		echo "Usage: unix2date <date>"
		exit 0
fi

date --date=@"$DATE"
