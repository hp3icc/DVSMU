#!/bin/bash


file=/etc/crontab

cron_daily_time=$(sed -n -e '/cron.daily/p' $FILE_CRON | cut -f 2 -d' ')
cron_daily_time=$(echo $cron_daily_time | cut -f1 -d' ')
cron_daily_min=$(sed -n -e '/cron.daily/p' $FILE_CRON | cut -f 1 -d' ')
cron_daily_min_plus_3=$((cron_daily_min + 3))
cron_daily_min_plus_4=$((cron_daily_min + 4))

echo "reboot=yes" | sudo tee -a $file > /dev/null 2>&1
echo "time=3" | sudo tee -a $file > /dev/null 2>&1
echo "0 3 * * * root /usr/local/dvs/man_log" | sudo tee -a $file > /dev/null 2>&1
echo "$cron_daily_min_plus_3 $cron_daily_time * * * root /usr/local/dvs/DMRIds_chk.sh" | sudo tee -a $file > /dev/null 2>&1

dir=/usr/local/dvs
files="dvsmu man_log"
for file in $files; do
sudo wget -O ${dir}/$file https://raw.githubusercontent.com/hp3icc/DVSMU/main/$file
sudo chmod +x ${dir}/$file
done


dir=/var/lib/dvswitch/dvs
files="analog_bridge00.service md380-emu00.service mmdvm_bridge00.service var00.txt"
for file in $files; do
sudo wget -O ${dir}/$file https://raw.githubusercontent.com/hp3icc/DVSMU/main/$file
sudo chmod +x ${dir}/$file
done


sudo mkdir /var/lib/dvswitch/dvs/adv/user00
dir=/var/lib/dvswitch/dvs/adv/user00
files="dvsm.adv dvsm.basic dvsm.macro dvsm.sh"
for file in $files; do
sudo wget -O ${dir}/$file https://raw.githubusercontent.com/hp3icc/DVSMU/main/$file
sudo chmod +x ${dir}/$file
done


sudo mkdir /var/lib/dvswitch/dvs/adv/user00EN
dir=/var/lib/dvswitch/dvs/adv/user00EN
files="adv_audio.txt adv_dmr.txt adv_hotspot.txt adv_main.txt adv_managetg.txt adv_resetfvrt.txt adv_rxgain.txt adv_tgref.txt adv_tools.txt adv_txgain.txt"
for file in $files; do
sudo wget -O ${dir}/$file https://raw.githubusercontent.com/hp3icc/DVSMU/main/EN/$file
done


sudo mkdir /var/lib/dvswitch/dvs/adv/user00KR
dir=/var/lib/dvswitch/dvs/adv/user00KR
files="adv_audio.txt adv_dmr.txt adv_hotspot.txt adv_main.txt adv_managetg.txt adv_resetfvrt.txt adv_rxgain.txt adv_tgref.txt adv_tools.txt adv_txgain.txt"
for file in $files; do
sudo wget -O ${dir}/$file https://raw.githubusercontent.com/hp3icc/DVSMU/main/KR/$file
done


sudo rm ./config.sh

exit 0

