#!/bin/bash

# dvsMU내의 메뉴에서 upgrade하면 이 프로그램이 실행됨
# dvsMU 개발시에, 정식 발표버전과 그 이전 버전의 내용이 달라짐. 이에 따라 정식버전 발표시에 그 이전의 내용과 다른 내용을 수정하는 내용이 있음. (man_log 관련한 내용)
# 차후에 upgrade 할 내용이 있으면 여기에 계속 주가하면 됨.
# 차후에 변수가 추가될때를 고려하여 변수가 추가되는 루틴을 미리 작성해 둠.

user_array="01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40"

#====== crontab 설정 (man_log 및 DMRIds_chk.sh의 실행을 위한 설정) =============================================
function set_crontab() {

FILE_CRON=/etc/crontab

# <<<crontab에서 daily가 있는 줄의 내용 : 25 6    * * *   root    test -x /usr/sbin/anacron || ( cd / && run-parts --report /etc/cron.daily )>>>

cron_daily_time=$(sed -n -e '/cron.daily/p' $FILE_CRON | cut -f 2 -d' ')
cron_daily_time=$(echo $cron_daily_time | cut -f1 -d' ')
cron_daily_min=$(sed -n -e '/cron.daily/p' $FILE_CRON | cut -f 1 -d' ')
cron_daily_min_plus_3=$((cron_daily_min + 3))
cron_daily_min_plus_4=$((cron_daily_min + 4))

if [[ ! -z `sudo grep "time" $FILE_CRON` ]]; then
	sudo sed -i -e "/time/ c time=3" $FILE_CRON
else
	echo "time=3" | sudo tee -a $FILE_CRON
fi

if [[ ! -z `sudo grep "man_log" $FILE_CRON` ]]; then
	sudo sed -i -e "/man_log/ c 0 3 * * * root /usr/local/dvs/man_log" $FILE_CRON
else
	echo "0 3 * * * root /usr/local/dvs/man_log" | sudo tee -a $FILE_CRON
fi

if [[ ! -z `sudo grep "reboot" $FILE_CRON` ]]; then
	sudo sed -i -e "/reboot/ c reboot=yes" $FILE_CRON
else
	echo "reboot=yes" | sudo tee -a $FILE_CRON
fi

if [[ ! -z `sudo grep "DMRIds" $FILE_CRON` ]]; then
	sudo sed -i -e "/DMRIds/ c $cron_daily_min_plus_3 $cron_daily_time * * * root /usr/local/dvs/DMRIds_chk.sh" $FILE_CRON
else
	echo "$cron_daily_min_plus_3 $cron_daily_time * * * root /usr/local/dvs/DMRIds_chk.sh" | sudo tee -a $FILE_CRON
fi
}

#====== 여러가지 수정사항을 처리하는 루틴 =========================
function do_change() {

# 주파수가 00000 이면, 430으로 수정
update_ini="sudo ${MB}dvswitch.sh updateINIFileValue"

source /var/lib/dvswitch/dvs/var00.txt > /dev/null 2>&1
if [ $rx_freq = 000000000 ]; then
	file=/var/lib/dvswitch/dvs/var00.txt
	tag=rx_freq; value=430000000
	sudo sed -i -e "/^$tag=/ c $tag=$value" $file
	tag=tx_freq; value=430000000
	sudo sed -i -e "/^$tag=/ c $tag=$value" $file
fi

# 아래의 항목들은 지운다.
sudo sed -i -e "/^bm_password=/ c bm_password=" $file
sudo sed -i "/^lat=/ c lat=" $file
sudo sed -i "/^lon=/ c lon=" $file
sudo sed -i "/^desc=/ c desc=dvsMU" $file

source /var/lib/dvswitch/dvs/var.txt > /dev/null 2>&1
if [ $rx_freq = 000000000 ]; then
	file=/var/lib/dvswitch/dvs/var.txt
	tag=rx_freq; value=430000000
	sudo sed -i -e "/^$tag=/ c $tag=$value" $file
	tag=tx_freq; value=430000000
	sudo sed -i -e "/^$tag=/ c $tag=$value" $file
fi

source /opt/MMDVM_Bridge/MMDVM_Bridge.ini > /dev/null 2>&1
if [ $RXFrequency = "000000000" ]; then
	file=/opt/MMDVM_Bridge/MMDVM_Bridge.ini
	section=Info; tag=RXFrequency; value=430000000
	$update_ini $file $section $tag $value
	section=Info; tag=TXFrequency; value=430000000
	$update_ini $file $section $tag $value
fi

# DMR_fvrt_list.txt 수정
file=/var/lib/dvswitch/dvs/tgdb/DMR_fvrt_list.txt
if [[ -z `sudo grep "45039" $file` ]]; then
	sudo wget -O $file https://raw.githubusercontent.com/hp3icc/DVSMU/main/tgdb_KR/DMR_fvrt_list.txt
fi

file=/var/lib/dvswitch/dvs/tgdb/KR/DMR_fvrt_list.txt
if [[ -z `sudo grep "45039" $file` ]]; then
	sudo wget -O $file https://raw.githubusercontent.com/hp3icc/DVSMU/main/tgdb_KR/DMR_fvrt_list.txt
fi

user_array
for user in $user; do
source /var/lib/dvswitch/dvs/var${user}.txt > /dev/null 2>&1
if [ -e /var/lib/dvswitch/dvs/var${user}.txt ] && [ x${call_sign} != x ]; then
	if [ $rx_freq = 000000000 ]; then
		file=/var/lib/dvswitch/dvs/var${user}.txt
		tag=rx_freq; value=430000000
		sudo sed -i -e "/^$tag=/ c $tag=$value" $file
		tag=tx_freq; value=430000000
		sudo sed -i -e "/^$tag=/ c $tag=$value" $file
	fi

	source /opt/user${user}/MMDVM_Bridge.ini > /dev/null 2>&1
	if [ $RXFrequency = "000000000" ]; then
		file=/opt/user${user}/MMDVM_Bridge.ini
		section=Info; tag=RXFrequency; value=430000000
		$update_ini $file $section $tag $value
		section=Info; tag=TXFrequency; value=430000000
		$update_ini $file $section $tag $value
	fi

	file=/var/lib/dvswitch/dvs/tgdb/user${user}/DMR_fvrt_list.txt
	if [[ -z `sudo grep "45039" $file` ]]; then
		sudo wget -O /var/lib/dvswitch/dvs/tgdb/user${user}/DMR_fvrt_list.txt https://raw.githubusercontent.com/hp3icc/DVSMU/main/tgdb_KR/DMR_fvrt_list.txt
	fi
fi
done
}

#====== 변수가 추가될때 처리하는 루틴 시작부분 =============================================
function add_var_val() {
#sudo wget -O /var/lib/dvswitch/dvs/var00.txt https://raw.githubusercontent.com/hp3icc/DVSMU/main/var00.txt > /dev/null 2>&1

# When updating, the stanzas will be appended to varxx.txt, if not exist.
# each item needs space in between. no qutation marks are needed
new_var="txgain_asl txgain_stfu txgain_intercom"
# default value will be applied once, at the first time
# each item needs space in between. if the item is character, it needs quotation marks.
new_val=(0.35 0.35 0.35)

function do_add() {
for var in ${new_var}; do
        if [[ -z `sudo grep "^$var" $file` ]]; then
                echo "$var=" | sudo tee -a $file > /dev/null 2>&1
                val=${new_val[$n]}
                sudo sed -i -e "/^$var=/ c $var=$val" $file
        fi
        n=$(($n+1))
done
}

file=/var/lib/dvswitch/dvs/var.txt
	do_add; n=0

file=/var/lib/dvswitch/dvs/var00.txt
	do_add; n=0

user_array
for user in $user; do
source /var/lib/dvswitch/dvs/var${user}.txt > /dev/null 2>&1
if [ -e /var/lib/dvswitch/dvs/var${user}.txt ] && [ x${call_sign} != x ]; then
	file=/var/lib/dvswitch/dvs/var${user}.txt
	do_add; n=0

    sudo systemctl stop mmdvm_bridge${user} > /dev/null 2>&1
#   sudo systemctl stop analog_bridge${user} > /dev/null 2>&1
#   sudo systemctl stop md380-emu${user} > /dev/null 2>&1

speep 1

file=/opt/user${user}/DVSwitch.ini
        if [ "${talkerAlias}" = "" ];
        then    sudo sed -i -e "/talkerAlias/ c talkerAlias = " $file
        else    $update_ini $file DMR talkerAlias "${talkerAlias}"
        fi
#    $update_ini $file Info Description "${desc}"

    sudo systemctl start mmdvm_bridge${user} > /dev/null 2>&1
#   sudo systemctl start analog_bridge${user} > /dev/null 2>&1
#   sudo systemctl start md380-emu${user} > /dev/null 2>&1
fi
done
}

################################################
# MAIN PROGRAM
################################################
file=dvsmu
sudo wget -O /usr/local/dvs/$file https://raw.githubusercontent.com/hp3icc/DVSMU/main/$file
sudo chmod +x /usr/local/dvs/$file

file=man_log
sudo wget -O /usr/local/dvs/$file https://raw.githubusercontent.com/hp3icc/DVSMU/main/$file
sudo chmod +x /usr/local/dvs/$file

file=DMRIds_chk.sh
sudo wget -O /usr/local/dvs/$file https://raw.githubusercontent.com/hp3icc/DVSMU/main/$file
sudo chmod +x /usr/local/dvs/$file


# 필요시 아래와 같이 다운로드 가능
# sudo wget -O /usr/local/dvs/dvsmu https://raw.githubusercontent.com/hp3icc/DVSMU/main/dvsmu
# sudo wget -O /usr/local/dvs/man_log https://raw.githubusercontent.com/hp3icc/DVSMU/main/man_log
# sudo wget -O /usr/local/dvs/DMRIds_chk.sh https://raw.githubusercontent.com/hp3icc/DVSMU/main/DMRIds_chk.sh

sleep 10

set_crontab

do_change

add_var_val

