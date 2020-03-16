# Reex-MN: Script to setup Masternode

<b>IMPORTANT ADVICE: Auto-masternode script tool is for install in fresh vps, you shouldnt install in machine that already have daemons with some balance due you will lost. Is suggested have a fresh VPS ubuntu with atleast 1 Gb RAM and 15 Gbs free space.</b>

1. download the file: 
```
git clone https://github.com/reecore-coin/Reex-MN.git
cd Reex-MN
```
Prepare the windows wallet:<br>
Go to debug console and type:
```
getnewaddress MN1
```
Send 15.000 REEX to the address and let it atleast confirm by 1 block
Generate the MN key  (in debug console)and save in txt:
```
masternode genkey
```
Go back to vps and execute the file automn.sh:
```
sudo ./automn.sh
```
Change the permissions:
```chmod +x automn.sh```
Prepare the windows wallet:
Go to debug console and type:
```
getnewaddress MN1
```
Send 15.000 REEX to the address and let it atleast confirm by 1 block<br><br>
Generate the MN key  (in debug console)and save in txt:
```
masternode genkey
```
Go back to vps and execute the file reemn16.sh:
```
sudo ./reemn18.sh
```
2. Wait, let it ask for genkey then put it by pressing control+V to paste the info you got in step 3c and press enter to go on.
3. Let it finish and note the IP:PORT given at the end of the script execution
4. Go back to your windows wallet (in debug console) and generate masternode outputs:
```
masternode outputs
```
It will give you something like this:  
```
txhash: "7a1ebb4baadf9ff39bbbfc2d58fd57ff15b65a5096069c8b232d3d312fb4xxxx",
outputidx: 1
```
you will only need to copy text between ""

5. Open the masternode conf file and put:
```
MN1 IP:PORT masternodekey masternodeouputs txnumber
EXAMPLE: 38.25.122.251:31000 7NEGGttKZojkAzViEYXXXxKTFdAtC2uSiMg8NSFqYVBtN6mYdU 7a1ebb4baadf9ff39bbbfc2d58fd57ff15b65a5096069c8XXX3fb4cb5c 1
```
6. Save masternode conf file, reopen wallet and in masternode section right-click START ALIAS
7. You need atleast 15 blocks confirmed before it start to work

enjoy :)
