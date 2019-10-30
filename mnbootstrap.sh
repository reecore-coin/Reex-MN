#!/bin/bash

# Make sure unzip is installed
clear
apt-get -qq update
apt -qqy install unzip

clear
echo "This script will bootstrap your masternode."
read -rp "Press Ctrl-C to abort or any other key to continue. " -n1 -s
clear

if [ "$(id -u)" != "0" ]; then
  echo "This script must be run as root."
  exit 1
fi

if [ -e /etc/systemd/system/Reecore.service ]; then
  systemctl stop Reecore.service
else
  su -c "reecore-cli stop" "root"
fi

echo "Refreshing node, please wait."

sleep 5

rm -rf "/root/.Reecore/blocks"
rm -rf "/root/.Reecorechainstate"
rm -rf "/root/.Reecore/sporks"
rm -rf "/root/.Reecore/peers.dat"

echo "Installing bootstrap file..."

cd /root/.Reecore && wget https://github.com/reecore-coin/Reex/releases/download/v.1.3.1.0/bootstrap-20191010.zip && unzip bootstrap.zip && rm bootstrap.zip

if [ -e /etc/systemd/system/Reecore.service ]; then
  sudo systemctl start Reecore.service
else
  su -c "reecored -daemon" "root"
fi

echo "Starting REEX, will check status in 60 seconds..."
sleep 60

clear

if ! systemctl status Reecore.service | grep -q "active (running)"; then
  echo "ERROR: Failed to start Reex. Please re-install using install script."
  exit
fi

echo "Waiting for wallet to load..."
until su -c "reecore-cli getinfo 2>/dev/null | grep -q \"version\"" "$USER"; do
  sleep 1;
done

clear

echo "Your masternode is syncing. Please wait for this process to finish."
echo "This can a few minutes. Do not close this window."
echo ""

until [ -n "$(reecore-cli getconnectioncount 2>/dev/null)"  ]; do
  sleep 1
done

until su -c "reecore-cli mnsync status 2>/dev/null | grep '\"IsBlockchainSynced\": true' > /dev/null" "$USER"; do 
  echo -ne "Current block: $(su -c "reecore-cli getblockcount" "$USER")\\r"
  sleep 1
done

clear

cat << EOL
Now, you need to start your masternode. If you haven't already, please add this
node to your masternode.conf now, restart and unlock your desktop wallet, go to
the Masternodes tab, select your new node and click "Start Alias."
EOL

read -rp "Press Enter to continue after you've done that. " -n1 -s

clear

sleep 1
su -c "/usr/local/bin/reecore-cli startmasternode local false" "$USER"
sleep 1
clear
su -c "/usr/local/bin/reecore-cli masternode status" "$USER"
sleep 5

echo "" && echo "Masternode refresh completed." && echo ""
