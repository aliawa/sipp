#!/usr/bin/python

import optparse
from scapy.all import *

# Options parser
usage = "usage: %prog [options] ip-address port"
parser = optparse.OptionParser(usage=usage);
options, args = parser.parse_args()

if len(args) !=4:
    parser.error("Incorrect number of arguments");

ip_src = args[0]
port_src=int(args[1])
ip_dst = args[2]
port_dst=int(args[3])
print "Sending RTP from: {0}:{1} to {2}:{3}".format(ip_src,port_src,ip_dst,port_dst)



def sendrtp(filename):
    newpkts=[]
    for p in PcapReader(filename):
        p = Ether()/p[IP]
        p[IP].src=ip_src
        p[IP].dst=ip_dst
        del p.chksum

        p[UDP].sport = port_src
        p[UDP].dport = port_dst
        p[UDP].chksum= None
        newpkts.append(p)

        print p.summary()
    return newpkts



sendpfast(PacketList(sendrtp("../scenario/pcap/g711a.pcap")),realtime=1, iface='eth1')





