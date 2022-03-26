#!/bin/bash

source /var/lib/dvswitch/dvs/var.txt

#===================================
SCRIPT_VERSION="1.0"
SCRIPT_AUTHOR="HL5KY"
SCRIPT_DATE="2021-11-18"
#===================================

FILE_DAT=/var/lib/mmdvm/DMRIds.dat
FILE_NEW=/var/lib/mmdvm/DMRIds.new
FILE_BAK=/var/lib/mmdvm/DMRIds.bak
LIB=/var/lib/mmdvm

FILE_THIS=${DVS}DMRIds_chk.sh
FILE_CRON=/etc/crontab
FILE_LOG=/var/log/dvswitch/dvsmu.log

ORG_FILE_SIZE=4585788
ORG_NUMBER_HL=1439

MIN_FILE_SIZE=4584788
MIN_NUMBER_HL=1429

MAX_LOG_LINE=500

CHK_CALLSIGNS="HL5KY HL5BTF HL5BHH HL5PPT HL2DRY DS5QDR DS5ANY DS5TUK JA2HWE ZL1SN"

min=$(sed -n -e '/DMRIds/p' $FILE_CRON | cut -f 1 -d' ')

time=$(date +%Y-%m-%d'  '%H:%M:%S)
cron_daily_time=$(sed -n -e '/cron.daily/p' $FILE_CRON | cut -f 2 -d' ')
cron_daily_time=$(echo $cron_daily_time | cut -f1 -d' ')
cron_daily_min=$(sed -n -e '/cron.daily/p' $FILE_CRON | cut -f 1 -d' ')
cron_daily_min_plus_3=$((cron_daily_min + 3))
cron_daily_min_plus_4=$((cron_daily_min + 4))

#--------------------------------------------------------------
function set_chk_time_agn_1min() {
sudo sed -i -e "/DMRIds/ c $cron_daily_min_plus_4 $cron_daily_time * * * root /usr/local/dvs/DMRIds_chk.sh" $FILE_CRON
}
#--------------------------------------------------------------
function set_chk_time_agn_10min() {

min=$(sed -n -e '/DMRIds/p' $FILE_CRON | cut -f 1 -d' ')
new_min=$((min + 10))

if [ $new_min -ge 60 ]; then
	sudo sed -i -e "/DMRIds/ c $cron_daily_min_plus_3 $cron_daily_time * * * root /usr/local/dvs/DMRIds_chk.sh" $FILE_CRON
else
	sudo sed -i -e "/DMRIds/ c $new_min $cron_daily_time * * * root /usr/local/dvs/DMRIds_chk.sh" $FILE_CRON
fi
}
#--------------------------------------------------------------
function logging() {

sudo sed -i "1 i\\$log_line" $FILE_LOG > /dev/null 2>&1

line=`cat $FILE_LOG | wc -l`

if [ $line -gt $MAX_LOG_LINE ]; then
	sudo sed -i '$ d' $FILE_LOG
fi
}
#--------------------------------------------------------------
function cp_bak_to_dat() {

if [ -e $FILE_BAK ]; then
	sudo cp -f $FILE_BAK $FILE_DAT
fi
}
#--------------------------------------------------------------
function db_download() {
${DEBUG} curl -s -N "https://database.radioid.net/static/user.csv" | awk -F, 'NR>1 {if ($1 > "") print $1,$2,$3}' | sudo tee $FILE_NEW  > /dev/null 2>&1
}
#--------------------------------------------------------------
function file_size_chk() {

FILE_SIZE=$(wc -c $FILE_CHK | awk '{print $1}')

if [ $FILE_SIZE -lt $MIN_FILE_SIZE ]; then #smaller
	chk_result=no
else    #greater
	chk_result=ok
fi
}
#--------------------------------------------------------------
function hl_num_chk() {

NUMBER_HL=$(grep ^450  $FILE_CHK | wc -l)

if [ $NUMBER_HL -lt $MIN_NUMBER_HL ]; then #smaller
	chk_result=no
else    #greater
	chk_result=ok
fi
}
#--------------------------------------------------------------
function callsign_chk() {

for CALLSIGN in ${CHK_CALLSIGNS}; do
        if [[ -z `grep $CALLSIGN $FILE_CHK` ]]; then
		chk_result=no
		break
	else
		chk_result=ok
        fi
done
}

#==============================================================
# MAIN
#==============================================================

if [ ! -e $FILE_LOG ]; then
	echo "$time  Start a new dvsMU Log" | sudo tee $FILE_LOG > /dev/null 2>&1
	log_line=--------------------------------------------------; logging
fi

if [ $min = $cron_daily_min_plus_3 ]; then

	FILE_CHK=/var/lib/mmdvm/DMRIds.dat

	file_size_chk
	if [ $chk_result = no ]; then
		set_chk_time_agn_1min
		log_line="$time  dat_file_size_err DAT: $FILE_SIZE < B4: ORG_FILE_SIZE"; logging
		cp_bak_to_dat
		exit
	fi

	hl_num_chk
	if [ $chk_result = no ]; then
		set_chk_time_agn_1min
		log_line="$time  dat_file_hl_num_err DAT: $NUMBER_HL < B4: $ORG_NUMBER_HL"; logging
                cp_bak_to_dat
                exit
	fi

        callsign_chk
        if [ $chk_result = no ]; then
		set_chk_time_agn_1min
		log_line="$time  dat_file_callsign_err $CALLSIGN"; logging
                cp_bak_to_dat
                exit
        fi

	sudo cp -f $FILE_DAT $FILE_BAK
	log_line="$time  DMRIds.dat is OK"; logging
	log_line=--------------------------------------------------; logging

else
        FILE_CHK=/var/lib/mmdvm/DMRIds.new

	db_download

	file_size_chk
	if [ $chk_result = no ]; then
		set_chk_time_agn_10min
		log_line="$time  new_file_size_err NEW: $FILE_SIZE < B4: ORG_FILE_SIZE"; logging
		exit
	fi

	hl_num_chk
	if [ $chk_result = no ]; then
		set_chk_time_agn_10min
		log_line="$time  new_file_hl_num_err NEW: $NUMBER_HL < B4: $ORG_NUMBER_HL"; logging
		exit
	fi

	callsign_chk
        if [ $chk_result = no ]; then
                set_chk_time_agn_10min
		log_line="$time  new_file_callsign_err $CALLSIGN"; logging
		exit
        fi


# when all checks for new file are ok, excute followings

        sudo sed -i -e "/DMRIds/ c $cron_daily_min_plus_3 $cron_daily_time * * * root /usr/local/dvs/DMRIds_chk.sh" $FILE_CRON

        sudo sed -i -e "/^ORG_FILE_SIZE/ c ORG_FILE_SIZE=$FILE_SIZE" $FILE_THIS

	NEW_MIN_FILE_SIZE=$(($FILE_SIZE-1000))
	sudo sed -i -e "/^MIN_FILE_SIZE/ c MIN_FILE_SIZE=$NEW_MIN_FILE_SIZE" $FILE_THIS

        sudo sed -i -e "/^ORG_NUMBER_HL/ c ORG_NUMBER_HL=$NUMBER_HL" $FILE_THIS

	NEW_MIN_NUMBER_HL=$(($NUMBER_HL-10))
	sudo sed -i -e "/^MIN_NUMBER_HL/ c MIN_NUMBER_HL=$NEW_MIN_NUMBER_HL" $FILE_THIS

	sudo cp -f $FILE_NEW $FILE_DAT
	sudo cp -f $FILE_NEW $FILE_BAK
	log_line="$time  new DMRIds.dat is OK"; logging
	log_line=--------------------------------------------------; logging

fi

