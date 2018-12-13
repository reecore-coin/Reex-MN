# Reex-MN: Script to setup Masternode


Need a fresh VPS with atleast 1 Gb RAM and 15 Gbs free space
1. download the file: 
```
wget https://github.com/Hser2bio/Reex-MN/blob/master/reemn.sh
```
2. change the permissions:
```
chmod +x reemn.sh
```
3. prepare the windows wallet:
- go to debug console and type:
```
getnewaddress MN1
```
- send 1.000 REEX to this address and let atleast confirm by 1 blocks
- get the MN key and save in txt:
```
masternode genkey
```
4. back to vps and execute the file reemn.sh:
```
sudo ./reemn.sh
```
5. wait to ask genkey and put by control+V the info getted in 4.3 point.
6. let finish and note the IP:PORT given at the end of the script execution
7. back to your windows wallet and get masternode outputs:
```
masternode outputs
```
8. open the masternode conf file and put:
```
MN1 IP:PORT masternodekey masternodeoputus number
```
9. save masternode conf file reopen wallet and in masternode section type START
10. need atleast 22 blocks to be confirmed and start to work

enjoy :)
