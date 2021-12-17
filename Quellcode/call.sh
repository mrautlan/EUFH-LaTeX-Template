#!/bin/bash

run_call() {
        sudo rm /home/pi/Downloads/rtpdata_pi1-pi2.txt

        #First, start SIP server on destination device, after that, start TShark and SIPp. The RTP address has to be specified with -mi
        ssh pi@5.5.5.22 'sudo /home/pi/Downloads/sipp-3.3/sipp -sn uas -mi 5.5.5.22 -bg > /dev/null 2>&1 &'

        #Start TShark to monitor packets, TShark has to run on the receiving end (SSH)
        ssh -f pi@5.5.5.22 'sudo tshark -i eth0 -qz rtp,streams > /home/pi/Downloads/rtpdata_pi1-pi2.txt'

        #wait for TShark to start
        sleep 4

        #Start SIPp, RTP address has to be specified! Otherwise, RTP stream will be directed to 127.0.0.1. RTP stream is loaded with the pcap.xml file
        sudo /home/pi/Downloads/sipp-3.3/sipp -sf /home/pi/Downloads/sipp-3.3/pcap.xml 5.5.5.22 -m 1 -mi 5.5.5.21 -bg >/dev/null 2>&1 &

        #Wait for RTP stream to be transmitted, sleep for a certain time
        sleep $1

        #Kill SIPp client
        sudo pkill sipp

        #Kill TShark
        ssh pi@5.5.5.22 'sudo pkill tshark'

        #Kill SIPp server
        ssh pi@5.5.5.22 'sudo pkill sipp'

        #Copy file to source Raspberry Pi
        ssh pi@5.5.5.22 'scp /home/pi/Downloads/rtpdata_pi1-pi2.txt pi@5.5.5.21:/home/pi/Downloads'
}

#Run run_call function with 15 seconds transmission time
run_call 15

#Check how many packets have been transmitted via python script
packets=$(ssh -f pi@5.5.5.22 '/usr/bin/python /home/pi/Downloads/check_packetloss.py')

#Ff all packets have been transmitted, return MOS value
if ((packets >= 173)); then

        #Return MOS value with python script
        /usr/bin/python /home/pi/Downloads/call_gen_new_formula.py
        exit 0
#If less packets have been transmitted, run run_call function with 30 seconds transmission time
elif ((packets <= 173 && packets >= 100)); then

        run_call 30

        #Return MOS value with python script
        /usr/bin/python /home/pi/Downloads/call_gen_new_formula.py

#If less packets have been transmitted, run run_call function with 60 seconds transmission time
elif ((packets < 100)); then

        run_call 60

        #Return MOS value with python script
        /usr/bin/python /home/pi/Downloads/call_gen_new_formula.py
fi