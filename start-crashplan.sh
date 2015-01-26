#!/bin/bash

#############################################################
# Init script for CrashPlanEngine
#############################################################

SCRIPT=$(ls -l $0 | awk '{ print $NF }')
SCRIPTDIR=$(dirname $SCRIPT)
TARGETDIR="$SCRIPTDIR/.."

# Remaining Defaults
DESC="CrashPlan Engine"
NAME=CrashPlanEngine
DAEMON=$TARGETDIR/lib/com.backup42.desktop.jar
PIDFILE="$TARGETDIR/${NAME}.pid"

if [[ -f $TARGETDIR/install.vars ]]; then
	. $TARGETDIR/install.vars
else
	echo "Did not find $TARGETDIR/install.vars file."
	exit 1
fi

if [[ ! -f $DAEMON ]]; then
	echo "Could not find JAR file $DAEMON"
	exit 1
fi

if [[ ${LC_ALL} ]]; then
	LOCALE=`sed 's/\..*//g' <<< ${LC_ALL}`
	export LC_ALL="${LOCALE}.UTF-8"
elif [[ ${LC_CTYPE} ]]; then
	LOCALE=`sed 's/\..*//g' <<< ${LC_CTYPE}`
	export LC_CTYPE="${LOCALE}.UTF-8"
elif [[ ${LANG} ]]; then
	LOCALE=`sed 's/\..*//g' <<< ${LANG}`
	export LANG="${LOCALE}.UTF-8"
else
	export LANG="en_US.UTF-8"
fi

if [[ -f $TARGETDIR/bin/run.conf ]]; then
	. $TARGETDIR/bin/run.conf
else
	echo "Did not find $TARGETDIR/bin/run.conf file."
fi

FULL_CP="$TARGETDIR/lib/com.backup42.desktop.jar:$TARGETDIR/lang"

cd $TARGETDIR

exec nice -n 19 $JAVACOMMON $SRV_JAVA_OPTS -classpath $FULL_CP \
	com.backup42.service.CPService "$@"

