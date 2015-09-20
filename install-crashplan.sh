#!/bin/bash

#############################################################
# Linux Client Installer Script
#############################################################

# variables defined in install.defaults
# APP_BASENAME = human-readable application name
# DIR_BASENAME = dir name
# JRE_X64_DOWNLOAD_URL = url to the 64-bit jre
# JRE_I586_DOWNLOAD_URL = url to the 32-bit jre

SCRIPT_DIR=`dirname ${0}`
if [ ! -f "${SCRIPT_DIR}/install.defaults" ] ; then
	echo "${SCRIPT_DIR}/install.defaults MISSING!"
	exit 1
fi

. ${SCRIPT_DIR}/install.defaults

REQDBINS="grep sed cpio gzip cut head tail who"
OKJAVA="1.5 1.6 1.7"

# ===============================================================================
# Continue validation by verifying the existence of a supported Java VM
# ===============================================================================
JAVACOMMON="DOWNLOAD"

# Setup ARCHIVE var to point to the cpio archive.  This will be used here to extract what we need
# to execute the Java comparison below and will be used later by the script to 
# actually extract everything.
ARCHIVE=`ls ./*_*.cpi`

TARGETDIR=/crashplan
BINSDIR=/usr/local/bin
MANIFESTDIR=/crashplan/archives

# INSTALL TIME ===============================================

mkdir -p $TARGETDIR

# is crashplan already there?
if [ -f ${TARGETDIR}/install.vars ]; then
	echo "CrashPlan appears to already be installed in the specified location:"
	echo "  ${TARGETDIR}"
	echo "Please uninstall and then try this install again."
	exit 1
fi

# create a file that has our install vars so we can later uninstall
NOW=`date +%Y%m%d`
echo "" > ${TARGETDIR}/install.vars
echo "TARGETDIR=${TARGETDIR}" >> ${TARGETDIR}/install.vars
echo "MANIFESTDIR=${MANIFESTDIR}" >> ${TARGETDIR}/install.vars
echo "INSTALLDATE=$NOW" >> ${TARGETDIR}/install.vars
cat ${SCRIPT_DIR}/install.defaults >> ${TARGETDIR}/install.vars

# keep track of the processor architecture
PARCH=`uname -m`
	
#download java
if [[ $JAVACOMMON == "DOWNLOAD" ]]; then
	if [[ $PARCH == "x86_64" ]]; then
		JVMURL="${JRE_X64_DOWNLOAD_URL}"
	else
		JVMURL="${JRE_I586_DOWNLOAD_URL}"
	fi
	JVMFILE=`basename ${JVMURL}`
	if [[ -f ${JVMFILE} ]]; then
		echo ""
		echo "Download of the JVM found. We'll try to use it, but if it's only a partial"
		echo "copy of the file then this will fail. If that happens please remove the file"
		echo "and try again."
		echo "JRE Archive: ${JVMFILE}"
		echo ""
	else
	
	    # Start by looking for wget
	    WGET_PATH=`which wget 2> /dev/null`
	    if [[ $? == 0 ]]; then
			echo "    downloading the JRE using wget"
			$WGET_PATH --quiet $JVMURL
			if [[ $? != 0 ]]; then
				echo "Unable to download JRE; please check network connection"
				exit 1
			fi
	    else

			CURL_PATH=`which curl 2> /dev/null`
			if [[ $? == 0 ]]; then
		    	echo "    downloading the JRE using curl"
		    	$CURL_PATH -L $JVMURL -o `basename $JVMURL`
				if [[ $? != 0 ]]; then
					echo "Unable to download JRE; please check network connection"
					exit 1
				fi
			else
		    	echo "Could not find wget or curl.  You must install one of these utilities"
		    	echo "in order to download a JVM"
		    	exit 1
			fi
	    fi
	fi

	HERE=`pwd`
	cd ${TARGETDIR}
	# Extract into ./jre
	tar -xzf "${HERE}/${JVMFILE}"
	cd "${HERE}"
	JAVACOMMON="${TARGETDIR}/jre/bin/java"
	echo "Java Installed."
fi
echo "" >> ${TARGETDIR}/install.vars
echo "JAVACOMMON=${JAVACOMMON}" >> ${TARGETDIR}/install.vars

# Definition of ARCHIVE occurred above when we extracted the JAR we need to evaluate Java environment
echo Unpacking ${HERE}/${ARCHIVE} ... 
HERE=`pwd`
cd ${TARGETDIR}
cat "${HERE}/${ARCHIVE}" | gzip -d -c - | cpio -i --no-preserve-owner
cd "${HERE}"

# custom?
if [ -d .Custom ]; then
  echo Copying .Custom to ${TARGETDIR}
  cp -Rp .Custom "${TARGETDIR}"
fi
if [ -d custom ]; then
  echo Copying custom to ${TARGETDIR}
  cp -Rp custom "${TARGETDIR}"
fi
if [ -d Custom ]; then
  echo Copying custom to ${TARGETDIR}
  cp -Rp custom "${TARGETDIR}"
fi

#update the configs for file storage
if grep "<manifestPath>.*</manifestPath>" ${TARGETDIR}/conf/default.service.xml > /dev/null
	then
		sed -i "s|<manifestPath>.*</manifestPath>|<manifestPath>${MANIFESTDIR}</manifestPath>|g" ${TARGETDIR}/conf/default.service.xml
	else
		sed -i "s|<backupConfig>|<backupConfig>\n\t\t\t<manifestPath>${MANIFESTDIR}</manifestPath>|g" ${TARGETDIR}/conf/default.service.xml
fi

# the log dir
LOGDIR=${TARGETDIR}/log
chmod 777 $LOGDIR

cp scripts/run.conf ${TARGETDIR}/bin

mv ${TARGETDIR}/conf ${TARGETDIR}/conf.orig
mkdir ${TARGETDIR}/conf

echo ""
echo "Installation is complete. Thank you for installing ${APP_BASENAME} for Linux."
echo ""

