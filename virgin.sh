#!/bin/ash

# Refer to https://my.virginmedia.com/traffic-management/traffic-management-policy-thresholds.html
# to find the limits that apply to you

tc0=12000           #kbps
tc1=6100            #kbps
tc2=4300            #kbps

#It's usually not necessary to change these parameters
week_tc_start=16    #h
weel_tc_end=23      #h
weekend_tc_start=11 #h
weelend_tc_end=23   #h
ping_limit=50000    #ns

get_current_tc() {
	uci get qos.wan.upload
}

set_tc() {
	uci set qos.wan.upload=$1
	uci commit qos
	/etc/init.d/qos reload
}

get_ping() {
	gateway=$(ip route 2>/dev/null | grep default | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | head -n 1)
	if [ "$gateway" == "" ]; then
		#Fallback on the route command
		gateway=$(route -n | grep -E '^0\.0\.0\.0' | cut  -f 10 -d ' ')
	fi
	ping -c4 -W1 -w10 $gateway | tail -1 | awk -F '/' '{print $4}' | sed 's/\.//'
}

is_ts_on() {
	if [ $(date +%u) -lt 6 ]; then
		if [ $(date +%H) -ge $week_tc_start ] && [ $(date +%H) -lt $weel_tc_end ]; then
			echo 1
			return
		fi
	else
		if [ $(date +%H) -ge $weekend_tc_start ] && [ $(date +%H) -lt $weelend_tc_end ]; then
			echo 1
			return
		fi
	fi
	echo 0
}


current_tc=$(get_current_tc)

if [ $(is_ts_on) == 0 ]; then
	echo "We're out of the traffic shaping period"
	if [ $current_tc -lt $tc0 ]; then
		echo "Resetting QOS to ${tc0}kbps"
		set_tc $tc0
	fi
else
	echo "We're in traffic shaping period"
	if [ $current_tc -lt $tc0 ]; then
		echo "We're alreading restricting ourselves"
		if [ $current_tc -gt $tc2 ]; then
			echo "We can restrict even more, testing if it's necessary..."
			avg_ping=$(get_ping)
			if [ $avg_ping -gt $ping_limit ]; then
				echo "Ping (${avg_ping}ns) is over the limit, restring more! Switching in TC2=${tc2}kbps"
				set_tc $tc2
			else
				if [ $(( $(date +%M) % 10 )) == 0 ]; then
					echo "We're fine but can we releave the pressure?"
					set_tc $tc0
					sleep 5
					avg_ping=$(get_ping)
					if [ $avg_ping -gt $ping_limit ]; then
						echo "Answer is NO, I guess (ping gets to high: ${avg_ping}ns"
						set_tc $tc1
					else
						echo "Yes! Switching in TC0=${tc0}kbps"
					fi
				fi
			fi
		else
			echo "... to the maximum!"
			if [ $(( $(date +%M) % 10 )) == 0 ]; then
				echo "But can we releave the pressure?"
				set_tc $tc1
				sleep 5
				avg_ping=$(get_ping)
				if [ $avg_ping -gt $ping_limit ]; then
					echo "Answer is NO, I guess (ping gets to high: ${avg_ping}ns"
					set_tc $tc2
				else
					echo "Yes! Switching in TC1=${tc1}kbps"
				fi
			fi
		fi
	else
		echo "We're not restricting ourselves, do we need to?"
		avg_ping=$(get_ping)
		if [ $avg_ping -gt $ping_limit ]; then
			echo "Ping (${avg_ping}ns) is over the limit, starting restrictions! Switching in TC1=${tc1}kbps"
			set_tc $tc1
		else
			echo "Nah, it's fine... (ping is ${avg_ping}ns)"
		fi
	fi
fi

