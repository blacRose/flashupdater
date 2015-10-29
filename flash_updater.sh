#!/bin/bash
# Script to download and install Flash Player.
# Only works on Intel systems.

# Set these to your Apple file share
cacheserver=""
cacheshare=""
cacheuser=""
cachepass=""


tmpath="/tmp/flashplayer"
dmgfile="flash.dmg"
volname="Flash"
logfile="/Library/Logs/FlashUpdateScript.log"

# Are we running on Intel?
if [ '`/usr/bin/uname -p`'="i386" -o '`/usr/bin/uname -p`'="x86_64" ]; then
	echo "`date`: Checking versions."
	# Get the latest version of Flash Player available from Adobe's About Flash page.
	latestver=`/usr/bin/curl -s http://www.adobe.com/software/flash/about/ | /usr/bin/grep -A2 'Macintosh<br />OS X' | /usr/bin/grep -A1 'Safari' | /usr/bin/sed -e 's/<[^>][^>]*>//g' -e '/^ *$/d' | /usr/bin/tail -n 1 | /usr/bin/grep -e "[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*" -o`
	# Get the version number of the currently-installed Flash Player, if any.
	if [ -e "/Library/Internet Plug-Ins/Flash Player.plugin" ]; then
		currentinstalledver=`/usr/bin/defaults read /Library/Internet\ Plug-Ins/Flash\ Player.plugin/Contents/version CFBundleShortVersionString`
	else
		currentinstalledver="none"
	fi
	# Compare the two versions, if they are different of Flash is not present then download and install the new version.
	if [ "${currentinstalledver}" != "${latestver}" ]; then
		/bin/echo "`date`: Current Flash version: ${currentinstalledver}" >> ${logfile}
		/bin/echo "`date`: Available Flash version: ${latestver}" >> ${logfile}
		/bin/echo "`date`: Downloading newer version." >> ${logfile}
		mkdir -p "${tmpath}"
		mount_afp "afp://${cacheuser}:${cachepass}@${cacheserver}/${cacheshare}" ${tmpath}
		/bin/echo "`date`: Share mounted." >> $logfile
		if [ ! -e "${tmpath}/cachever.txt" ]; then
			/bin/echo -n "0" > ${tmpath}/cachever.txt
			cachever="none"
			/bin/echo "`date`: Cache error! Rebuilt cachever file." >> ${logfile}
		else
			# sleep a random amount of time (0-3s). this prevents everyone locking it at the same time.
			sleep $[ ( $RANDOM % 3 ) ]s
			while [ -f ${tmpath}/.cachelock ]
			do
			  sleep 10
			  echo "`date`: Idling." >> $logfile
			done
			cachever=`cat ${tmpath}/cachever.txt`
			if [ "${cachever}" != "${latestver}" ]; then
					# lock directory
					/usr/bin/touch ${tmpath}/.cachelock
					# download latest version
					/bin/echo "`date`: Caching latest version."
					/usr/bin/curl -o ${tmpath}/flash.dmg http://download.macromedia.com/get/flashplayer/pdc/${latestver}/install_flash_player_osx.dmg >> ${logfile}
					echo "`date`: Cached latest version."
					/bin/echo "$latestver" > ${tmpath}/cachever.txt
					/bin/rm ${tmpath}/.cachelock
			fi
		fi
		if [ ${cachever} == "none" ]; then
			# 
			# Try the old way
			# 
			/bin/echo "`date`: Current Flash version: ${currentinstalledver}" >> ${logfile}
			/bin/echo "`date`: Available Flash version: ${latestver}" >> ${logfile}
			/bin/echo "`date`: Downloading newer version." >> ${logfile}
			/usr/bin/curl -o /tmp/flash.dmg http://download.macromedia.com/get/flashplayer/pdc/${latesterver}/install_flash_player_osx.dmg >> ${logfile}
			/bin/echo "`date`: Mounting installer disk image." >> ${logfile}
			/usr/bin/hdiutil attach /tmp/flash.dmg -nobrowse -quiet
			/bin/echo "`date`: Installing..." >> ${logfile}
			/usr/sbin/installer -pkg /Volumes/Flash\ Player/Install\ Adobe\ Flash\ Player.app/Contents/Resources/Adobe\ Flash\ Player.pkg -target / >> ${logfile}
			/bin/sleep 10
			/bin/echo "`date`: Unmounting installer disk image." >> ${logfile}
			/usr/bin/hdiutil detach $(/bin/df | /usr/bin/grep ${volname} | awk '{print $1}') -quiet
			/bin/sleep 2
			/bin/echo "`date`: Deleting disk image." >> ${logfile}
			/bin/rm /tmp/${dmgfile}
			newlyinstalledver=`/usr/bin/defaults read /Library/Internet\ Plug-Ins/Flash\ Player.plugin/Contents/version CFBundleShortVersionString`
		else
			# 
			# The shiny new way, using a proper cache
			# 
			echo 
			/bin/echo "`date`: Mounting installer disk image."
			/usr/bin/hdiutil attach ${tmpath}/flash.dmg -nobrowse -quiet
			/bin/echo "`date`: Installing..."
			/usr/sbin/installer -pkg /Volumes/Flash\ Player/Install\ Adobe\ Flash\ Player.app/Contents/Resources/Adobe\ Flash\ Player.pkg -target / >> $logfile
			/bin/sleep 10
			/bin/echo "`date`: Unmounting installer disk image."
			/usr/bin/hdiutil detach $(/bin/df | /usr/bin/grep ${volname} | awk '{print $1}') -quiet
			/bin/sleep 10
			/bin/echo "`date`: Unmounting share." >> ${logfile}
			/sbin/umount ${tmpath}
			/bin/echo "`date`: Deleting temp folder." >> ${logfile}
			/bin/rm -r ${tmpath}
			newlyinstalledver=`/usr/bin/defaults read /Library/Internet\ Plug-Ins/Flash\ Player.plugin/Contents/version CFBundleShortVersionString`
		fi
        if [ "${latestver}" = "${newlyinstalledver}" ]; then
            /bin/echo "`date`: SUCCESS: Flash has been updated to version ${newlyinstalledver}" >> ${logfile}
	   		/bin/echo "--" >> ${logfile}
        else
            /bin/echo "`date`: ERROR: Flash update unsuccessful, version remains at ${currentinstalledver}." >> ${logfile}
            /bin/echo "--" >> ${logfile}
		fi
    # If Flash is up to date already, just log it and exit.       
	else
		/bin/echo "`date`: Flash is already up to date, running ${currentinstalledver}." >> ${logfile}
        	/bin/echo "--" >> ${logfile}
	fi	
else
	/bin/echo "`date`: ERROR: This script is for Intel Macs only." >> ${logfile}
fi
tail -n 3 ${logfile}