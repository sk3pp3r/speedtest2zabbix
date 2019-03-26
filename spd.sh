#!/bin/bash
set -e
printf "\033c"
###################################################################################
# Title: spd.sh
# Description: Script to check speedtest and report back to zabbix.
# Original Author: Haim Cohen 
# https://www.linkedin.com/in/haimc/
# 10-Feb-2019
###################################################################################
#
# Tested with Zabbix vZabbix 3.0.24 & Speedtest-cli v2.0.0
echo "checking speedtest and report back to zabbix, please wait..."

#################
# Configuration #
#################
# Zabbix 
TIMESTAMP=$(date "+%Y.%m.%d-%H.%M.%S")
ZABBIX_SENDER="/usr/bin/zabbix_sender"
ZABBIX_HOST="SpeedTest"
ZABBIX_SRV="zabbix IP or FQDN"
ZABBIX_LOG="/dev/null"
ZABBIX_DATA=/tmp/zbxdata_$TIMESTAMP.log
# Speedtest
SPEEDTEST="/usr/bin/speedtest-cli"
CACHE_FILE=/tmp/speedtest_$TIMESTAMP.log
ID="21197" # Test against server ID, to get all servers ID - run 'speedtest --list' 

                ###################################################################################
                ###   Israel Servers List                                                       ###
                ###                                                                             ###
                ###    6176) LAN-WAN I.T Services LTD (Baqa el-Gharbiya, Israel) [37.02 km]     ###
                ###   11616) KamaTera INC (Rosh HaAyin, Israel) [80.11 km]                      ###
                ###   11615) KamaTera INC (Rosh HaAyin, Israel) [80.11 km]                      ###
                ###    9034) Xfone 018 (Petah Tikva, Israel) [81.39 km]                         ###
                ###   12087) Triple C (Petah Tikva, Israel) [81.39 km]                          ###
                ###   11617) KamaTera INC (Petah Tikva, Israel) [81.39 km]                      ###
                ###   21197) Hotnet (Petah Tikva, Israel) [81.39 km]                            ###
                ###   14215) Partner Communications (Petah Tikva, Israel) [81.91 km]            ###
                ###    3660) SPD Hosting LTD (Petah Tikwa, Israel) [82.03 km]                   ###
                ###   10553) 099 Primo Communications (Tel Aviv, Israel) [85.49 km]             ###
                ###    5803) Pelephone Communications (Tel Aviv, Israel) [85.49 km]             ###
                ###    1330) Y-tech (Tel Aviv, Israel) [85.49 km]                               ###
                ###    5283) Cellcom Israel (Rishon LeZion, Israel) [96.89 km]                  ###
                ###    3413) HOT Mobile (Lod, Israel) [96.89 km]                                ###
                ###   10541) 099 Primo Communications (Jerusalem, Israel) [116.76 km]           ###
                ###    8333) 3SAMNET (Jerusalem, Israel) [116.76 km]                            ###
                ###    1075) Coolnet (Jerusalem, Israel) [116.76 km]                            ###
                ###    4138) Pelephone Communications (Ashkelon, Israel) [133.79 km]            ###
                ###################################################################################



#################
# Generate data #
#################
speedtest --server $ID --csv > $CACHE_FILE

##################
# Extract fields #
##################
output=$(cat $CACHE_FILE)
    WAN_IP=$(echo "$output" | cut -f10 -d ',')
    PING=$(echo "$output" | cut -f6 -d ',')
    SRV_NAME=$(echo "$output" | cut -f2 -d ',')
    SRV_CITY=$(echo "$output" | cut -f3 -d ',')
    SRV_KM=$(echo "$output" | cut -f5 -d ',' | cut -b1-5)
    DL_TMP=$(echo "$output" | cut -f7 -d ',')
    UP_TMP=$(echo "$output" | cut -f8 -d ',')
    


#####################
# convert to Mbit/s #
#####################
DL=$(echo "$DL_TMP" |  awk '{ printf("%.2f\n", $1 / 1024 /1024 ) }')
UP=$(echo "$UP_TMP" |  awk '{ printf("%.2f\n", $1 / 1024 /1024 ) }')


#####################
# Write Zabbix Data #
#####################
 echo "SpeedTest" key.download $DL >> $ZABBIX_DATA 
 echo "SpeedTest" key.upload $UP >> $ZABBIX_DATA 
 echo "SpeedTest" key.wan.ip $WAN_IP >> $ZABBIX_DATA 
 echo "SpeedTest" key.ping $PING >> $ZABBIX_DATA
 echo "SpeedTest" key.srv.name $SRV_NAME >> $ZABBIX_DATA
 echo "SpeedTest" key.srv.city $SRV_CITY >> $ZABBIX_DATA
 echo "SpeedTest" key.srv.km $SRV_KM >> $ZABBIX_DATA

##########################
# zabbix sender finction #
##########################
function send_value {
        /usr/bin/zabbix_sender -z ZABBIX_SERVER_IP_OR_FQDN -i $ZABBIX_DATA
}

#######################
# Send data to Zabbix #
send_value
#######################