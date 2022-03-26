#!/bin/bash

###############################################################################
#
#  Excution Scripts for DVSM.MACRO
#  Copyright (c) 2020 HL5KY
#
#  THE SOFTWARE IS PROVIDED "AS IS" AND IN NO EVENT SHALL HL5KY BE LIABLE FOR
#  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
#  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION
#  OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN
#  CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#
###############################################################################

source /var/lib/dvswitch/dvs/var.txt

mode_now=$($MODESET)
if [ $mode_now = "YSFN" ]; then mode_now="YSF"; fi
TG=$($TUNE)
TG_S="^$TG|||"


#################################################################
#  Managing TG/Ref DB
#################################################################
function do_add_contents() {
if [[ ! -z `sudo grep "$TG_S" ${tgdb}${mode_now}_node_list.txt` ]]; then
	add_contents=$(sudo grep -i "$TG_S" ${tgdb}${mode_now}_node_list.txt)
else
    	  if [ $mode_now = "DMR" ]; then add_contents="$TG|||TG $TG"
	elif [ $mode_now = "DSTAR" ]; then add_contents="$TG|||${TG:0:6} ${TG:6:1}"
	elif [ $mode_now = "YSF" ]; then add_contents="$TG|||$TG"
	elif [ $mode_now = "NXDN" ]; then add_contents="$TG|||TG $TG"
	elif [ $mode_now = "P25" ]; then add_contents="$TG|||TG $TG"
	fi
fi
}


function do_collect() {
        ${MESSAGE} " Updating Global DB "
        ${DVSWITCH} collectProcessDataFiles
        ${MESSAGE} " Adding Favorite DB "
        sudo \cp -f /tmp/*_node_list.txt ${tgdb}

        for mode in DMR DSTAR NXDN P25 YSF; do
                sudo sed -i "1s/.*/Global|||======GLOBAL=======/g" ${tgdb}${mode}_node_list.txt;
        done
}


function do_push() {
        for mode in DMR DSTAR NXDN P25 YSF; do
                do_pushfile ${mode}
        done
}


function do_pushfile() {
        mode=$1
        sudo cat ${tgdb}${mode}_fvrt_list.txt ${tgdb}${mode}_node_list.txt > /tmp/${mode}_node_list.txt;
        sudo ${DVSWITCH} pushfile /tmp/${mode}_node_list.txt;
}

#---------------------------------------------------------------------
if [ "$1" = "add_fvrt" ]; then
	do_add_contents
        if [ $TG = "4000" ] || [ $TG = "9999" ] || [ $TG = "U" ] || [ $TG = "disconnect" ]; then :
	else sudo sed -i -e "/$TG_S/d" ${tgdb}${mode_now}_fvrt_list.txt
	fi
	line_no_file=$(sudo cat ${tgdb}${mode_now}_fvrt_list.txt | wc -l)
	line_no=$2
	if [ $line_no -gt $line_no_file ] || [ $line_no -eq 0 ]; then
		# add line at the bottom
		echo "$add_contents" | sudo tee -a ${tgdb}${mode_now}_fvrt_list.txt
	else
		# add line below $line_no
		sudo sed -i -e "${line_no}i $add_contents" ${tgdb}${mode_now}_fvrt_list.txt
	fi
	do_pushfile $mode_now

elif [ "$1" = "del_fvrt" ]; then
        if [ $TG = "4000" ] || [ $TG = "9999" ] || [ $TG = "U" ] || [ $TG = "disconnect" ]; then
                ${MESSAGE} " Can Not Delete UNLINK "
        else
		sudo sed -i -e "/$TG_S/d" ${tgdb}${mode_now}_fvrt_list.txt
		## below 2 lines are : If there are more than 2 lines matching $TG_S, get the line number of 1st matching and delete that line.
		# line_del=$(sudo grep -n "$TG_S" ${tgdb}${mode_now}_fvrt_list.txt | cut -d: -f1 | tail -1)
		# sudo sed -i "${line_del}d" ${tgdb}${mode_now}_fvrt_list.txt
		do_pushfile $mode_now
	fi

elif [ "$1" = "push_tg_ref" ]; then
	do_collect; do_push

elif [ "$1" = "reset_fvrt_db" ]; then
	if [ ${dmr_id:0:3} = 450 ]; then LN="KR"; fi

	if [ -d ${tgdb}${LN} ]; then
        	sudo \cp -f ${tgdb}${LN}/* ${tgdb}
	else
        	sudo \cp -f ${tgdb}EN/* ${tgdb}
	fi
        ${MESSAGE} " Initializing Favorite TG/Ref "
	do_push
fi

#################################################################
#  RESTART
#################################################################
if [ "$1" = "restart" ]; then
	${DVS}88_restart.sh
fi

#################################################################
#  REBOOT
#################################################################
if [ "$1" = "reboot" ]; then
	${DVS}99_reboot.sh
fi

#################################################################
#  Change MODE
#################################################################
DMR_svr_hotspot_chk() {

  if [[ ! -z `sudo grep "${rpt_id}" ${MB}MMDVM_Bridge.ini` ]]; then hotspot=""
elif [[ ! -z `sudo grep "${rpt_id_2}" ${MB}MMDVM_Bridge.ini` ]]; then hotspot="HotSpot 2"
elif [[ ! -z `sudo grep "${rpt_id_3}" ${MB}MMDVM_Bridge.ini` ]]; then hotspot="HotSpot 3"
  fi
}


if [ "$1" = "dmr" ]; then
        if [ ${mode_now} = "DMR" ]; then
       	${MESSAGE} " already on   DMR "
        else
        ${MODESET} DMR
        ${DVSWITCH} tlvAudio AUDIO_USE_GAIN ${txgain_dmr}
#        sudo systemctl stop ircddbgatewayd
        fi

elif [ "$1" = "dstar" ]; then
        if [ ${mode_now} = "DSTAR" ]; then
        ${MESSAGE} " already on   DSTAR "
#        sudo systemctl restart ircddbgatewayd
        else
#        sudo systemctl restart ircddbgatewayd
#  	sleep 12
        ${MODESET} DSTAR
        ${DVSWITCH} tlvAudio AUDIO_USE_GAIN ${txgain_dstar}
        fi

elif [ "$1" = "nxdn" ]; then
        if [ ${mode_now} = "NXDN" ]; then
        ${MESSAGE} " already on   NXDN "
        else
        ${MODESET} NXDN
        ${DVSWITCH} tlvAudio AUDIO_USE_GAIN ${txgain_nxdn}
#        sudo systemctl stop ircddbgatewayd
        fi
        ${DVSWITCH} tlvAudio AUDIO_USE_GAIN ${txgain_nxdn}

elif [ "$1" = "p25" ]; then
        if [ ${mode_now} = "P25" ]; then
        ${MESSAGE} " already on   P25 "
        else
        ${MODESET} P25
        ${DVSWITCH} tlvAudio AUDIO_USE_GAIN ${txgain_p25}
#        sudo systemctl stop ircddbgatewayd
        fi

elif [ "$1" = "ysf" ]; then
        if [ ${mode_now} = "YSF" ]; then
        ${MESSAGE} " already on   YSF "
        else
        ${MODESET} YSF
        ${DVSWITCH} tlvAudio AUDIO_USE_GAIN ${txgain_ysf}
#        sudo systemctl stop ircddbgatewayd
        fi
elif [ "$1" = "asl" ]; then
        if [ ${mode_now} = "ASL" ]; then
        ${MESSAGE} " already on   ASL "
        else
        ${MODESET} ASL
        ${DVSWITCH} tlvAudio AUDIO_USE_GAIN ${txgain_asl}
#        sudo systemctl stop ircddbgatewayd
        fi
elif [ "$1" = "stfu" ]; then
        if [ ${mode_now} = "STFU" ]; then
        ${MESSAGE} " already on   STFU "
        else
        ${MODESET} STFU
        ${DVSWITCH} tlvAudio AUDIO_USE_GAIN ${txgain_stfu}
#        sudo systemctl stop ircddbgatewayd
        fi
elif [ "$1" = "intercom" ]; then
        if [ ${mode_now} = "INTERCOM" ]; then
        ${MESSAGE} " already on   INTERCOM "
        else
        ${MODESET} INTERCOM
        ${DVSWITCH} tlvAudio AUDIO_USE_GAIN ${txgain_intercom}
#        sudo systemctl stop ircddbgatewayd
        fi
fi

#################################################################
#  Change DMR Server (BM / DMRPlus / TGIF / Others)
#################################################################
do_dmr_server() {
        ${MESSAGE} " WAIT   for   ${dmr_svr} "
#        sudo ${DVS}adnl_dmr.sh MBini_return
        sleep 1; ${MESSAGE} " WAIT................. "
        sleep 1; ${MESSAGE} " .................WAIT "
        sleep 1; ${MESSAGE} " OK   ${dmr_svr} "
}


if [ "$1" = "bm" ]; then
       ${TUNE} "${bm_password}@${bm_address}:${bm_port}"
#        update_var default_dmr_server ${bm_name}
        dmr_svr=${bm_name}; do_dmr_server

elif [ "$1" = "tgif" ]; then
       ${TUNE} "${tgif_password}@${tgif_address}:${tgif_port}"
#        update_var default_dmr_server ${tgif_name}
        dmr_svr=${tgif_name}; do_dmr_server

elif [ "$1" = "dmrplus" ]; then
       ${TUNE} "${dmrplus_password}@${dmrplus_address}:${dmrplus_port}"
#       ${TUNE} "${dmrplus_password}@${dmrplus_address}:${dmrplus_port}:StartRef=4649;RelinkTime=60;UserLink=1"
#        update_var default_dmr_server ${dmrplus_name}
        dmr_svr=${dmrplus_name}; do_dmr_server

elif [ "$1" = "other1" ]; then
       ${TUNE} "${other1_password}@${other1_address}:${other1_port}"
#        update_var default_dmr_server ${other1_name}
        dmr_svr=${other1_name}; do_dmr_server

elif [ "$1" = "other2" ]; then
       ${TUNE} "${other2_password}@${other2_address}:${other2_port}"
#        update_var default_dmr_server ${other2_name}
        dmr_svr=${other2_name}; do_dmr_server
fi

#################################################################
#  Set TlvAudio
#################################################################
do_set_tlvAudio() {

gain_now=$(sudo ${DVSWITCH} tlvAudio AUDIO_USE_GAIN)

if [ ${cal} = "plus" ]; then
	gain=$(echo "${gain_now} ${gain_change}" | awk '{printf "%.2f", $1+$2}')

elif [ ${cal} = "mnus" ]; then
	gain=$(echo "${gain_now} ${gain_change}" | awk '{printf "%.2f", $1-$2}')

elif [ ${cal} = "cent" ]; then
	gain=${gain_now}
#	${MESSAGE} " TX  GAIN   ${gain} "
fi


if [ ${mode_now} = "DMR" ]; then
        sudo sed -i -e "/^*tx_c_0.00/ c *tx_c_0.00,DMR TXGain   <${gain}>" "${AB}adv_txgain.txt";
	${MACRO} ${AB}adv_txgain.txt;
        update_var txgain_dmr ${gain};
        sudo sed -i -e "/^tlvGain/ c tlvGain = ${gain}                          ; Gain factor when tlvAudio = AUDIO_USE_GAIN (0.0 to 5.0) (1.0 = AUDIO_UNITY)" "${AB}Analog_Bridge.ini";

elif [ ${mode_now} = "DSTAR" ]; then
        sudo sed -i -e "/^*tx_c_0.00/ c *tx_c_0.00,DSTAR TXGain   <${gain}>" "${AB}adv_txgain.txt";
        ${MACRO} ${AB}adv_txgain.txt;
        update_var txgain_dstar ${gain}

elif [ ${mode_now} = "NXDN" ]; then
        sudo sed -i -e "/^*tx_c_0.00/ c *tx_c_0.00,NXDN TXGain   <${gain}>" "${AB}adv_txgain.txt";
        ${MACRO} ${AB}adv_txgain.txt;
        update_var txgain_nxdn ${gain}

elif [ ${mode_now} = "P25" ]; then
        sudo sed -i -e "/^*tx_c_0.00/ c *tx_c_0.00,P25 TXGain   <${gain}>" "${AB}adv_txgain.txt";
        ${MACRO} ${AB}adv_txgain.txt;
        update_var txgain_p25 ${gain}

elif [ ${mode_now} = "YSF" ]; then
        sudo sed -i -e "/^*tx_c_0.00/ c *tx_c_0.00,YSF TXGain   <${gain}>" "${AB}adv_txgain.txt";
        ${MACRO} ${AB}adv_txgain.txt;
        update_var txgain_ysf ${gain}
fi

${DVSWITCH} tlvAudio AUDIO_USE_GAIN ${gain}
}

#------ Main of tlvAudio ----------------------------------------
  if [ "$1" = "tx_p_0.20" ]; then cal="plus"; gain_change="0.20"; do_set_tlvAudio
elif [ "$1" = "tx_p_0.15" ]; then cal="plus"; gain_change="0.15"; do_set_tlvAudio
elif [ "$1" = "tx_p_0.10" ]; then cal="plus"; gain_change="0.10"; do_set_tlvAudio
elif [ "$1" = "tx_p_0.05" ]; then cal="plus"; gain_change="0.05"; do_set_tlvAudio
elif [ "$1" = "tx_c_0.00" ] || [ "$1" = "tx_gain" ]; then cal="cent"; do_set_tlvAudio
elif [ "$1" = "tx_m_0.05" ]; then cal="mnus"; gain_change="0.05"; do_set_tlvAudio
elif [ "$1" = "tx_m_0.10" ]; then cal="mnus"; gain_change="0.10"; do_set_tlvAudio
elif [ "$1" = "tx_m_0.15" ]; then cal="mnus"; gain_change="0.15"; do_set_tlvAudio
elif [ "$1" = "tx_m_0.20" ]; then cal="mnus"; gain_change="0.20"; do_set_tlvAudio
fi

#################################################################
#  Set UsrpAudio
#################################################################
do_set_usrpAudio() {
        sudo sed -i -e "/^*rx_0.00/ c *rx_0.00,=== RXGain   <${gain}>" "${AB}adv_rxgain.txt";
        ${MACRO} ${AB}adv_rxgain.txt;
        ${DVSWITCH} usrpAudio AUDIO_USE_GAIN ${gain}
        update_var usrpGain ${gain}
        sudo sed -i -e "/^usrpGain/ c usrpGain = ${gain}                         ; Gain factor when usrpAudio = AUDIO_USE_GAIN (0.0 to 5.0) (1.0 = AUDIO_UNITY)" "${AB}Analog_Bridge.ini"
}

  if [ "$1" = "rx_gain" ]; then gain=$(sudo ${DVSWITCH} usrpAudio AUDIO_USE_GAIN); do_set_usrpAudio
elif [ "$1" = "rx_0.00" ]; then gain=$(sudo ${DVSWITCH} usrpAudio AUDIO_USE_GAIN); do_set_usrpAudio
elif [ "$1" = "rx_1.00" ]; then gain="1.00"; do_set_usrpAudio
elif [ "$1" = "rx_2.00" ]; then gain="2.00"; do_set_usrpAudio
elif [ "$1" = "rx_3.00" ]; then gain="3.00"; do_set_usrpAudio
elif [ "$1" = "rx_4.00" ]; then gain="4.00"; do_set_usrpAudio
elif [ "$1" = "rx_5.00" ]; then gain="5.00"; do_set_usrpAudio
elif [ "$1" = "rx_6.00" ]; then gain="6.00"; do_set_usrpAudio
elif [ "$1" = "rx_7.00" ]; then gain="7.00"; do_set_usrpAudio
elif [ "$1" = "rx_8.00" ]; then gain="8.00"; do_set_usrpAudio
elif [ "$1" = "rx_9.00" ]; then gain="9.00"; do_set_usrpAudio
elif [ "$1" = "rx_10.0" ]; then gain="10.0"; do_set_usrpAudio
fi

#################################################################
#  DROP DYNAMIC TG / HOTSPOT
#################################################################
do_hotspot() {
	${MESSAGE} " WAIT   for   ${hotspot}   ${dmr_id} ${hs_id:7} "
	General=$(grep -n "\[General" ${MB}MMDVM_Bridge.ini | cut -d':' -f1)
	id_line=`expr $General + 2`
	sudo sed -i -e "${id_line}s/.*/Id=${hs_id}/" "${MB}MMDVM_Bridge.ini"
	sudo systemctl restart mmdvm_bridge
	update_var rpt_id_now ${hs_id}
	sleep 1; ${MESSAGE} " WAIT................. "
	sleep 1; ${MESSAGE} " .................WAIT "
	sleep 1; ${MESSAGE} " OK   ${hotspot}   ${dmr_id} ${hs_id:7} "
}

  if [ "$1" = "hotspot_1" ]; then hotspot="HotSpot 1"; hs_id=${rpt_id}; do_hotspot
elif [ "$1" = "hotspot_2" ]; then hotspot="HotSpot 2"; hs_id=${rpt_id_2}; do_hotspot
elif [ "$1" = "hotspot_3" ]; then hotspot="HotSpot 3"; hs_id=${rpt_id_3}; do_hotspot
  fi

if [ "$1" = "hotspot" ]; then
        ${MESSAGE} " WAIT   for   ${dmr_id} $2 "
        General=$(grep -n "\[General" ${MB}MMDVM_Bridge.ini | cut -d':' -f1)
        id_line=`expr $General + 2`
        sudo sed -i -e "${id_line}s/.*/Id=${dmr_id}$2/" "${MB}MMDVM_Bridge.ini"
        sudo systemctl restart mmdvm_bridge
	update_var rpt_id_now ${dmr_id}$2
        sleep 1; ${MESSAGE} " WAIT................. "
        sleep 1; ${MESSAGE} " .................WAIT "
        sleep 1; ${MESSAGE} " OK   ${dmr_id} $2 "
fi


if  [ "$1" = "drop_dynamic_tg" ]; then
		hs_id=${rpt_id}
		${TUNE} 4000
		${MESSAGE} " Drop Dynamic TGs "
               	General=$(grep -n "\[General" ${MB}MMDVM_Bridge.ini | cut -d':' -f1)
               	id_line=`expr $General + 2`
               	sudo sed -i -e "${id_line}s/.*/Id=${hs_id}/" "${MB}MMDVM_Bridge.ini"
              	sudo systemctl restart mmdvm_bridge
		update_var rpt_id_now ${hs_id}
	        sleep 1; ${MESSAGE} " WAIT................. "
        	sleep 1; ${MESSAGE} " .................WAIT "
		sleep 1; ${MESSAGE} "  FINISHED  "
fi

#################################################################
#  CPU Doctor
#################################################################

if [ "$1" = "cpu_doc" ]; then
	sudo systemctl stop ircddbgatewayd
	${MESSAGE}          "   Lowering CPU Load ..."
        sleep 3; ${MESSAGE} " .... WAIT 1 min ...... "
	sleep 40; sudo systemctl restart ircddbgatewayd
        sleep 20; ${MESSAGE} "        FINISHED ..... "
fi


exit 0

