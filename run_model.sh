#!/usr/bin/env bash

NORMAL_FONT="\e[0m"
RED_FONT="\e[31;1m"
GREEN_FONT="\e[32;1m"
YELLOW_FONT="\e[33;1m"
CYAN_FONT="\033[0;36m"
ROOTDIR="./output/rdv3cfg1"
OUTDIR=${ROOTDIR}/rdv3cfg1
MODEL_TYPE="rdv3cfg1"
MODEL_PARAMS=""
FS_TYPE=""
TAP_INTERFACE=""
HEADLESS="false"

source $PWD/common_util.sh

# Check that the path to the model exists.
if [ ! -f "$MODEL" ]; then
	echo "ERROR: you should set variable MODEL to point to a valid FVP_RD_V3_Cfg1" \
		 "model binary, currently it is set to \"$MODEL\""
	exit 1
fi

#Path to the binary models
PATH_TO_MODEL=$(dirname "${MODEL}")

if [ $# -eq 0 ]; then
	echo -e "$YELLOW_FONT Warning!!!!!: Continuing with default : -f busybox" >&2
	echo -e "$YELLOW_FONT Use for more option  ${0##*/} -h|-- help $NORMAL_FONT" >&2
	FS_TYPE="busybox";
	NTW_ENABLE="false";
	VIRT_IMG="false";
	EXTRA_MODEL_PARAMS="";
	VIRTIO_NET="false";
fi

# Display usage message and exit
function usage_help {
	echo -e "$GREEN_FONT usage: ${0##*/} -n <interface_name> -f <fs_type> -v <virtio_image_path> -d <sata_image_path> -a <extra_model_params>" >&2
	echo -e "$GREEN_FONT fs_type = $RED_FONT busybox $NORMAL_FONT" >&2
	echo -e "$GREEN_FONT network_enabled = $RED_FONT true $GREEN_FONT or $RED_FONT false $NORMAL_FONT" >&2
	echo -e "$GREEN_FONT virtio_imag_path = Please input virtio image path $NORMAL_FONT" >&2
	echo -e "$GREEN_FONT sata_image_path = Please input sata disk image path $NORMAL_FONT" >&2
	echo -e "$GREEN_FONT extra_model_params = Input additional model parameters $NORMAL_FONT" >&2
}

while test $# -gt 0; do
	case "$1" in
		-h|--help)
			usage_help
			exit 1
			;;
		-f)
			shift
			if test $# -gt 0; then
				FS_TYPE=$1
			fi
			shift
			;;
		-n)
			shift
			if test $# -gt 0; then
				NTW_ENABLE=$1
			fi
			shift
			;;
		-v)
			shift
			if test $# -gt 0; then
				VIRTIO_IMAGE_PATH=$1
			fi
			shift
			;;
		-d)
			shift
			if test $# -gt 0; then
				SATADISK_IMAGE_PATH=$1
			fi
			shift
			;;
		-a)
			shift
			if test $# -gt 0; then
				EXTRA_MODEL_PARAMS=$1
			fi
			shift
			;;
		-j)
			HEADLESS="true"
			shift
			;;
		-p)
			shift
			shift
			;;
		-t)
			shift
			;;
		*)
			usage_help
			exit 1
			;;
	esac
done

if [[ -z $NTW_ENABLE ]]; then
	echo -e "$RED_FONT Continue with <network_enabled> as false !!! $NORMAL_FONT" >&2
	NTW_ENABLE="false";
fi

if [ ${NTW_ENABLE,,} == "true" ]; then
	find_tap_interface
	if [[ -z $TAP_INTERFACE ]]; then
		echo -e "$YELLOW_FONT Please input a unique bridge interface name for network setup $NORMAL_FONT" >&2
		read TAP_INTERFACE
		if [[ -z $TAP_INTERFACE ]]; then
			echo -e "$RED_FONT network interface name is empty $NORMAL_FONT" >&2
			exit 1;
		fi
	fi
fi

if [ ${NTW_ENABLE,,} != "true" ] && [ ${NTW_ENABLE,,} != "false" ]; then
	echo -e "$RED_FONT Unsupported <network_enabled> selected  $NORMAL_FONT" >&2
	usage_help
	exit 1;
fi

if [[ -z $FIP_IMAGE ]]; then
	echo -e "$RED_FONT Continue with <FIP_IMAGE> as fip-uefi.bin !!! $NORMAL_FONT" >&2
	FIP_IMAGE="fip-uefi.bin";
fi

if [[ -n "$VIRTIO_IMAGE_PATH" ]]; then
	MODEL_PARAMS="$MODEL_PARAMS \
			-C ros.board.virtioblockdevice.image_path=${VIRTIO_IMAGE_PATH}"
fi

if [[ -n "$SATADISK_IMAGE_PATH" ]]; then
	MODEL_PARAMS="$MODEL_PARAMS \
			-C pcie_group_0.pcie0.pcie_rc.ahci0.ahci.image_path="${SATADISK_IMAGE_PATH}""
fi

mkdir -p ./$MODEL_TYPE

if [ ${NTW_ENABLE,,} == "true" ]; then
	MODEL_PARAMS="$MODEL_PARAMS \
		-C ros.board.virtio_net.hostbridge.interfaceName="$TAP_INTERFACE" \
		-C ros.board.virtio_net.enabled=1 \
		-C ros.board.virtio_net.transport="legacy" "
fi

echo "NOR1 flash image: $PWD/nor1_flash.img"
create_nor_flash_image "$PWD/nor1_flash.img"
echo "NOR2 flash image: $PWD/nor2_flash.img"
create_nor_flash_image "$PWD/nor2_flash.img"

if [ "$HEADLESS" == "true" ] ; then
	MODEL_PARAMS="$MODEL_PARAMS \
		-C ros.disable_visualisation=true \
		-C css.sysctrl.terminal_rse_uart.start_telnet=0 \
		-C css.sysctrl.scp.terminal_uart_scp.start_telnet=0 \
		-C css.sysctrl.scp.terminal_uart_lcp.start_telnet=0 \
		-C css.sysctrl.mcp.terminal_uart_mcp.start_telnet=0 \
		-C css.ap_periph.terminal_sec_uart.start_telnet=0 \
		-C css.ap_periph.terminal_ns_uart0.start_telnet=0 \
		-C css.ap_periph.terminal_ns_uart1.start_telnet=0
		"
fi

# print the model version.
${MODEL} --version


LCP_UART_PARAMS=" \
	-C css.sysctrl.scp.pl011_uart_lcp.baud_rate=115200 \
	-C css.sysctrl.scp.pl011_uart_lcp.uart_enable=1 \
	-C css.sysctrl.scp.pl011_uart_lcp.clock_rate=24000000 \
	-C css.sysctrl.scp.pl011_uart_lcp.shutdown_on_eot=1 \
	-C css.sysctrl.scp.pl011_uart_lcp.unbuffered_output=1 \
	-C css.sysctrl.scp.pl011_uart_lcp.out_file=${MODEL_TYPE,,}/${UART_LCP_OUTPUT_FILE_NAME} \
	"

AP2SCP_NS_MHU3_DBCH_PARAMS="\
	-C css.sysctrl.scp.ap2scp_mhu_s.NUM_DB_CH=6 \
	-C css.sysctrl.scp.scp2ap_mhu_s.NUM_DB_CH=6 \
	"

AP2SCP_NS_MHU3_PARAMS=" \
	$AP2SCP_NS_MHU3_DBCH_PARAMS \
	"

AP2SCP_S_MHU3_DBCH_PARAMS="\
	-C css.sysctrl.scp.ap2scp_mhu_s.NUM_DB_CH=6 \
	-C css.sysctrl.scp.scp2ap_mhu_s.NUM_DB_CH=6 \
	"

AP2SCP_S_MHU3_PARAMS=" \
	$AP2SCP_S_MHU3_DBCH_PARAMS \
	"

SCP2RSE_CMU4_MHU3_PARAMS=" \
	-C css.sysctrl.rse.CMU4_NUM_DB_CH=5 \
	"

AP2RSE_S_MHU_PARAMS=" \
	-C css.sysctrl.rse.CMU0_NUM_DB_CH=16 \
	"

PARAMS="\
	-C css.sysctrl.rse.rom.raw_image=$OUTDIR/tf_m_rom.bin \
	--data css.sysctrl.rse.cpu=$OUTDIR/tf_m_flash.bin@0xB0000000 \
	--data css.sysctrl.rse.cpu=$OUTDIR/tf_m_vm0_0.bin@0x31000400 \
	--data css.sysctrl.rse.cpu=$OUTDIR/tf_m_vm1_0.bin@0x31080000 \
	-C ros.board.flashloader0.fname=$OUTDIR/$FIP_IMAGE \
	-C ros.board.flashloader1.fname=$PWD/nor1_flash.img \
	-C ros.board.flashloader1.fnameWrite=$PWD/nor1_flash.img \
	-C ros.board.flashloader2.fname=$PWD/nor2_flash.img \
	-C ros.board.flashloader2.fnameWrite=$PWD/nor2_flash.img \
	-I -R \
	-C css.sysctrl.rse_uart.out_file=${MODEL_TYPE,,}/${UART_RSE_OUTPUT_FILE_NAME} \
	-C css.sysctrl.rse_uart.unbuffered_output=1 \
	-C css.sysctrl.rse_uart.uart_enable=true \
	-C css.sysctrl.scp.pl011_uart_scp.out_file=${MODEL_TYPE,,}/${UART0_SCP_OUTPUT_FILE_NAME} \
	-C css.sysctrl.scp.pl011_uart_scp.unbuffered_output=1 \
	-C css.sysctrl.scp.pl011_uart_scp.uart_enable=true \
	-C css.sysctrl.mcp.pl011_uart_mcp.out_file=${MODEL_TYPE,,}/${UART0_MCP_OUTPUT_FILE_NAME} \
	-C css.sysctrl.mcp.pl011_uart_mcp.unbuffered_output=1 \
	-C css.sysctrl.mcp.pl011_uart_mcp.uart_enable=true \
	-C css.ap_periph.sec_uart.out_file=${MODEL_TYPE,,}/${UART_SEC_OUTPUT_FILE_NAME} \
	-C css.ap_periph.sec_uart.unbuffered_output=1 \
	-C css.ap_periph.sec_uart.uart_enable=true \
	-C css.ap_periph.ns_uart0.out_file=${MODEL_TYPE,,}/${UART_NSEC_OUTPUT_FILE_NAME} \
	-C css.ap_periph.ns_uart0.unbuffered_output=1 \
	-C css.ap_periph.ns_uart0.uart_enable=true \
	-C css.ap_periph.ns_uart1.out_file=${MODEL_TYPE,,}/${UART_AP_RMM_NS_OUTPUT_FILE_NAME} \
	-C css.ap_periph.ns_uart1.unbuffered_output=1 \
	-C css.ap_periph.ns_uart1.uart_enable=true \
	-C css.sysctrl.rse.DISABLE_GATING=true \
	-C css.sysctrl.HAS_RSE_CPU_PRIVATE_REGION=1 \
	-C css.gic_distributor.ITS-device-bits=20 \
	-C css.sysctrl.mcp.pl011_uart_mcp.shutdown_tag='shutting' \
	-C pcie_group_0.pcie0.hierarchy_file_name=<default> \
	-C pcie_group_0.pcie0.pcie_rc.ahci0.endpoint.ats_supported=true \
	-C pcie_group_0.pcie1.hierarchy_file_name=example_pcie_hierarchy_1.json \
	-C pcie_group_0.pcie2.hierarchy_file_name=example_pcie_hierarchy_2.json \
	-C pcie_group_0.pcie3.hierarchy_file_name=example_pcie_hierarchy_3.json \
	-C pcie_group_0.pcie4.hierarchy_file_name=example_pcie_hierarchy_4.json \
	-C css.sysctrl.rse.intchecker.ICBC_RESET_VALUE=0x0000011B
	${SCP2RSE_CMU4_MHU3_PARAMS} \
	${AP2SCP_NS_MHU3_PARAMS} \
	${AP2SCP_S_MHU3_PARAMS} \
	${AP2RSE_S_MHU_PARAMS} \
	${LCP_UART_PARAMS} \
	${MODEL_PARAMS} \
	${EXTRA_MODEL_PARAMS}"

echo
echo "RSE UART Log    = "$PWD/${MODEL_TYPE,,}/${UART_RSE_OUTPUT_FILE_NAME}
echo "SCP UART Log    = "$PWD/${MODEL_TYPE,,}/${UART0_SCP_OUTPUT_FILE_NAME}
echo "MCP UART Log    = "$PWD/${MODEL_TYPE,,}/${UART0_MCP_OUTPUT_FILE_NAME}
echo "LCP UART Log    = "$PWD/${MODEL_TYPE,,}/${UART_LCP_OUTPUT_FILE_NAME}
echo "AP S UART Log   = "$PWD/${MODEL_TYPE,,}/${UART_SEC_OUTPUT_FILE_NAME}
echo "AP NS UART Log  = "$PWD/${MODEL_TYPE,,}/${UART_NSEC_OUTPUT_FILE_NAME}
echo "AP RMM UART Log = "$PWD/${MODEL_TYPE,,}/${UART_AP_RMM_NS_OUTPUT_FILE_NAME}
echo
echo -e "${GREEN_FONT}Launching RD-V3-Cfg1 model${NORMAL_FONT}"
echo
echo -e "${CYAN_FONT}${MODEL} ${PARAMS}${NORMAL_FONT}"
echo

if [[ $HEADLESS == "true" ]]; then
	# Execute model in background
	${MODEL} ${PARAMS} 2>&1 &
	if [[ $? != "0" ]]; then
		echo "Failed to launch the model"
		export MODEL_PID=0
	else
		echo "Model launched with pid: "$!
		export MODEL_PID=$!
	fi
else
	# Execute model in foreground
	${MODEL} ${PARAMS} 2>&1
fi
