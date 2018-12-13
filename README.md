# Reex-MN
Script to setup Masternode

1. Need a fresh VPS with atleast 1 Gb RAM and 15 Gbs free space
2. download the file: 
```
wget https://github.com/Hser2bio/Reex-MN/blob/master/reemn.sh
```
3. change the permissions:
```
chmod +x reemn.sh
```
4. prepare the windows wallet:
4.1 go to debug console and type:
```
getnewaddress MN1
```
4.2 send 1.000 REEX to this address and let atleast confirm by 1 blocks
4.3 get the MN key and save in txt:
```
masternode genkey
```
5. back to vps and execute the file reemn.sh:
```
sudo ./reemn.sh
```
6. wait to ask genkey and put by control+V the info getted in 4.3 point.

