#!/usr/bin/env bash

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# This script is contains different utility method to run validation tests  #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

# Colors
NORMAL_FONT="\e[0m"
RED_FONT="\e[31;1m"
GREEN_FONT="\e[32;1m"
YELLOW_FONT="\e[33;1m"
CYAN_FONT="\033[0;36m"

# Miscellaneous
CURRENT_DATE_TIME=`date +%Y-%m-%d_%H.%M.%S`
MYPID=$$

# UART Log files
UART_SEC_OUTPUT_FILE_NAME=refinfra-${MYPID}-uart-0-sec_$CURRENT_DATE_TIME
UART_NSEC_OUTPUT_FILE_NAME=refinfra-${MYPID}-uart-0-nsec_$CURRENT_DATE_TIME
UART_AP_RMM_NS_OUTPUT_FILE_NAME=refinfra-${MYPID}-ap_rmm_ns_$CURRENT_DATE_TIME
UART_RSE_OUTPUT_FILE_NAME=refinfra-${MYPID}-uart-rse_$CURRENT_DATE_TIME
UART0_SCP_OUTPUT_FILE_NAME=refinfra-${MYPID}-uart-0-scp_$CURRENT_DATE_TIME
UART0_MCP_OUTPUT_FILE_NAME=refinfra-${MYPID}-uart-0-mcp_$CURRENT_DATE_TIME
UART_LCP_OUTPUT_FILE_NAME=refinfra-${MYPID}-uart-lcp_$CURRENT_DATE_TIME

# creates a nor flash image with the path and filename passed as parameter.
create_nor_flash_image () {
	if [ ! -f $1 ]; then
		echo -e "\n[INFO] Creating NOR Flash image"
		#create 64MB image of 256K block size
		dd if=/dev/zero of=$1 bs=256K count=256 > /dev/null 2>&1
		#Gzip it
		gzip $1 && mv $1.gz $1
	fi
}

# kill the model's children, then kill the model
kill_model () {
    if [[ -z "$MODEL_PID" ]]; then
        :
    else
        echo -e "\n[INFO] Killing all children of PID: $MODEL_PID"
        MODEL_CHILDREN=$(pgrep -P $MODEL_PID)
        for CHILD in $MODEL_CHILDREN
        do
            echo -e "\n[INFO] Killing $CHILD $(ps -e | grep $CHILD)"
            kill -9 $CHILD > /dev/null 2>&1
        done
        kill -9 $MODEL_PID > /dev/null 2>&1
        echo -e "\n[INFO] All model processes killed successfully."
    fi
}

# parse_log_file: waits until the search string is found in the log file
#				  or timeout occurs
# Arguments: 1. log file name
#            2. search string
#            3. timeout
# Return Value: 0 -> Success
#              -1 -> Failure
parse_log_file ()
{
	local testdone=1
	local cnt=0
	local logfile=$1
	local search_str=$2
	local timeout=$3

	if [ "$timeout" -le 0 ] || [ "$timeout" -gt $SGI_TEST_MAX_TIMEOUT ]; then
		echo -e "\n[WARN] timeout value $timeout is invalid. Setting" \
			"timeout to $SGI_TEST_MAX_TIMEOUT seconds."
		timeout=$SGI_TEST_MAX_TIMEOUT;
	fi

	while [  $testdone -ne 0 ]; do
		sleep 1
		if ls $logfile 1> /dev/null 2>&1; then
			tail $logfile | grep -q -s -e "$search_str" > /dev/null 2>&1
			testdone=$?
		fi
		if [ "$cnt" -ge "$timeout" ]; then
			echo -e "\n[ERROR]: ${FUNCNAME[0]}: Timedout or $logfile may not found!\n"
			return -1
		fi
		cnt=$((cnt+1))
	done
	return 0
}

##
# send shutdown signal to the os
##
send_shutdown () {
	RET=1

	echo -e "\n[INFO] Sending Shutdown Signal ...\n"
	ssh  -o ServerAliveInterval=30 \
	 -o ServerAliveCountMax=720 \
	 -o StrictHostKeyChecking=no \
	 -o UserKnownHostsFile=/dev/null root@$2 \
	 'shutdown -h now' 2>&1 | tee -a $1
	RET=$?
	return $RET
}
