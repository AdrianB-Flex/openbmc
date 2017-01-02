#!/bin/sh
#
# Copyright 2014-present Facebook. All Rights Reserved.
#
# This program file is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#

### BEGIN INIT INFO
# Provides:          power-on
# Required-Start:
# Required-Stop:
# Default-Start:     S
# Default-Stop:
# Short-Description: Power on micro-server
### END INIT INFO
. /usr/local/bin/openbmc-utils.sh

PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/bin

devmem_clear_bit 0x1e6e2080 20
devmem_clear_bit 0x1e6e208c 14

i2cset -f -y 12 0x31 0x06 0x4 2>/dev/null #sysled light blue

val=$(i2cget -f -y 12 0x31 0x22 2> /dev/null)
if [ "$val" = "0x11" ] ; then
	i2cset -f -y 12 0x31 0x22 0x0
	soft_reboot=0
else
	soft_reboot=1
	echo "System boot by software reboot"
fi

if galaxy100_scm_is_present && [ $soft_reboot -eq 0 ] ; then
	# First power on TH, and if Panther+ is used,
	# provide standby power to Panther+.
	repeater_config
	KR10G_repeater_config
	wedge_power_on_board

	echo -n "Checking microserver present status ... "
	if wedge_is_us_on 10 "."; then
		echo "on"
	    on=1
	    # microsever reset
	    wedge_power.sh reset
	else
	    echo "off"
		on=0
	fi

	if [ $on -eq 0 ]; then
	    # Power on now
	    wedge_power.sh on -f
	fi
elif ! galaxy100_scm_is_present ; then
	echo "SCM isn't present..."
fi