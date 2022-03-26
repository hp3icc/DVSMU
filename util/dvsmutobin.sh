#!/bin/bash

# dvsmu를 만들고 나서, Binary로 바꾸고 Backup을 만드는 등의 작업을 자동화 함.
# shc 프로그램을 설치한다 (맨 아래 설명 있음)
# 텍스트로 된 dvsmu를 바이너리 파일로 만드는 작업이다.
# 한 단계씩 실행하므로 각 단계마다 엔터를 누른다.

DVS=/usr/local/dvs/
HOME=/home/dvswitch/
SHC=/home/dvswitch/shc-3.8.9/

sudo \cp -f ${DVS}dvsmu ${DVS}dvsmu.bak
echo "copied to bak"
read
sudo \cp -f ${DVS}dvsmu ${DVS}dvsmu.sh
echo "copied to sh"
read
sudo \cp -f ${DVS}dvsmu ${HOME}dvsmu
echo "copied to HOME"
read
${SHC}shc -r -v -T -f ${HOME}dvsmu
echo "shrinked"
read
sudo mv ${HOME}dvsmu.x ${HOME}dvsmu
echo "copied the file x to dvsmu"
read
sudo \cp -f ${HOME}dvsmu ${DVS}dvsmu
echo "copied to DVS folder"


# 아래와 같이 다운로드가 가능함 =====================================
# sudo wget -O /usr/local/dvs/dvsmutobin.sh https://raw.githubusercontent.com/hp3icc/DVSMU/main/util/dvsmutobin.sh
# sudo chmod +x /usr/local/dvs/dvsmutobin.sh


# shc 설치 ========================================================
# wget http://www.datsi.fi.upm.es/~frosal/sources/shc-3.8.9.tgz
# tar xvfz shc-3.8.9.tgz
#cd shc-3.8.9
# make (필히 실행해야 함)

# 바이너리화:
# ./shc -r -v -T -f ./파일명

# 본래의 스크립트 파일하나,
# 바이너리파일인 .x
# 그리고 쉘스크립트가 c코드로 변환되었던 .c코드가 만들어진다.
