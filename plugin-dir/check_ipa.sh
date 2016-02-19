#!/bin/bash

#######################################################
#                                                     #
#  Name:    check_ipa                                 #
#                                                     #
#  Version: 1.0                                       #
#  Created: 2016-02-18                                #
#  License: GPLv3 - http://www.gnu.org/licenses       #
#  Copyright: (c)2016 René Koch                       #
#  Author:  René Koch <rkoch@rk-it.at>                #
#  URL: https://github.com/scrat14/check_ipa          #
#                                                     #
#######################################################

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Changelog:
# * 1.0.0 - Thu Feb 18 2016 - René Koch <rkoch@rk-it.at>
# - This is the first release of new plugin check_ipa

# Configuration
IPA_CTL="/sbin/ipactl"
SUDO="/usr/bin/sudo"

# Variables
PROG="check_ipa"
VERSION="1.0.0"
VERBOSE=0
STATUS=3

# Icinga/Nagios status codes
STATUS_WARNING=1
STATUS_CRITICAL=2
STATUS_UNKNOWN=3


# function print_usage()
print_usage(){
  echo "Usage: ${0} [-v] [-V]"
}


# function print_help()
print_help(){
  echo ""
  echo "IPA plugin for Icinga/Nagios version ${VERSION}"
  echo "(c)2016 - Rene Koch <rkoch@rk-it.at>"
  echo ""
  echo ""
  print_usage
  cat <<EOT
Options:
 -h, --help
    Print detailed help screen
 -V, --version
    Print version information
 -v, --verbose
    Show details for command-line debugging (Nagios may truncate output)
Send email to rkoch@rk-it.at if you have questions regarding use
of this software. To sumbit patches of suggest improvements, send
email to rkoch@rk-it.at
EOT

exit ${STATUS_UNKNOWN}

}


# function print_version()
print_version(){
  echo "${PROG} ${VERSION}"
  exit ${STATUS_UNKNOWN}
}


# The main function starts here

# Parse command line options
while test -n "$1"; do
  
  case "$1" in
    -h | --help)
      print_help
      ;;
    -V | --version)
      print_version
      ;;
    -v | --verbose)
      VERBOSE=1
      shift
      ;;
    *)
      echo "Unknown argument: ${1}"
      print_usage
      exit ${STATUS_UNKNOWN}
      ;;
  esac
  shift
      
done


# Get status of IPA services
if [ ${VERBOSE} -eq 1 ]; then
  echo "[V]: Output of ipactl status:"
  echo "`${SUDO} ${IPA_CTL} status`"
fi

IPA=(`${SUDO} ${IPA_CTL} status 2>/dev/null | grep -v 'must be running' | awk '{ print $1,$3 }'`)
if [ $? -ne 0 ]; then
	echo "IPA UNKNOWN: ${IPA[*]}"
	exit ${STATUS_UNKNOWN}
else
  # loop through array
  for INDEX in ${!IPA[*]}; do
    # odd number in array is status of service
    # even number is service itself
    if [ $(( ${INDEX}%2 )) -eq 0 ]; then
      # status needs to be "RUNNING", otherwise the service isn't running
      if [ ${IPA[$((INDEX+1))]} != "RUNNING" ]; then
        STATUSTEXT="${STATUSTEXT} ${IPA[${INDEX}]} is ${IPA[$((INDEX+1))]},"
        STATUS=${STATUS_CRITICAL}
      fi
   fi
  done
fi

if [ -n "${STATUSTEXT}" ]; then
  # chop last ","
  STATUSTEXT="`echo ${STATUSTEXT} | awk '{print substr($0,1,length($0)-1)}'`" 
fi

if [ ${STATUS} -ne ${STATUS_CRITICAL} ]; then
  # IPA is OK
  echo "IPA OK: All services are running!"
  STATUS=${STATUS_OK}
else
  echo "IPA CRITICAL: ${STATUSTEXT}"
fi

exit ${STATUS}
