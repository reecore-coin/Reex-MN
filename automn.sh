#!/bin/bash
# Prepare the environment
CONFIG_FILE='Reecore.conf'
CONFIGFOLDER='/root/.Reecore'
COIN_PATH='/usr/local/bin/'
#64 bit only
COIN_TGZ='https://github.com/reecore-coin/Reex/releases/download/v1.4.1.0/Reecore-v1.4.1.0.tar.gz'
COIN_PATHPART='Reecore-v1.4.1.0'
COIN_DAEMON="reecored"
COIN_CLI="reecore-cli"
COIN_NAME='Reecore'
COIN_PORT=45210
COIN_boot='https://github.com/reecore-coin/Reex-MN/releases/download/16.03.20/bootstrap.dat'
NODEIP=$(curl -s4 icanhazip.com)

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# -----------------------------------------------------------------------------------
progressfilt () {
  local flag=false c count cr=$'\r' nl=$'\n'
  while IFS='' read -d '' -rn 1 c
  do
    if $flag
    then
      printf '%c' "$c"
    else
      if [[ $c != $cr && $c != $nl ]]
      then
        count=0
      else
        ((count++))
        if ((count > 1))
        then
          flag=true
        fi
      fi
    fi
  done
}
# -----------------------------------------------------------------------------------
function download_node() {
  echo -e "Prepare to download $COIN_NAME"
  TMP_FOLDER=$(mktemp -d)
  cd $TMP_FOLDER
  wget --progress=bar:force $COIN_TGZ 2>&1 | progressfilt
  compile_error
  COIN_ZIP=$(echo $COIN_TGZ | awk -F'/' '{print $NF}')
  tar zxf $COIN_ZIP >/dev/null 2>&1
  compile_error
  chmod +x $COIN_DAEMON $COIN_CLI
  cp -p $COIN_DAEMON $COIN_CLI $COIN_PATH/
  compile_error
  rm -f $COIN_ZIP >/dev/null 2>&1
  cd ~ >/dev/null
  rm -rf $TMP_FOLDER >/dev/null 2>&1
  clear
}

function download_bootstrap() {
  echo -e "${GREEN}Downloading Bootstrap${NC}"
  cd $CONFIGFOLDER >/dev/null 2>&1
  wget $COIN_boot
  clear
}

function configure_systemd() {
  cat << EOF > /etc/systemd/system/$COIN_NAME.service
[Unit]
Description=$COIN_NAME service
After=network.target
[Service]
User=root
Group=root
Type=forking
#PIDFile=$CONFIGFOLDER/$COIN_NAME.pid
ExecStart=$COIN_PATH/$COIN_DAEMON -daemon -conf=$CONFIGFOLDER/$CONFIG_FILE -datadir=$CONFIGFOLDER
ExecStop=-$COIN_PATH/$COIN_CLI -conf=$CONFIGFOLDER/$CONFIG_FILE -datadir=$CONFIGFOLDER stop
Restart=always
PrivateTmp=true
TimeoutStopSec=60s
TimeoutStartSec=10s
StartLimitInterval=120s
StartLimitBurst=5
[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  sleep 3
  systemctl start $COIN_NAME.service
  systemctl enable $COIN_NAME.service >/dev/null 2>&1

  if [[ -z "$(ps axo cmd:100 | egrep $COIN_DAEMON)" ]]; then
    echo -e "${RED}$COIN_NAME is not running${NC}, please investigate. You should start by running the following commands as root:"
    echo -e "${GREEN}systemctl start $COIN_NAME.service"
    echo -e "systemctl status $COIN_NAME.service"
    echo -e "less /var/log/syslog${NC}"
    exit 1
  fi
}

function configure_startup() {
  cat << EOF > /etc/init.d/$COIN_NAME
#! /bin/bash
### BEGIN INIT INFO
# Provides: $COIN_NAME
# Required-Start: $remote_fs $syslog
# Required-Stop: $remote_fs $syslog
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: $COIN_NAME
# Description: This file starts and stops $COIN_NAME MN server
#
### END INIT INFO
case "\$1" in
 start)
   $COIN_PATH/$COIN_DAEMON -daemon -conf=$CONFIGFOLDER/$CONFIG_FILE -datadir=$CONFIGFOLDER
   sleep 5
   ;;
 stop)
   $COIN_PATH/$COIN_CLI -conf=$CONFIGFOLDER/$CONFIG_FILE -datadir=$CONFIGFOLDER stop
   ;;
 restart)
   $COIN_CLI stop
   sleep 10
   $COIN_PATH/$COIN_DAEMON -daemon -conf=$CONFIGFOLDER/$CONFIG_FILE -datadir=$CONFIGFOLDER
   ;;
 *)
   echo "Usage: $COIN_NAME {start|stop|restart}" >&2
   exit 3
   ;;
esac
EOF
chmod +x /etc/init.d/$COIN_NAME >/dev/null 2>&1
update-rc.d $COIN_NAME defaults >/dev/null 2>&1
/etc/init.d/$COIN_NAME start >/dev/null 2>&1
if [ "$?" -gt "0" ]; then
 sleep 5
 /etc/init.d/$COIN_NAME start >/dev/null 2>&1
fi
}


function create_config() {
  mkdir $CONFIGFOLDER >/dev/null 2>&1
  RPCUSER=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w10 | head -n1)
  RPCPASSWORD=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w22 | head -n1)
  cat << EOF > $CONFIGFOLDER/$CONFIG_FILE
rpcuser=$RPCUSER
rpcpassword=$RPCPASSWORD
rpcallowip=127.0.0.1
listen=1
server=1
daemon=1
port=$COIN_PORT
EOF
}

function create_key() {
  echo -e "Enter your ${RED}$COIN_NAME Masternode Private Key${NC}.\nLeave it blank to generate a new ${RED}$COIN_NAME Masternode Private Key${NC} for you:"
  read -e COINKEY
  if [[ -z "$COINKEY" ]]; then
    $COIN_PATH/$COIN_DAEMON -daemon
    sleep 30
    if [ -z "$(ps axo cmd:100 | grep $COIN_DAEMON)" ]; then
      echo -e "${RED}$COIN_NAME server couldn't not start. Check /var/log/syslog for errors.{$NC}"
      exit 1
    fi
    COINKEY=$($COIN_PATH/$COIN_CLI masternode genkey)
    if [ "$?" -gt "0" ];
      then
      echo -e "${RED}Wallet not fully loaded. Let us wait for 30s and try again to generate the Private Key${NC}"
      sleep 30
      COINKEY=$($COIN_PATH/$COIN_CLI masternode genkey)
      if [ "$?" -gt "0" ];
      then
        echo -e "${RED}Wallet not fully loaded. Let us wait for another 30s and try again to generate the Private Key${NC}"
        sleep 30
        COINKEY=$($COIN_PATH/$COIN_CLI masternode genkey)
      fi
    fi
  $COIN_PATH/$COIN_CLI stop
fi
clear
}

function update_config() {
  sed -i 's/daemon=1/daemon=0/' $CONFIGFOLDER/$CONFIG_FILE
  cat << EOF >> $CONFIGFOLDER/$CONFIG_FILE
logintimestamps=1
maxconnections=256
#bind=$NODEIP
staking=0
masternode=1
externalip=$NODEIP
masternodeaddr=$NODEIP:$COIN_PORT
masternodeprivkey=$COINKEY
EOF
}

function enable_firewall() {
  echo -e "Installing and setting up firewall to allow ingress on port ${GREEN}$COIN_PORT${NC}"
  ufw allow ssh >/dev/null 2>&1
  ufw allow $COIN_PORT >/dev/null 2>&1
  ufw default allow outgoing >/dev/null 2>&1
  echo "y" | ufw enable >/dev/null 2>&1
}

function get_ip() {
  declare -a NODE_IPS
  for ips in $(netstat -i | awk '!/Kernel|Iface|lo/ {print $1," "}')
  do
    NODE_IPS+=($(curl --interface $ips --connect-timeout 2 -s4 icanhazip.com))
  done

  if [ ${#NODE_IPS[@]} -gt 1 ]
    then
      echo -e "${GREEN}More than one IP. Please type 0 to use the first IP, 1 for the second and so on...${NC}"
      INDEX=0
      for ip in "${NODE_IPS[@]}"
      do
        echo ${INDEX} $ip
        let INDEX=${INDEX}+1
      done
      read -e choose_ip
      NODEIP=${NODE_IPS[$choose_ip]}
  else
    NODEIP=${NODE_IPS[0]}
  fi
}

function detect_ubuntu() {
 if [[ $(lsb_release -d) == *18.04* ]]; then
   UBUNTU_VERSION=18
 elif [[ $(lsb_release -d) == *16.04* ]]; then
   UBUNTU_VERSION=16
 elif [[ $(lsb_release -d) == *14.04* ]]; then
   UBUNTU_VERSION=14
else
   echo -e "${RED}You are not running Ubuntu 14.04, 16.04 or 18.04 Installation is cancelled.${NC}"
   exit 1
fi
}

function checks() {
 detect_ubuntu
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}$0 must be run as root.${NC}"
   exit 1
fi

if [ -n "$(pidof $COIN_DAEMON)" ] || [ -e "$COIN_DAEMOM" ] ; then
  echo -e "${RED}$COIN_NAME is already installed.${NC}"
  exit 1
fi
}

function prepare_system_for_download() {
echo -e "Prepare the system to install ${GREEN}$COIN_NAME${NC} master node."
apt-get update >/dev/null 2>&1
DEBIAN_FRONTEND=noninteractive apt-get update > /dev/null 2>&1
DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -y -qq upgrade >/dev/null 2>&1
echo -e "Installing required packages, it may take some time to finish.${NC}"
apt-get update >/dev/null 2>&1
apt-get install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" curl systemd >/dev/null 2>&1
if [ "$?" -gt "0" ];
  then
    echo -e "${RED}Not all required packages were installed properly. Try to install them manually by running the following commands:${NC}\n"
    echo "apt-get update"
    echo "apt install -y curl sytemd"
 exit 1
fi

clear
}

function create_swap() {
 echo -e "Checking if swap space is needed."
 PHYMEM=$(free -g|awk '/^Mem:/{print $2}')
 SWAP=$(swapon -s)
 if [[ "$PHYMEM" -lt "2"  &&  -z "$SWAP" ]]
  then
    echo -e "${GREEN}Server is running with less than 2G of RAM without SWAP, creating 2G swap file.${NC}"
    SWAPFILE=$(mktemp)
    dd if=/dev/zero of=$SWAPFILE bs=1024 count=2M
    chmod 600 $SWAPFILE
    mkswap $SWAPFILE
    swapon -a $SWAPFILE
 else
  echo -e "${GREEN}The server running with at least 2G of RAM, or a SWAP file is already in place.${NC}"
 fi
 clear
}


function important_information() {
 echo
 echo -e "================================================================================"
 echo -e "$COIN_NAME Masternode is up and running listening on port ${RED}$COIN_PORT${NC}."
 echo -e "Configuration file is: ${RED}$CONFIGFOLDER/$CONFIG_FILE${NC}"
 if (( $UBUNTU_VERSION == 16 || $UBUNTU_VERSION == 18 )); then
   echo -e "Start: ${GREEN}systemctl start $COIN_NAME.service${NC}"
   echo -e "Stop: ${GREEN}systemctl stop $COIN_NAME.service${NC}"
   echo -e "Status: ${GREEN}systemctl status $COIN_NAME.service${NC}"
 else
   echo -e "Start: ${GREEN}/etc/init.d/$COIN_NAME start${NC}"
   echo -e "Stop: ${GREEN}/etc/init.d/$COIN_NAME stop${NC}"
   echo -e "Status: ${GREEN}/etc/init.d/$COIN_NAME status${NC}"
 fi
 echo -e "VPS_IP:PORT ${GREEN}$NODEIP:$COIN_PORT${NC}"
 echo -e "MASTERNODE PRIVATEKEY is: ${GREEN}$COINKEY${NC}"
 echo -e "Check if $COIN_NAME is running by using the following command:\n${GREEN}ps -ef | grep $COIN_DAEMON | grep -v grep${NC}"
 echo -e "================================================================================"
}

function setup_node() {
  get_ip
  create_config
  create_key
  update_config
  enable_firewall
  important_information
  if (( $UBUNTU_VERSION == 16 || $UBUNTU_VERSION == 18 )); then
    configure_systemd
  else
    configure_startup
  fi
}


##### Main #####
clear

checks
create_swap
prepare_system_for_download
download_node
download_bootstrap
setup_node
